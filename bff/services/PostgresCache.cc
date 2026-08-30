#include "PostgresCache.h"

#include <exception>
#include <future>
#include <trantor/utils/Logger.h>

namespace {

// A cache lookup must never cost more than the upstream call it exists to
// avoid. A local Postgres answers in well under a millisecond; anything past
// these bounds means something is wrong, and the right move is to give up and
// treat it as a miss.
constexpr std::chrono::milliseconds kReadTimeout{250};
constexpr std::chrono::milliseconds kWriteTimeout{500};
constexpr std::chrono::milliseconds kSchemaTimeout{5000};
constexpr std::chrono::seconds kBreakerCooldown{30};

}  // namespace

PostgresCache::PostgresCache(std::shared_ptr<drogon::orm::DbClient> client, std::size_t maxRows)
    : client_(std::move(client)), maxRows_(maxRows == 0 ? 1 : maxRows) {}

bool PostgresCache::degraded() const {
    return std::chrono::steady_clock::now() < unhealthyUntil_.load(std::memory_order_relaxed);
}

void PostgresCache::tripBreaker() {
    unhealthyUntil_.store(std::chrono::steady_clock::now() + kBreakerCooldown,
                          std::memory_order_relaxed);
}

std::optional<drogon::orm::Result> PostgresCache::exec(std::chrono::milliseconds timeout,
                                                       const std::string& sql,
                                                       const std::vector<std::string>& args) {
    if (degraded()) {
        return std::nullopt;
    }
    try {
        std::future<drogon::orm::Result> fut;
        switch (args.size()) {
            case 0:
                fut = client_->execSqlAsyncFuture(sql);
                break;
            case 1:
                fut = client_->execSqlAsyncFuture(sql, args[0]);
                break;
            case 2:
                fut = client_->execSqlAsyncFuture(sql, args[0], args[1]);
                break;
            default:
                fut = client_->execSqlAsyncFuture(sql, args[0], args[1], args[2]);
                break;
        }
        if (fut.wait_for(timeout) != std::future_status::ready) {
            LOG_ERROR << "PostgresCache: statement timed out after " << timeout.count()
                      << "ms; treating the cache as unavailable for " << kBreakerCooldown.count()
                      << "s";
            tripBreaker();
            return std::nullopt;
        }
        return fut.get();
    } catch (const std::exception& e) {
        LOG_ERROR << "PostgresCache: statement failed: " << e.what();
        tripBreaker();
        return std::nullopt;
    }
}

bool PostgresCache::ensureSchema() {
    // UNLOGGED: this is a cache, so skipping WAL avoids write amplification on a
    // host shared with another tenant's real data. The only cost is that a
    // Postgres *crash* truncates it -- and the case this exists for, a BFF
    // redeploy, does not touch Postgres at all.
    const bool table = exec(kSchemaTimeout,
                            "CREATE UNLOGGED TABLE IF NOT EXISTS places_cache ("
                            "  key text PRIMARY KEY,"
                            "  value text NOT NULL,"
                            "  expires_at timestamptz NOT NULL,"
                            "  last_read timestamptz NOT NULL DEFAULT now())",
                            {})
                           .has_value();
    if (!table) {
        return false;
    }
    exec(kSchemaTimeout,
         "CREATE INDEX IF NOT EXISTS places_cache_expires_at ON places_cache (expires_at)",
         {});
    exec(kSchemaTimeout,
         "CREATE INDEX IF NOT EXISTS places_cache_last_read ON places_cache (last_read)",
         {});
    return true;
}

std::optional<std::string> PostgresCache::get(const std::string& key) {
    // One statement: enforce expiry, refresh last_read for the LRU sweep, and
    // return the value. Expiry is checked here rather than relying on the sweep,
    // so a stale row is never served even if the sweep has never run.
    const auto rows = exec(kReadTimeout,
                           "UPDATE places_cache SET last_read = now() "
                           "WHERE key = $1 AND expires_at > now() "
                           "RETURNING value",
                           {key});
    if (!rows || rows->empty()) {
        return std::nullopt;
    }
    return (*rows)[0]["value"].as<std::string>();
}

void PostgresCache::set(const std::string& key, const std::string& value, int ttlSeconds) {
    // Upsert: a rolling deploy can have two processes writing the same key, and
    // the loser must not error (spec FR-008).
    exec(kWriteTimeout,
         "INSERT INTO places_cache (key, value, expires_at, last_read) "
         "VALUES ($1, $2, now() + make_interval(secs => $3::double precision), now()) "
         "ON CONFLICT (key) DO UPDATE SET "
         "  value = EXCLUDED.value,"
         "  expires_at = EXCLUDED.expires_at,"
         "  last_read = now()",
         {key, value, std::to_string(ttlSeconds)});
}

void PostgresCache::clear() {
    exec(kWriteTimeout, "DELETE FROM places_cache", {});
}

void PostgresCache::sweep() {
    exec(kWriteTimeout, "DELETE FROM places_cache WHERE expires_at <= now()", {});
    // Then trim to the row cap, least recently read first. A targeted delete
    // rather than a table rewrite, so it holds no long lock.
    exec(kWriteTimeout,
         "DELETE FROM places_cache WHERE key IN ("
         "  SELECT key FROM places_cache ORDER BY last_read DESC OFFSET $1)",
         {std::to_string(maxRows_)});
}
