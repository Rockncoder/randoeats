#pragma once

#include <drogon/drogon.h>
#include <json/json.h>

#include <memory>
#include <string>

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

/// Business logic: cache lookup, upstream fetch via GooglePlacesClient, and
/// normalization to the stable client contract. Never returns raw Google JSON.
class PlacesService {
 public:
  PlacesService(std::shared_ptr<GooglePlacesClient> client,
                std::shared_ptr<ICache> cache, int nearbyTtl, int detailsTtl);

  drogon::Task<ServiceResult> nearby(double lat, double lng, int radius,
                                     std::string type, int maxResults);
  drogon::Task<ServiceResult> details(std::string placeId);

 private:
  /// Maps one raw Google place to the normalized restaurant contract.
  static Json::Value normalize(const Json::Value& place);
  static std::string serialize(const Json::Value& value);

  std::shared_ptr<GooglePlacesClient> client_;
  std::shared_ptr<ICache> cache_;
  int nearbyTtl_;
  int detailsTtl_;
};
