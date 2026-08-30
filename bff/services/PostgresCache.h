#pragma once

#include "ICache.h"

#include <drogon/orm/DbClient.h>
#include <drogon/orm/Result.h>

#include <atomic>
#include <chrono>
#include <cstddef>
#include <memory>
#include <optional>
#include <string>
#include <vector>

/// Durable [ICache] backed by the PostgreSQL already running on the host.
///
/// Chosen over Redis because nothing here needs a second datastore: the access
/// pattern is a keyed lookup with an expiry, a few times a minute. See
/// specs/002-bff-durable-cache/ for the reasoning and the trade-off — expiry
/// and eviction are our code here, rather than SETEX and maxmemory-policy.
///
/// Every operation is best-effort. The cache going down must never take a
/// request down (spec FR-005), so failures are logged and reported as a miss
/// rather than thrown into the request path.
class PostgresCache : public ICache {
  public:
    PostgresCache(std::shared_ptr<drogon::orm::DbClient> client, std::size_t maxRows);

    /// Creates the table and indexes if absent. Returns false if the database
    /// is unreachable, so the caller can fall back instead of failing to start.
    bool ensureSchema();

    std::optional<std::string> get(const std::string& key) override;
    void set(const std::string& key, const std::string& value, int ttlSeconds) override;
    void clear() override;

    /// Deletes expired rows, then trims to [maxRows_] by oldest read. Expiry is
    /// enforced on read as well, so a missed sweep can never serve stale data —
    /// this only reclaims space.
    void sweep();

  private:
    /// Runs [sql], returning nullopt if it errors or does not finish within
    /// [timeout].
    ///
    /// Drogon retries a failed Postgres connection every second, indefinitely,
    /// and execSqlSync simply blocks while it does. A plain try/catch never
    /// fires: an unreachable database would hang the request thread rather than
    /// throw, which is worse than the failure FR-005 exists to prevent. Every
    /// statement therefore goes through a bounded wait.
    std::optional<drogon::orm::Result> exec(std::chrono::milliseconds timeout,
                                            const std::string& sql,
                                            const std::vector<std::string>& args);

    /// True while the breaker is open. After a timeout or error, calls
    /// short-circuit for a cooldown so a dead database costs one timeout rather
    /// than one per request.
    bool degraded() const;
    void tripBreaker();

    std::shared_ptr<drogon::orm::DbClient> client_;
    std::size_t maxRows_;
    std::atomic<std::chrono::steady_clock::time_point> unhealthyUntil_{
        std::chrono::steady_clock::time_point{}};
};
