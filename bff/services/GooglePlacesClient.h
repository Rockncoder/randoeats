#pragma once

#include <drogon/drogon.h>
#include <json/json.h>

#include <string>
#include <vector>

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

/// Inputs for a restaurant Text Search.
struct SearchParams {
  std::string query;             // empty → browse all ("restaurant")
  double lat = 0;
  double lng = 0;
  int radius = 5000;
  int maxResults = 20;           // total wanted; paginated up to ~60
  bool openNow = false;
  double minRating = 0;          // <= 0 → no minimum
  std::vector<int> priceLevels;  // 1..4; empty → any
  bool includeAtmosphere = false;  // add the pricier atmosphere fields
};

/// §0 — The ONLY component permitted to make upstream calls to Google Places
/// (New). Every method documents the billing SKU tier it triggers.
class GooglePlacesClient {
 public:
  explicit GooglePlacesClient(std::string apiKey);

  /// Text Search with pagination. SKU: ENTERPRISE (+ ATMOSPHERE when
  /// params.includeAtmosphere). Upstream: POST /v1/places:searchText, paged via
  /// nextPageToken. Returns a merged {"places":[...]} across pages.
  drogon::Task<UpstreamResult> searchText(SearchParams params);

  /// Place Details (full). SKU: ENTERPRISE + ATMOSPHERE — includes
  /// editorialSummary, hours, phone/website, and the atmosphere flags.
  /// Upstream: GET /v1/places/{placeId}.
  drogon::Task<UpstreamResult> getDetails(std::string placeId);

  /// Place Photo. SKU: PHOTO. Upstream: GET /v1/{photoName}/media, then the
  /// returned googleusercontent URL for the bytes (proxied, not cached).
  drogon::Task<PhotoResult> getPhoto(std::string photoName, int maxWidth);

 private:
  std::string apiKey_;
};
