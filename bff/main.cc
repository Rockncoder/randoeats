#include <drogon/drogon.h>
#include <json/json.h>

#include <algorithm>
#include <chrono>
#include <cstdlib>
#include <fstream>
#include <memory>
#include <string>

#include "services/AppContext.h"
#include "services/GooglePlacesClient.h"
#include "services/InMemoryCache.h"
#include "services/MetricsLogger.h"
#include "services/PlacesService.h"

using namespace drogon;

namespace {

int64_t nowNs() {
  return std::chrono::duration_cast<std::chrono::nanoseconds>(
             std::chrono::steady_clock::now().time_since_epoch())
      .count();
}

/// Reflects the request Origin only if it's in the configured allow-list.
void applyCors(const HttpRequestPtr& req, const HttpResponsePtr& resp) {
  const std::string origin = req->getHeader("origin");
  if (origin.empty()) return;
  const auto& allowed = AppContext::instance().allowedOrigins;
  if (std::find(allowed.begin(), allowed.end(), origin) != allowed.end()) {
    resp->addHeader("Access-Control-Allow-Origin", origin);
    resp->addHeader("Vary", "Origin");
  }
}

Json::Value loadConfig(const std::string& path) {
  std::ifstream in(path);
  if (!in) {
    LOG_FATAL << "Cannot open config file: " << path;
    std::exit(1);
  }
  Json::Value cfg;
  Json::CharReaderBuilder builder;
  std::string errs;
  if (!Json::parseFromStream(builder, in, &cfg, &errs)) {
    LOG_FATAL << "Invalid config JSON: " << errs;
    std::exit(1);
  }
  return cfg;
}

}  // namespace

int main(int argc, char* argv[]) {
  const std::string configPath = argc > 1 ? argv[1] : "config.json";
  const Json::Value cfg = loadConfig(configPath);

  const std::string apiKey = cfg.get("places_api_key", "").asString();
  if (apiKey.empty() || apiKey == "YOUR_GOOGLE_PLACES_API_KEY") {
    LOG_FATAL << "places_api_key is not set in " << configPath;
    return 1;
  }
  const int port = cfg.get("port", 8848).asInt();
  const int threads = cfg.get("threads", 1).asInt();
  const auto maxEntries =
      static_cast<std::size_t>(cfg.get("cache_max_entries", 2000).asUInt());
  const int nearbyTtl = cfg.get("nearby_ttl_seconds", 3600).asInt();
  const int detailsTtl = cfg.get("details_ttl_seconds", 21600).asInt();
  const std::string metricsPath =
      cfg.get("metrics_log_path", "metrics.jsonl").asString();

  auto& ctx = AppContext::instance();
  ctx.metrics = std::make_shared<MetricsLogger>(metricsPath);
  ctx.google = std::make_shared<GooglePlacesClient>(apiKey);
  auto cache = std::make_shared<InMemoryCache>(maxEntries);
  ctx.places = std::make_shared<PlacesService>(ctx.google, cache, nearbyTtl,
                                               detailsTtl);
  for (const auto& origin : cfg["allowed_origins"]) {
    ctx.allowedOrigins.push_back(origin.asString());
  }

  // Health check (no cache, no upstream).
  app().registerHandler(
      "/api/v1/health",
      [](const HttpRequestPtr&,
         std::function<void(const HttpResponsePtr&)>&& callback) {
        Json::Value body;
        body["status"] = "ok";
        body["version"] = "1.0.0";
        callback(HttpResponse::newHttpJsonResponse(body));
      },
      {Get});

  // CORS preflight: short-circuit OPTIONS before routing, otherwise Drogon
  // rejects it as a disallowed method on the GET routes.
  app().registerPreRoutingAdvice([](const HttpRequestPtr& req,
                                    AdviceCallback&& stop,
                                    AdviceChainCallback&& pass) {
    if (req->method() == Options) {
      auto resp = HttpResponse::newHttpResponse();
      resp->setStatusCode(k204NoContent);
      applyCors(req, resp);
      resp->addHeader("Access-Control-Allow-Methods", "GET, OPTIONS");
      resp->addHeader("Access-Control-Allow-Headers", "Content-Type");
      resp->addHeader("Access-Control-Max-Age", "86400");
      stop(resp);
    } else {
      pass();
    }
  });

  // Metrics: stamp a start time before routing...
  app().registerPreRoutingAdvice(
      [](const HttpRequestPtr& req) { req->attributes()->insert("m_start", nowNs()); });

  // ...and, after handling, apply CORS and write the JSONL metrics line.
  app().registerPostHandlingAdvice(
      [](const HttpRequestPtr& req, const HttpResponsePtr& resp) {
        applyCors(req, resp);
        const auto attrs = req->attributes();
        const int64_t start = attrs->get<int64_t>("m_start");
        const long total = start ? (nowNs() - start) / 1000000 : 0;
        std::string cache = attrs->get<std::string>("m_cache");
        if (cache.empty()) cache = "NONE";
        const long upstream = static_cast<long>(attrs->get<int64_t>("m_upstream"));
        const std::string endpoint = attrs->get<std::string>("m_endpoint");
        AppContext::instance().metrics->log(
            req->methodString(), req->path(),
            static_cast<int>(resp->getStatusCode()), total, upstream, cache,
            endpoint);
      });

  LOG_INFO << "RandoEats BFF listening on :" << port << " (" << threads
           << " thread(s))";
  app().addListener("0.0.0.0", port).setThreadNum(threads).run();
  return 0;
}
