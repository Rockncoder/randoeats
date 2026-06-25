#include "MetricsLogger.h"

#include <json/json.h>

#include <chrono>
#include <ctime>
#include <iomanip>
#include <sstream>

namespace {

/// Current UTC time as ISO-8601 with millisecond precision, e.g.
/// "2026-06-25T10:30:00.123Z".
std::string isoNow() {
  using namespace std::chrono;
  const auto now = system_clock::now();
  const auto ms = duration_cast<milliseconds>(now.time_since_epoch()) % 1000;
  const std::time_t t = system_clock::to_time_t(now);
  std::tm tm{};
  gmtime_r(&t, &tm);
  std::ostringstream os;
  os << std::put_time(&tm, "%Y-%m-%dT%H:%M:%S") << '.' << std::setfill('0')
     << std::setw(3) << ms.count() << 'Z';
  return os.str();
}

}  // namespace

MetricsLogger::MetricsLogger(const std::string& path)
    : out_(path, std::ios::app), enabled_(out_.is_open()) {}

void MetricsLogger::log(const std::string& method, const std::string& path,
                        int status, long totalMs, long upstreamMs,
                        const std::string& cache,
                        const std::string& upstreamEndpoint) {
  if (!enabled_) return;

  Json::Value rec;
  rec["ts"] = isoNow();
  rec["method"] = method;
  rec["path"] = path;
  rec["status"] = status;
  rec["total_ms"] = static_cast<Json::Int64>(totalMs);
  rec["upstream_ms"] = static_cast<Json::Int64>(upstreamMs);
  rec["cache"] = cache;
  rec["upstream_endpoint"] = upstreamEndpoint;

  Json::StreamWriterBuilder builder;
  builder["indentation"] = "";  // compact, single line
  const std::string line = Json::writeString(builder, rec);

  std::lock_guard<std::mutex> lock(mutex_);
  out_ << line << '\n';
  out_.flush();
}
