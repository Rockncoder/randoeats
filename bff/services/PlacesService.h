#pragma once

#include <drogon/drogon.h>
#include <json/json.h>

#include <memory>
#include <string>
#include <vector>

#include "GooglePlacesClient.h"
#include "ICache.h"

/// Outcome of a service call, carrying everything the controller needs to build
/// the HTTP response and the metrics record.
struct ServiceResult {
  int status = 200;
  std::string body;            // normalized JSON string (or {"error":...})
  std::string cache = "MISS";  // HIT or MISS
  long upstreamMs = 0;
  int ttlSeconds = 0;          // for the Cache-Control header
};

/// A normalized nearby query: keyword + location + the full filter set the app
/// supports (server-side: open/rating/price; atmosphere: beer/wine/patio/group/
/// parking, applied client-side here since Places can't filter them upstream).
struct NearbyQuery {
  std::string query;
  double lat = 0;
  double lng = 0;
  int radius = 5000;
  int maxResults = 20;
  bool openNow = false;
  double minRating = 0;
  std::vector<int> priceLevels;
  bool beer = false;
  bool wine = false;
  bool patio = false;
  bool group = false;
  bool parking = false;
};

/// Business logic: cache lookup, upstream fetch via GooglePlacesClient, and
/// normalization to the stable client contract. Never returns raw Google JSON.
class PlacesService {
 public:
  PlacesService(std::shared_ptr<GooglePlacesClient> client,
                std::shared_ptr<ICache> cache, int nearbyTtl, int detailsTtl);

  drogon::Task<ServiceResult> nearby(NearbyQuery query);
  drogon::Task<ServiceResult> details(std::string placeId);

 private:
  /// Maps one raw Google place to the normalized restaurant contract. Fields
  /// not present in the upstream payload are simply omitted, so this serves both
  /// the lean list mask and the full detail mask.
  static Json::Value normalize(const Json::Value& place);
  static std::string serialize(const Json::Value& value);

  std::shared_ptr<GooglePlacesClient> client_;
  std::shared_ptr<ICache> cache_;
  int nearbyTtl_;
  int detailsTtl_;
};
