#pragma once

#include <memory>
#include <string>
#include <vector>

class PlacesService;
class GooglePlacesClient;
class MetricsLogger;

/// Process-wide service container. Drogon constructs controllers as singletons
/// with no constructor args, so dependencies are wired here in main() and read
/// by controllers/advices. (shared_ptr supports the forward-declared types.)
struct AppContext {
  std::shared_ptr<PlacesService> places;
  std::shared_ptr<GooglePlacesClient> google;
  std::shared_ptr<MetricsLogger> metrics;
  std::vector<std::string> allowedOrigins;

  static AppContext& instance() {
    static AppContext ctx;
    return ctx;
  }
};
