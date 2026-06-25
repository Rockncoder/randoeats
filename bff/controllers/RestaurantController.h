#pragma once

#include <drogon/HttpController.h>

#include <string>

/// Maps the public `/api/v1/restaurants/...` routes to PlacesService. Controllers
/// never call GooglePlacesClient directly — only PlacesService (and, for the raw
/// photo bytes, the client via the same AppContext). See AppContext for wiring.
class RestaurantController
    : public drogon::HttpController<RestaurantController> {
 public:
  METHOD_LIST_BEGIN
  ADD_METHOD_TO(RestaurantController::nearby, "/api/v1/restaurants/nearby",
                drogon::Get);
  // Photo route is registered before the catch-all {placeId} so it wins.
  ADD_METHOD_TO(RestaurantController::photo,
                "/api/v1/restaurants/{placeId}/photo", drogon::Get);
  ADD_METHOD_TO(RestaurantController::details,
                "/api/v1/restaurants/{placeId}", drogon::Get);
  METHOD_LIST_END

  drogon::Task<drogon::HttpResponsePtr> nearby(drogon::HttpRequestPtr req);
  drogon::Task<drogon::HttpResponsePtr> details(drogon::HttpRequestPtr req,
                                                std::string placeId);
  drogon::Task<drogon::HttpResponsePtr> photo(drogon::HttpRequestPtr req,
                                              std::string placeId);
};
