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
    std::string query;  // empty → browse all ("restaurant")
    double lat = 0;
    double lng = 0;
    int radius = 5000;
    int maxResults = 20;  // total wanted; paginated up to ~60
    bool openNow = false;
    double minRating = 0;            // <= 0 → no minimum
    std::vector<int> priceLevels;    // 1..4; empty → any
    bool includeAtmosphere = false;  // add the pricier atmosphere fields
};

/// Upstream abstraction so the service layer never depends on a concrete
/// client. The only production implementation is [GooglePlacesClient]; tests
/// substitute a scripted double so a test can assert that Google was *not*
/// called, and so no test ever performs network I/O or needs a real API key.
///
/// This mirrors [ICache]'s role for the cache: the seam exists to keep
/// PlacesService free of a concrete dependency, not to anticipate a second
/// upstream provider.
class IPlacesUpstream {
  public:
    IPlacesUpstream() = default;
    virtual ~IPlacesUpstream() = default;

    // Held only by shared_ptr and never copied; deleting these keeps
    // cppcoreguidelines-special-member-functions satisfied without inventing
    // copy semantics for an interface that has no state.
    IPlacesUpstream(const IPlacesUpstream&) = delete;
    IPlacesUpstream& operator=(const IPlacesUpstream&) = delete;
    IPlacesUpstream(IPlacesUpstream&&) = delete;
    IPlacesUpstream& operator=(IPlacesUpstream&&) = delete;

    /// Text Search with pagination. Returns a merged {"places":[...]}.
    virtual drogon::Task<UpstreamResult> searchText(SearchParams params) = 0;

    /// Place Details (full).
    virtual drogon::Task<UpstreamResult> getDetails(std::string placeId) = 0;

    /// Place Photo bytes (proxied, not cached).
    virtual drogon::Task<PhotoResult> getPhoto(std::string photoName, int maxWidth) = 0;
};
