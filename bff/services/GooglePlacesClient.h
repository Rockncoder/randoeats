#pragma once

#include <drogon/drogon.h>
#include <json/json.h>

#include <string>

/// Result of an upstream JSON call to Google.
struct UpstreamResult {
  int status = 0;       // HTTP status from Google; 0 = transport failure
  Json::Value json;     // parsed response body (object), or null
  long upstreamMs = 0;  // wall time spent on the Google call(s)
};

/// Result of an upstream photo (binary) fetch.
struct PhotoResult {
  int status = 0;
  std::string bytes;
  std::string contentType;
  long upstreamMs = 0;
};

/// §0 — The ONLY component permitted to make upstream calls to Google Places
/// (New). All controllers/services go through here, so every outbound call is
/// auditable in one file. Each method documents the billing SKU tier it
/// triggers via its field mask.
class GooglePlacesClient {
 public:
  explicit GooglePlacesClient(std::string apiKey);

  /// Nearby Search. SKU: ENTERPRISE (mask includes rating/userRatingCount/
  /// priceLevel). Upstream: POST /v1/places:searchNearby.
  drogon::Task<UpstreamResult> searchNearby(double lat, double lng, int radius,
                                            std::string type, int maxResults);

  /// Place Details. SKU: ENTERPRISE. Upstream: GET /v1/places/{placeId}.
  drogon::Task<UpstreamResult> getDetails(std::string placeId);

  /// Place Photo. SKU: PHOTO. Upstream: GET /v1/{photoName}/media, then the
  /// returned googleusercontent URL for the bytes (proxied, not cached).
  drogon::Task<PhotoResult> getPhoto(std::string photoName, int maxWidth);

 private:
  std::string apiKey_;
};
