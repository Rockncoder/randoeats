#pragma once

#include "services/IPlacesUpstream.h"

#include <atomic>
#include <string>

/// Scripted stand-in for [GooglePlacesClient].
///
/// Exists so a test can assert the thing that actually costs money: that an
/// upstream call was *not* made. Every method records its invocation count, and
/// no method performs I/O, so the suite never contacts Google and never needs a
/// real API key.
class FakePlacesUpstream : public IPlacesUpstream {
  public:
    /// HTTP status the next call returns. 0 models a transport failure.
    int status = 200;
    /// Milliseconds reported as upstream time, so HIT (0) is distinguishable.
    long upstreamMs = 42;
    /// Place id echoed into the canned payload, to tell responses apart.
    std::string placeId = "place-1";

    std::atomic<int> searchCalls{0};
    std::atomic<int> detailsCalls{0};
    std::atomic<int> photoCalls{0};

    int totalCalls() const { return searchCalls + detailsCalls + photoCalls; }

    drogon::Task<UpstreamResult> searchText(SearchParams /*params*/) override {
        ++searchCalls;
        UpstreamResult result;
        result.status = status;
        result.upstreamMs = upstreamMs;
        if (status == 200) {
            Json::Value place;
            place["id"] = placeId;
            Json::Value places(Json::arrayValue);
            places.append(place);
            result.json["places"] = places;
        }
        co_return result;
    }

    drogon::Task<UpstreamResult> getDetails(std::string id) override {
        ++detailsCalls;
        UpstreamResult result;
        result.status = status;
        result.upstreamMs = upstreamMs;
        if (status == 200) {
            result.json["id"] = id;
        }
        co_return result;
    }

    drogon::Task<PhotoResult> getPhoto(std::string /*photoName*/, int /*maxWidth*/) override {
        ++photoCalls;
        PhotoResult result;
        result.status = status;
        result.upstreamMs = upstreamMs;
        co_return result;
    }
};
