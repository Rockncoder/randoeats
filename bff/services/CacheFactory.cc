#include "CacheFactory.h"

#include "InMemoryCache.h"

#include <stdexcept>
#include <string>
#include <trantor/utils/Logger.h>

#ifdef RANDOEATS_HAS_POSTGRES
#include "PostgresCache.h"

#include <drogon/orm/DbClient.h>
#endif

std::shared_ptr<ICache> createCache(const Json::Value& config) {
    const auto maxEntries =
        static_cast<std::size_t>(config.get("cache_max_entries", 2000).asUInt());
    const std::string backend = config.get("cache_backend", "memory").asString();

    if (backend == "memory") {
        return std::make_shared<InMemoryCache>(maxEntries);
    }

    if (backend == "postgres") {
#ifdef RANDOEATS_HAS_POSTGRES
        const auto& pg = config["postgres"];
        const std::string conn = pg.get("connection", "").asString();
        if (conn.empty()) {
            throw std::runtime_error(
                R"(cache_backend is "postgres" but postgres.connection is empty)");
        }
        try {
            auto client = drogon::orm::DbClient::newPgClient(
                conn, static_cast<std::size_t>(pg.get("connections", 2).asUInt()));
            auto cache = std::make_shared<PostgresCache>(
                client, static_cast<std::size_t>(pg.get("max_rows", 20000).asUInt()));
            if (cache->ensureSchema()) {
                LOG_INFO << "cache backend: postgres";
                return cache;
            }
            LOG_ERROR << "cache backend: postgres unreachable at startup, "
                         "falling back to in-memory";
        } catch (const std::exception& e) {
            LOG_ERROR << "cache backend: postgres init failed (" << e.what()
                      << "), falling back to in-memory";
        }
        return std::make_shared<InMemoryCache>(maxEntries);
#else
        // Loud, not silent. A build without Drogon's Postgres support cannot
        // honour this configuration, and quietly using memory instead would be
        // a false green of exactly the kind this project refuses.
        throw std::runtime_error(R"(cache_backend is "postgres" but this binary was built without )"
                                 "Drogon PostgreSQL support (rebuild Drogon with -DBUILD_ORM=ON "
                                 "-DBUILD_POSTGRESQL=ON)");
#endif
    }

    throw std::runtime_error(R"(unrecognized cache_backend: ")" + backend +
                             R"(" (expected "memory" or "postgres"))");
}
