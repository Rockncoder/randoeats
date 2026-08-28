#include "FakePlacesUpstream.h"
#include "services/InMemoryCache.h"
#include "services/PlacesService.h"

#include <drogon/drogon_test.h>
#include <drogon/utils/coroutine.h>

#include <chrono>
#include <memory>

namespace {

struct ManualClock {
    std::chrono::steady_clock::time_point now = std::chrono::steady_clock::now();
    void advance(int seconds) { now += std::chrono::seconds(seconds); }
};

constexpr int kNearbyTtl = 3600;   // matches config.json nearby_ttl_seconds
constexpr int kDetailsTtl = 21600; // matches config.json details_ttl_seconds

struct Fixture {
    std::shared_ptr<FakePlacesUpstream> upstream = std::make_shared<FakePlacesUpstream>();
    std::shared_ptr<ManualClock> clock = std::make_shared<ManualClock>();
    std::shared_ptr<InMemoryCache> cache =
        std::make_shared<InMemoryCache>(100, [c = clock] { return c->now; });
    std::shared_ptr<PlacesService> service =
        std::make_shared<PlacesService>(upstream, cache, kNearbyTtl, kDetailsTtl);
};

NearbyQuery baseQuery() {
    NearbyQuery q;
    q.query = "tacos";
    q.lat = 33.7879;
    q.lng = -117.8531;
    q.radius = 5000;
    q.maxResults = 20;
    return q;
}

}  // namespace

// Scenario 1 — empty cache is a MISS, upstream called exactly once.
DROGON_TEST(NearbyMissesOnEmptyCacheAndCallsUpstreamOnce) {
    Fixture f;
    const auto result = drogon::sync_wait(f.service->nearby(baseQuery()));

    CHECK(result.status == 200);
    CHECK(result.cache == "MISS");
    CHECK(f.upstream->searchCalls == 1);
    CHECK(result.ttlSeconds == kNearbyTtl);
}

// Scenario 2 — a repeat request is a HIT and does NOT call Google.
DROGON_TEST(NearbyHitsCacheAndDoesNotCallUpstream) {
    Fixture f;
    drogon::sync_wait(f.service->nearby(baseQuery()));
    const auto second = drogon::sync_wait(f.service->nearby(baseQuery()));

    CHECK(second.cache == "HIT");
    CHECK(second.upstreamMs == 0);
    CHECK(f.upstream->searchCalls == 1);  // still one: the HIT cost nothing
}

// Scenario 3 — once the TTL elapses the request goes upstream again.
DROGON_TEST(NearbyMissesAgainAfterTtlElapses) {
    Fixture f;
    drogon::sync_wait(f.service->nearby(baseQuery()));
    f.clock->advance(kNearbyTtl + 1);

    const auto after = drogon::sync_wait(f.service->nearby(baseQuery()));
    CHECK(after.cache == "MISS");
    CHECK(f.upstream->searchCalls == 2);
}

// Scenario 4 — every input that changes the result set changes the cache key.
DROGON_TEST(NearbyKeyVariesWithEveryQueryInput) {
    Fixture f;
    drogon::sync_wait(f.service->nearby(baseQuery()));
    int expected = 1;

    const auto distinct = [&](NearbyQuery q) {
        const auto r = drogon::sync_wait(f.service->nearby(q));
        CHECK(r.cache == "MISS");
        CHECK(f.upstream->searchCalls == ++expected);
    };

    auto q = baseQuery(); q.query = "sushi";        distinct(q);
    q = baseQuery(); q.lat = 34.0;                  distinct(q);
    q = baseQuery(); q.lng = -118.0;                distinct(q);
    q = baseQuery(); q.radius = 1000;               distinct(q);
    q = baseQuery(); q.maxResults = 5;              distinct(q);
    q = baseQuery(); q.openNow = true;              distinct(q);
    q = baseQuery(); q.minRating = 4.0;             distinct(q);
    q = baseQuery(); q.priceLevels = {1, 2};        distinct(q);
    q = baseQuery(); q.beer = true;                 distinct(q);
    q = baseQuery(); q.wine = true;                 distinct(q);
    q = baseQuery(); q.patio = true;                distinct(q);
    q = baseQuery(); q.group = true;                distinct(q);
    q = baseQuery(); q.parking = true;              distinct(q);
}

// The same coordinates must produce the same key on every run and platform;
// sloppy float formatting would silently halve the hit rate.
DROGON_TEST(NearbyKeyIsStableForIdenticalCoordinates) {
    Fixture f;
    auto a = baseQuery();
    auto b = baseQuery();
    drogon::sync_wait(f.service->nearby(a));
    const auto second = drogon::sync_wait(f.service->nearby(b));

    CHECK(second.cache == "HIT");
    CHECK(f.upstream->searchCalls == 1);
}

// Scenario 5 — an upstream failure must not be cached.
DROGON_TEST(NearbyDoesNotCacheUpstreamFailures) {
    Fixture f;
    f.upstream->status = 500;

    const auto failed = drogon::sync_wait(f.service->nearby(baseQuery()));
    CHECK(failed.status != 200);

    f.upstream->status = 200;
    const auto retried = drogon::sync_wait(f.service->nearby(baseQuery()));
    CHECK(retried.cache == "MISS");  // the failure was not served from cache
    CHECK(retried.status == 200);
    CHECK(f.upstream->searchCalls == 2);
}

// The details path has the same contract, with its own TTL.
DROGON_TEST(DetailsMissesThenHits) {
    Fixture f;
    const auto first = drogon::sync_wait(f.service->details("abc"));
    CHECK(first.cache == "MISS");
    CHECK(first.ttlSeconds == kDetailsTtl);
    CHECK(f.upstream->detailsCalls == 1);

    const auto second = drogon::sync_wait(f.service->details("abc"));
    CHECK(second.cache == "HIT");
    CHECK(second.upstreamMs == 0);
    CHECK(f.upstream->detailsCalls == 1);
}

DROGON_TEST(DetailsKeyVariesByPlaceId) {
    Fixture f;
    drogon::sync_wait(f.service->details("abc"));
    const auto other = drogon::sync_wait(f.service->details("xyz"));

    CHECK(other.cache == "MISS");
    CHECK(f.upstream->detailsCalls == 2);
}

DROGON_TEST(DetailsMissesAgainAfterTtlElapses) {
    Fixture f;
    drogon::sync_wait(f.service->details("abc"));
    f.clock->advance(kDetailsTtl + 1);

    const auto after = drogon::sync_wait(f.service->details("abc"));
    CHECK(after.cache == "MISS");
    CHECK(f.upstream->detailsCalls == 2);
}

DROGON_TEST(DetailsDoesNotCacheUpstreamFailures) {
    Fixture f;
    f.upstream->status = 404;
    const auto failed = drogon::sync_wait(f.service->details("abc"));
    CHECK(failed.status != 200);

    f.upstream->status = 200;
    const auto retried = drogon::sync_wait(f.service->details("abc"));
    CHECK(retried.cache == "MISS");
    CHECK(f.upstream->detailsCalls == 2);
}
