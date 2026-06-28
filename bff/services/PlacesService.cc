#include "PlacesService.h"

#include <array>
#include <cstdio>
#include <string>

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

// True only when Google affirmatively reports the flag (null/absent → false),
// matching the app's strict client-side atmosphere filtering.
bool flagTrue(const Json::Value& place, const char* field) {
  return place.isMember(field) && place[field].asBool();
}

bool hasParking(const Json::Value& place) {
  if (!place.isMember("parkingOptions")) return false;
  for (const auto& v : place["parkingOptions"]) {
    if (v.isBool() && v.asBool()) return true;
  }
  return false;
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
  if (place.isMember("currentOpeningHours")) {
    const auto& hours = place["currentOpeningHours"];
    if (hours.isMember("openNow")) out["openNow"] = hours["openNow"].asBool();
    if (hours.isMember("weekdayDescriptions")) {
      out["weekdayHours"] = Json::Value(Json::arrayValue);
      for (const auto& line : hours["weekdayDescriptions"]) {
        out["weekdayHours"].append(line.asString());
      }
    }
  }
  if (place.isMember("nationalPhoneNumber")) {
    out["phone"] = place["nationalPhoneNumber"].asString();
  }
  if (place.isMember("websiteUri")) {
    out["website"] = place["websiteUri"].asString();
  }
  if (place.isMember("editorialSummary")) {
    out["editorialSummary"] = place["editorialSummary"].get("text", "").asString();
  }
  // Atmosphere flags are included only when present (i.e. requested upstream).
  if (place.isMember("servesBeer")) out["servesBeer"] = place["servesBeer"].asBool();
  if (place.isMember("servesWine")) out["servesWine"] = place["servesWine"].asBool();
  if (place.isMember("outdoorSeating")) {
    out["outdoorSeating"] = place["outdoorSeating"].asBool();
  }
  if (place.isMember("goodForGroups")) {
    out["goodForGroups"] = place["goodForGroups"].asBool();
  }
  if (place.isMember("parkingOptions")) out["hasParking"] = hasParking(place);
  // photoRefs always present (possibly empty) so the client can rely on it.
  out["photoRefs"] = Json::Value(Json::arrayValue);
  if (place.isMember("photos")) {
    for (const auto& photo : place["photos"]) {
      out["photoRefs"].append(photo.get("name", "").asString());
    }
  }
  return out;
}

drogon::Task<ServiceResult> PlacesService::nearby(NearbyQuery q) {
  const bool usesAtmosphere =
      q.beer || q.wine || q.patio || q.group || q.parking;

  // Cache key covers every input that changes the result set.
  std::string priceKey;
  for (int level : q.priceLevels) priceKey += std::to_string(level);
  std::array<char, 256> key{};
  std::snprintf(key.data(), key.size(),
                "nearby:%.3f:%.3f:%d:%d:%s:o%d:r%.1f:p%s:%d%d%d%d%d", q.lat,
                q.lng, q.radius, q.maxResults, q.query.c_str(),
                q.openNow ? 1 : 0, q.minRating, priceKey.c_str(),
                q.beer ? 1 : 0, q.wine ? 1 : 0, q.patio ? 1 : 0,
                q.group ? 1 : 0, q.parking ? 1 : 0);
  const std::string cacheKey(key.data());

  if (auto cached = cache_->get(cacheKey)) {
    co_return ServiceResult{200, *cached, "HIT", 0, nearbyTtl_};
  }

  SearchParams sp;
  sp.query = q.query;
  sp.lat = q.lat;
  sp.lng = q.lng;
  sp.radius = q.radius;
  sp.maxResults = q.maxResults;
  sp.openNow = q.openNow;
  sp.minRating = q.minRating;
  sp.priceLevels = q.priceLevels;
  sp.includeAtmosphere = usesAtmosphere;

  const UpstreamResult up = co_await client_->searchText(sp);
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
  for (const auto& place : up.json["places"]) {
    // Client-side atmosphere filtering (Places can't do it server-side).
    if (q.beer && !flagTrue(place, "servesBeer")) continue;
    if (q.wine && !flagTrue(place, "servesWine")) continue;
    if (q.patio && !flagTrue(place, "outdoorSeating")) continue;
    if (q.group && !flagTrue(place, "goodForGroups")) continue;
    if (q.parking && !hasParking(place)) continue;
    out["restaurants"].append(normalize(place));
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
