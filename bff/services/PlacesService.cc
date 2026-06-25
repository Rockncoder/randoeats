#include "PlacesService.h"

#include <array>
#include <cstdio>

namespace {

std::string serializeCompact(const Json::Value& value) {
  Json::StreamWriterBuilder builder;
  builder["indentation"] = "";
  return Json::writeString(builder, value);
}

int priceLevelToInt(const std::string& enumName) {
  if (enumName == "PRICE_LEVEL_FREE") return 0;
  if (enumName == "PRICE_LEVEL_INEXPENSIVE") return 1;
  if (enumName == "PRICE_LEVEL_MODERATE") return 2;
  if (enumName == "PRICE_LEVEL_EXPENSIVE") return 3;
  if (enumName == "PRICE_LEVEL_VERY_EXPENSIVE") return 4;
  return -1;  // unknown / absent
}

std::string errorBody(const std::string& message) {
  Json::Value e;
  e["error"] = message;
  return serializeCompact(e);
}

}  // namespace

PlacesService::PlacesService(std::shared_ptr<GooglePlacesClient> client,
                             std::shared_ptr<ICache> cache, int nearbyTtl,
                             int detailsTtl)
    : client_(std::move(client)),
      cache_(std::move(cache)),
      nearbyTtl_(nearbyTtl),
      detailsTtl_(detailsTtl) {}

std::string PlacesService::serialize(const Json::Value& value) {
  return serializeCompact(value);
}

Json::Value PlacesService::normalize(const Json::Value& place) {
  Json::Value out;
  out["id"] = place.get("id", "").asString();
  if (place.isMember("displayName")) {
    out["name"] = place["displayName"].get("text", "").asString();
  }
  if (place.isMember("formattedAddress")) {
    out["address"] = place["formattedAddress"].asString();
  }
  if (place.isMember("location")) {
    out["location"]["lat"] = place["location"].get("latitude", 0.0).asDouble();
    out["location"]["lng"] = place["location"].get("longitude", 0.0).asDouble();
  }
  if (place.isMember("rating")) out["rating"] = place["rating"].asDouble();
  if (place.isMember("userRatingCount")) {
    out["ratingCount"] = place["userRatingCount"].asInt();
  }
  if (place.isMember("priceLevel")) {
    const int level = priceLevelToInt(place["priceLevel"].asString());
    if (level >= 0) out["priceLevel"] = level;
  }
  if (place.isMember("primaryType")) {
    out["type"] = place["primaryType"].asString();
  }
  if (place.isMember("currentOpeningHours") &&
      place["currentOpeningHours"].isMember("openNow")) {
    out["openNow"] = place["currentOpeningHours"]["openNow"].asBool();
  }
  if (place.isMember("nationalPhoneNumber")) {
    out["phone"] = place["nationalPhoneNumber"].asString();
  }
  if (place.isMember("websiteUri")) {
    out["website"] = place["websiteUri"].asString();
  }
  // photoRefs is always present (possibly empty) so the client can rely on it.
  out["photoRefs"] = Json::Value(Json::arrayValue);
  if (place.isMember("photos")) {
    for (const auto& photo : place["photos"]) {
      out["photoRefs"].append(photo.get("name", "").asString());
    }
  }
  return out;
}

drogon::Task<ServiceResult> PlacesService::nearby(double lat, double lng,
                                                  int radius, std::string type,
                                                  int maxResults) {
  // Round lat/lng to ~110 m so nearby searches in the same vicinity share a
  // cache entry.
  std::array<char, 128> key{};
  std::snprintf(key.data(), key.size(), "nearby:%.3f:%.3f:%d:%s", lat, lng,
                radius, type.c_str());
  const std::string cacheKey(key.data());

  if (auto cached = cache_->get(cacheKey)) {
    co_return ServiceResult{200, *cached, "HIT", 0, nearbyTtl_};
  }

  const UpstreamResult up =
      co_await client_->searchNearby(lat, lng, radius, type, maxResults);

  if (up.status == 0) {
    co_return ServiceResult{502, errorBody("upstream unavailable"), "MISS",
                            up.upstreamMs, 0};
  }
  if (up.status != 200) {
    co_return ServiceResult{502, errorBody("upstream error"), "MISS",
                            up.upstreamMs, 0};
  }

  Json::Value out;
  out["restaurants"] = Json::Value(Json::arrayValue);
  if (up.json.isMember("places")) {
    for (const auto& place : up.json["places"]) {
      out["restaurants"].append(normalize(place));
    }
  }
  const std::string body = serialize(out);
  cache_->set(cacheKey, body, nearbyTtl_);
  co_return ServiceResult{200, body, "MISS", up.upstreamMs, nearbyTtl_};
}

drogon::Task<ServiceResult> PlacesService::details(std::string placeId) {
  const std::string cacheKey = "details:" + placeId;

  if (auto cached = cache_->get(cacheKey)) {
    co_return ServiceResult{200, *cached, "HIT", 0, detailsTtl_};
  }

  const UpstreamResult up = co_await client_->getDetails(placeId);

  if (up.status == 0) {
    co_return ServiceResult{502, errorBody("upstream unavailable"), "MISS",
                            up.upstreamMs, 0};
  }
  if (up.status == 404) {
    co_return ServiceResult{404, errorBody("not found"), "MISS", up.upstreamMs,
                            0};
  }
  if (up.status != 200) {
    co_return ServiceResult{502, errorBody("upstream error"), "MISS",
                            up.upstreamMs, 0};
  }

  const std::string body = serialize(normalize(up.json));
  cache_->set(cacheKey, body, detailsTtl_);
  co_return ServiceResult{200, body, "MISS", up.upstreamMs, detailsTtl_};
}
