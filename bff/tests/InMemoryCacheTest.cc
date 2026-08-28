#include "services/InMemoryCache.h"

#include <drogon/drogon_test.h>

#include <chrono>

namespace {

/// A clock a test can move forward, so TTL expiry is exercised without waiting
/// out a real 3600-second TTL.
struct ManualClock {
    std::chrono::steady_clock::time_point now = std::chrono::steady_clock::now();
    void advance(int seconds) { now += std::chrono::seconds(seconds); }
};

}  // namespace

DROGON_TEST(InMemoryCacheStoresAndReturns) {
    InMemoryCache cache(10);
    cache.set("k", "v", 60);
    const auto got = cache.get("k");
    REQUIRE(got.has_value());
    CHECK(*got == "v");
}

DROGON_TEST(InMemoryCacheMissesUnknownKey) {
    InMemoryCache cache(10);
    CHECK(!cache.get("absent").has_value());
}

DROGON_TEST(InMemoryCacheClearRemovesEverything) {
    InMemoryCache cache(10);
    cache.set("a", "1", 60);
    cache.set("b", "2", 60);
    cache.clear();
    CHECK(!cache.get("a").has_value());
    CHECK(!cache.get("b").has_value());
}

DROGON_TEST(InMemoryCacheExpiresAfterTtl) {
    auto clock = std::make_shared<ManualClock>();
    InMemoryCache cache(10, [clock] { return clock->now; });

    cache.set("k", "v", 60);
    CHECK(cache.get("k").has_value());

    clock->advance(59);
    CHECK(cache.get("k").has_value());  // still inside the TTL

    clock->advance(2);  // now past it
    CHECK(!cache.get("k").has_value());
}

DROGON_TEST(InMemoryCacheRefreshesTtlOnOverwrite) {
    auto clock = std::make_shared<ManualClock>();
    InMemoryCache cache(10, [clock] { return clock->now; });

    cache.set("k", "v1", 60);
    clock->advance(59);
    cache.set("k", "v2", 60);  // resets expiry
    clock->advance(30);

    const auto got = cache.get("k");
    REQUIRE(got.has_value());
    CHECK(*got == "v2");
}

DROGON_TEST(InMemoryCacheEvictsLeastRecentlyUsedAtCapacity) {
    InMemoryCache cache(2);
    cache.set("a", "1", 60);
    cache.set("b", "2", 60);

    // Touch "a" so "b" becomes the least recently used.
    CHECK(cache.get("a").has_value());

    cache.set("c", "3", 60);

    CHECK(cache.get("a").has_value());
    CHECK(cache.get("c").has_value());
    CHECK(!cache.get("b").has_value());
}

DROGON_TEST(InMemoryCacheTreatsZeroCapacityAsOne) {
    InMemoryCache cache(0);
    cache.set("a", "1", 60);
    CHECK(cache.get("a").has_value());
}
