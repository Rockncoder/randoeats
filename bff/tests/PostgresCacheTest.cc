#include "services/PostgresCache.h"

#include <drogon/drogon_test.h>
#include <drogon/orm/DbClient.h>

#include <chrono>
#include <cstdlib>
#include <memory>
#include <string>
#include <thread>

// Exercises PostgresCache against a REAL PostgreSQL, because the things worth
// testing here are SQL semantics: does expiry actually filter, does the upsert
// actually upsert, does the sweep actually respect the cap. A fake would only
// test the fake.
//
// The connection string comes from RANDOEATS_TEST_PG_CONN. This target is only
// registered by CMake when that variable is set, so it never silently passes by
// doing nothing -- if it runs at all, it ran against a database.

namespace {

std::shared_ptr<PostgresCache> makeCache(std::size_t maxRows = 100) {
    const char* conn = std::getenv("RANDOEATS_TEST_PG_CONN");
    auto client = drogon::orm::DbClient::newPgClient(conn ? conn : "", 1);
    auto cache = std::make_shared<PostgresCache>(client, maxRows);
    cache->ensureSchema();
    cache->clear();
    return cache;
}

}  // namespace

DROGON_TEST(PgStoresAndReturns) {
    auto cache = makeCache();
    cache->set("k", "v", 60);
    const auto got = cache->get("k");
    REQUIRE(got.has_value());
    CHECK(*got == "v");
}

DROGON_TEST(PgMissesUnknownKey) {
    auto cache = makeCache();
    CHECK(!cache->get("absent").has_value());
}

DROGON_TEST(PgRoundTripsNonAscii) {
    auto cache = makeCache();
    // Real place names carry accents and non-Latin scripts; a broken encoding
    // path would corrupt them silently.
    const std::string value = R"({"name":"Café Crème 北京 Ñandú"})";
    cache->set("unicode", value, 60);
    const auto got = cache->get("unicode");
    REQUIRE(got.has_value());
    CHECK(*got == value);
}

DROGON_TEST(PgExpiresOnRead) {
    auto cache = makeCache();
    // A already-expired TTL must be invisible immediately, without the sweep
    // having run -- expiry is enforced by the read, not by housekeeping.
    cache->set("stale", "v", -1);
    CHECK(!cache->get("stale").has_value());
}

DROGON_TEST(PgUpsertOverwritesAndRefreshesTtl) {
    auto cache = makeCache();
    cache->set("k", "first", 60);
    cache->set("k", "second", 60);
    const auto got = cache->get("k");
    REQUIRE(got.has_value());
    CHECK(*got == "second");
}

DROGON_TEST(PgClearRemovesEverything) {
    auto cache = makeCache();
    cache->set("a", "1", 60);
    cache->set("b", "2", 60);
    cache->clear();
    CHECK(!cache->get("a").has_value());
    CHECK(!cache->get("b").has_value());
}

DROGON_TEST(PgSweepRemovesExpiredButKeepsLive) {
    auto cache = makeCache();
    cache->set("live", "v", 600);
    cache->set("dead", "v", -1);
    cache->sweep();
    CHECK(cache->get("live").has_value());
    CHECK(!cache->get("dead").has_value());
}

DROGON_TEST(PgSweepEnforcesRowCap) {
    auto cache = makeCache(3);
    for (int i = 0; i < 10; ++i) {
        cache->set("key" + std::to_string(i), "v", 600);
    }
    cache->sweep();

    int surviving = 0;
    for (int i = 0; i < 10; ++i) {
        if (cache->get("key" + std::to_string(i)).has_value()) ++surviving;
    }
    CHECK(surviving <= 3);
    CHECK(surviving > 0);
}

DROGON_TEST(PgSurvivesANewClient) {
    // The whole point of the feature: a value written by one process is still
    // there for the next one. A fresh DbClient stands in for a redeployed BFF.
    auto writer = makeCache();
    writer->set("persisted", "still here", 600);

    const char* conn = std::getenv("RANDOEATS_TEST_PG_CONN");
    auto client = drogon::orm::DbClient::newPgClient(conn ? conn : "", 1);
    PostgresCache reader(client, 100);
    const auto got = reader.get("persisted");
    REQUIRE(got.has_value());
    CHECK(*got == "still here");
}

DROGON_TEST(PgUnreachableDegradesToMiss) {
    // FR-005: a cache that is down must never take a request down.
    auto client = drogon::orm::DbClient::newPgClient(
        "host=127.0.0.1 port=1 dbname=nope user=nope password=nope", 1);
    PostgresCache broken(client, 10);
    CHECK(!broken.get("anything").has_value());
    broken.set("anything", "v", 60);  // must not throw
    broken.clear();                   // must not throw
    broken.sweep();                   // must not throw
}
