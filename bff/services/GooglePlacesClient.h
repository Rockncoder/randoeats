#pragma once

#include "IPlacesUpstream.h"

#include <drogon/drogon.h>

#include <json/json.h>
#include <string>
#include <vector>

/// §0 — The ONLY component permitted to make upstream calls to Google Places
/// (New). Every method documents the billing SKU tier it triggers.
class GooglePlacesClient : public IPlacesUpstream {
  public:
    explicit GooglePlacesClient(std::string apiKey);

    /// Text Search with pagination. SKU: ENTERPRISE (+ ATMOSPHERE when
    /// params.includeAtmosphere). Upstream: POST /v1/places:searchText, paged via
    /// nextPageToken. Returns a merged {"places":[...]} across pages.
    drogon::Task<UpstreamResult> searchText(SearchParams params) override;

    /// Place Details (full). SKU: ENTERPRISE + ATMOSPHERE — includes
    /// editorialSummary, hours, phone/website, and the atmosphere flags.
    /// Upstream: GET /v1/places/{placeId}.
    drogon::Task<UpstreamResult> getDetails(std::string placeId) override;

    /// Place Photo. SKU: PHOTO. Upstream: GET /v1/{photoName}/media, then the
    /// returned googleusercontent URL for the bytes (proxied, not cached).
    drogon::Task<PhotoResult> getPhoto(std::string photoName, int maxWidth) override;

  private:
    std::string apiKey_;
};
