#include "GooglePlacesClient.h"

#include <chrono>

namespace {

constexpr char kPlacesHost[] = "https://places.googleapis.com";

// SKU: ENTERPRISE — rating/userRatingCount/priceLevel push the whole call to
// the Enterprise tier. Keep this mask to the minimum the list view needs.
constexpr char kNearbyMask[] =
    "places.id,places.displayName,places.formattedAddress,places.location,"
    "places.rating,places.userRatingCount,places.priceLevel,"
    "places.primaryType,places.currentOpeningHours.openNow,places.photos";

// SKU: ENTERPRISE — detail view.
constexpr char kDetailsMask[] =
    "id,displayName,formattedAddress,location,rating,userRatingCount,"
    "priceLevel,primaryType,currentOpeningHours,nationalPhoneNumber,"
    "websiteUri,photos";

long elapsedMs(std::chrono::steady_clock::time_point start) {
  return std::chrono::duration_cast<std::chrono::milliseconds>(
             std::chrono::steady_clock::now() - start)
      .count();
}

}  // namespace

GooglePlacesClient::GooglePlacesClient(std::string apiKey)
    : apiKey_(std::move(apiKey)) {}

drogon::Task<UpstreamResult> GooglePlacesClient::searchNearby(
    double lat, double lng, int radius, std::string type, int maxResults) {
  Json::Value body;
  body["includedTypes"].append(type);
  body["maxResultCount"] = maxResults;
  auto& circle = body["locationRestriction"]["circle"];
  circle["center"]["latitude"] = lat;
  circle["center"]["longitude"] = lng;
  circle["radius"] = static_cast<double>(radius);

  Json::StreamWriterBuilder builder;
  builder["indentation"] = "";

  auto req = drogon::HttpRequest::newHttpRequest();
  req->setMethod(drogon::Post);
  req->setPath("/v1/places:searchNearby");
  req->addHeader("X-Goog-Api-Key", apiKey_);
  req->addHeader("X-Goog-FieldMask", kNearbyMask);
  req->setContentTypeCode(drogon::CT_APPLICATION_JSON);
  req->setBody(Json::writeString(builder, body));

  UpstreamResult result;
  const auto start = std::chrono::steady_clock::now();
  try {
    auto client = drogon::HttpClient::newHttpClient(kPlacesHost);
    auto resp = co_await client->sendRequestCoro(req);
    result.status = static_cast<int>(resp->getStatusCode());
    if (auto json = resp->getJsonObject()) result.json = *json;
  } catch (const std::exception& e) {
    LOG_ERROR << "searchNearby upstream error: " << e.what();
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
