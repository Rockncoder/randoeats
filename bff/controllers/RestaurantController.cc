#include "RestaurantController.h"

#include <algorithm>
#include <string>

#include "../services/AppContext.h"
#include "../services/GooglePlacesClient.h"
#include "../services/PlacesService.h"

using drogon::HttpResponse;
using drogon::HttpResponsePtr;

namespace {

// Stash metrics facts on the request for the post-handling advice in main.cc.
void recordMetrics(const drogon::HttpRequestPtr& req, const std::string& cache,
                   long upstreamMs, const std::string& endpoint) {
  req->attributes()->insert("m_cache", cache);
  req->attributes()->insert("m_upstream", static_cast<int64_t>(upstreamMs));
  req->attributes()->insert("m_endpoint", endpoint);
}

HttpResponsePtr jsonResponse(const ServiceResult& result) {
  auto resp = HttpResponse::newHttpResponse();
  resp->setStatusCode(static_cast<drogon::HttpStatusCode>(result.status));
  resp->setContentTypeCode(drogon::CT_APPLICATION_JSON);
  resp->setBody(result.body);
  if (result.ttlSeconds > 0) {
    resp->addHeader("Cache-Control",
                    "public, max-age=" + std::to_string(result.ttlSeconds));
  }
  return resp;
}

HttpResponsePtr errorResponse(int status, const std::string& message) {
  auto resp = HttpResponse::newHttpResponse();
  resp->setStatusCode(static_cast<drogon::HttpStatusCode>(status));
  resp->setContentTypeCode(drogon::CT_APPLICATION_JSON);
  resp->setBody("{\"error\":\"" + message + "\"}");
  return resp;
}

}  // namespace

drogon::Task<HttpResponsePtr> RestaurantController::nearby(
    drogon::HttpRequestPtr req) {
  const auto& params = req->getParameters();
  if (!params.count("lat") || !params.count("lng")) {
    recordMetrics(req, "NONE", 0, "");
    co_return errorResponse(400, "lat and lng are required");
  }

  const double lat = std::stod(req->getParameter("lat"));
  const double lng = std::stod(req->getParameter("lng"));
  int radius =
      params.count("radius") ? std::stoi(req->getParameter("radius")) : 5000;
  radius = std::clamp(radius, 1, 50000);
  std::string type =
      params.count("type") ? req->getParameter("type") : "restaurant";
  int maxResults =
      params.count("max") ? std::stoi(req->getParameter("max")) : 20;
  maxResults = std::clamp(maxResults, 1, 20);

  const ServiceResult result = co_await AppContext::instance().places->nearby(
      lat, lng, radius, std::move(type), maxResults);
  recordMetrics(req, result.cache, result.upstreamMs, "nearby_search");
  co_return jsonResponse(result);
}

drogon::Task<HttpResponsePtr> RestaurantController::details(
    drogon::HttpRequestPtr req, std::string placeId) {
  const ServiceResult result =
      co_await AppContext::instance().places->details(placeId);
  recordMetrics(req, result.cache, result.upstreamMs, "place_details");
  co_return jsonResponse(result);
}

drogon::Task<HttpResponsePtr> RestaurantController::photo(
    drogon::HttpRequestPtr req, std::string /*placeId*/) {
  const auto& params = req->getParameters();
  if (!params.count("photo_ref")) {
    recordMetrics(req, "NONE", 0, "photo");
    co_return errorResponse(400, "photo_ref is required");
  }
  const std::string photoRef = req->getParameter("photo_ref");
  int maxWidth = params.count("max_width")
                     ? std::stoi(req->getParameter("max_width"))
                     : 400;
  maxWidth = std::clamp(maxWidth, 1, 1600);

  const PhotoResult photo =
      co_await AppContext::instance().google->getPhoto(photoRef, maxWidth);
  recordMetrics(req, "NONE", photo.upstreamMs, "photo");

  if (photo.status != 200 || photo.bytes.empty()) {
    co_return errorResponse(photo.status == 404 ? 404 : 502,
                            "photo unavailable");
  }

  auto resp = HttpResponse::newHttpResponse();
  resp->setStatusCode(drogon::k200OK);
  resp->setContentTypeString(photo.contentType);
  resp->setBody(photo.bytes);
  resp->addHeader("Cache-Control", "public, max-age=604800");  // 7 days
  co_return resp;
}
