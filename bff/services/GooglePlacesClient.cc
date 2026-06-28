#include "GooglePlacesClient.h"

#include <algorithm>
#include <chrono>

namespace {

constexpr char kPlacesHost[] = "https://places.googleapis.com";

// SKU: ENTERPRISE — list view. rating/userRatingCount/priceLevel set the tier.
constexpr char kNearbyMask[] =
    "places.id,places.displayName,places.formattedAddress,places.location,"
    "places.rating,places.userRatingCount,places.priceLevel,"
    "places.primaryType,places.currentOpeningHours.openNow,places.photos";

// Added to the list mask only when an atmosphere filter is active. SKU bumps to
// ENTERPRISE + ATMOSPHERE for that request.
constexpr char kNearbyAtmosphereMask[] =
    ",places.servesBeer,places.servesWine,places.outdoorSeating,"
    "places.goodForGroups,places.parkingOptions";

// SKU: ENTERPRISE + ATMOSPHERE — detail view (single place; fields are bare,
// no "places." prefix).
constexpr char kDetailsMask[] =
    "id,displayName,formattedAddress,location,rating,userRatingCount,"
    "priceLevel,primaryType,currentOpeningHours,nationalPhoneNumber,"
    "websiteUri,photos,editorialSummary,servesBeer,servesWine,outdoorSeating,"
    "goodForGroups,parkingOptions";

long elapsedMs(std::chrono::steady_clock::time_point start) {
  return std::chrono::duration_cast<std::chrono::milliseconds>(
             std::chrono::steady_clock::now() - start)
      .count();
}

std::string priceLevelEnum(int level) {
  switch (level) {
    case 1: return "PRICE_LEVEL_INEXPENSIVE";
    case 2: return "PRICE_LEVEL_MODERATE";
    case 3: return "PRICE_LEVEL_EXPENSIVE";
    case 4: return "PRICE_LEVEL_VERY_EXPENSIVE";
    default: return "";
  }
}

}  // namespace

GooglePlacesClient::GooglePlacesClient(std::string apiKey)
    : apiKey_(std::move(apiKey)) {}

drogon::Task<UpstreamResult> GooglePlacesClient::searchText(SearchParams p) {
  // Body shared across pages (must stay constant when a pageToken is supplied).
  Json::Value base;
  base["textQuery"] =
      p.query.empty() ? "restaurant" : (p.query + " restaurant");
  base["includedType"] = "restaurant";
  auto& circle = base["locationBias"]["circle"];
  circle["center"]["latitude"] = p.lat;
  circle["center"]["longitude"] = p.lng;
  circle["radius"] = static_cast<double>(p.radius);
  if (p.openNow) base["openNow"] = true;
  if (p.minRating > 0) base["minRating"] = p.minRating;
  for (int level : p.priceLevels) {
    const std::string e = priceLevelEnum(level);
    if (!e.empty()) base["priceLevels"].append(e);
  }

  std::string mask = kNearbyMask;
  if (p.includeAtmosphere) mask += kNearbyAtmosphereMask;
  mask += ",nextPageToken";

  const int pageSize = std::clamp(p.maxResults, 1, 20);
  Json::StreamWriterBuilder writer;
  writer["indentation"] = "";

  UpstreamResult result;
  result.json["places"] = Json::Value(Json::arrayValue);
  std::string pageToken;
  bool firstPage = true;
  const auto start = std::chrono::steady_clock::now();

  try {
    auto client = drogon::HttpClient::newHttpClient(kPlacesHost);
    do {
      // A freshly issued page token can need a moment to become valid. Sleep
      // without blocking the event loop.
      if (!firstPage) {
        co_await drogon::sleepCoro(
            trantor::EventLoop::getEventLoopOfCurrentThread(),
            std::chrono::milliseconds(300));
      }
      Json::Value body = base;
      body["pageSize"] = pageSize;
      if (!pageToken.empty()) body["pageToken"] = pageToken;

      auto req = drogon::HttpRequest::newHttpRequest();
      req->setMethod(drogon::Post);
      req->setPath("/v1/places:searchText");
      req->addHeader("X-Goog-Api-Key", apiKey_);
      req->addHeader("X-Goog-FieldMask", mask);
      req->setContentTypeCode(drogon::CT_APPLICATION_JSON);
      req->setBody(Json::writeString(writer, body));

      try {
        auto resp = co_await client->sendRequestCoro(req);
        const int status = static_cast<int>(resp->getStatusCode());
        if (firstPage) result.status = status;
        if (status != 200) break;  // keep any pages already collected
        if (auto json = resp->getJsonObject()) {
          for (const auto& place : (*json)["places"]) {
            result.json["places"].append(place);
          }
          pageToken = (*json).get("nextPageToken", "").asString();
        } else {
          break;
        }
      } catch (const std::exception& e) {
        LOG_ERROR << "searchText page error: " << e.what();
        if (firstPage) result.status = 0;
        break;
      }
      firstPage = false;
    } while (!pageToken.empty() &&
             static_cast<int>(result.json["places"].size()) < p.maxResults);
  } catch (const std::exception& e) {
    LOG_ERROR << "searchText error: " << e.what();
    result.status = 0;
  }

  result.upstreamMs = elapsedMs(start);
  co_return result;
}

drogon::Task<UpstreamResult> GooglePlacesClient::getDetails(
    std::string placeId) {
  auto req = drogon::HttpRequest::newHttpRequest();
  req->setMethod(drogon::Get);
  req->setPath("/v1/places/" + placeId);
  req->addHeader("X-Goog-Api-Key", apiKey_);
  req->addHeader("X-Goog-FieldMask", kDetailsMask);

  UpstreamResult result;
  const auto start = std::chrono::steady_clock::now();
  try {
    auto client = drogon::HttpClient::newHttpClient(kPlacesHost);
    auto resp = co_await client->sendRequestCoro(req);
    result.status = static_cast<int>(resp->getStatusCode());
    if (auto json = resp->getJsonObject()) result.json = *json;
  } catch (const std::exception& e) {
    LOG_ERROR << "getDetails upstream error: " << e.what();
    result.status = 0;
  }
  result.upstreamMs = elapsedMs(start);
  co_return result;
}

drogon::Task<PhotoResult> GooglePlacesClient::getPhoto(std::string photoName,
                                                       int maxWidth) {
  PhotoResult result;
  const auto start = std::chrono::steady_clock::now();
  try {
    // Step 1: ask Google for the photo's CDN URL (skipHttpRedirect=true returns
    // JSON {photoUri} instead of a 302). This is the billed PHOTO SKU call.
    auto req = drogon::HttpRequest::newHttpRequest();
    req->setMethod(drogon::Get);
    req->setPath("/v1/" + photoName + "/media");
    req->setParameter("maxWidthPx", std::to_string(maxWidth));
    req->setParameter("skipHttpRedirect", "true");
    req->addHeader("X-Goog-Api-Key", apiKey_);

    auto client = drogon::HttpClient::newHttpClient(kPlacesHost);
    auto resp = co_await client->sendRequestCoro(req);
    result.status = static_cast<int>(resp->getStatusCode());
    if (result.status != 200) {
      result.upstreamMs = elapsedMs(start);
      co_return result;
    }

    std::string photoUri;
    if (auto json = resp->getJsonObject()) {
      photoUri = (*json)["photoUri"].asString();
    }
    if (photoUri.empty()) {
      result.status = 502;
      result.upstreamMs = elapsedMs(start);
      co_return result;
    }

    // Step 2: fetch the actual image bytes from the (pre-signed) CDN URL. No
    // API key needed; this hop isn't billed.
    const auto schemeEnd = photoUri.find("://");
    const auto hostStart = schemeEnd == std::string::npos ? 0 : schemeEnd + 3;
    const auto pathStart = photoUri.find('/', hostStart);
    const std::string origin = photoUri.substr(0, pathStart);
    const std::string path =
        pathStart == std::string::npos ? "/" : photoUri.substr(pathStart);

    auto cdnReq = drogon::HttpRequest::newHttpRequest();
    cdnReq->setMethod(drogon::Get);
    cdnReq->setPath(path);
    auto cdnClient = drogon::HttpClient::newHttpClient(origin);
    auto cdnResp = co_await cdnClient->sendRequestCoro(cdnReq);
    result.status = static_cast<int>(cdnResp->getStatusCode());
    if (result.status == 200) {
      const auto body = cdnResp->getBody();
      result.bytes.assign(body.data(), body.size());
      result.contentType = cdnResp->getHeader("content-type");
      if (result.contentType.empty()) result.contentType = "image/jpeg";
    }
  } catch (const std::exception& e) {
    LOG_ERROR << "getPhoto upstream error: " << e.what();
    result.status = 0;
  }
  result.upstreamMs = elapsedMs(start);
  co_return result;
}
