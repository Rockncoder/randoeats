#pragma once

#include <fstream>
#include <mutex>
#include <string>

/// Appends one JSON object per line (JSON Lines) describing each request, for a
/// Phase-0 latency/cache baseline and ongoing observability.
///
/// Holds the log file open as a persistent ofstream, so log rotation must use
/// `copytruncate` (see /etc/logrotate.d/randoeats in the README). Thread-safe.
class MetricsLogger {
 public:
  /// Opens [path] for appending. If it can't be opened, logging is disabled
  /// (the BFF still serves traffic) rather than crashing.
  explicit MetricsLogger(const std::string& path);

  void log(const std::string& method, const std::string& path, int status,
           long totalMs, long upstreamMs, const std::string& cache,
           const std::string& upstreamEndpoint);

 private:
  std::ofstream out_;
  std::mutex mutex_;
  bool enabled_;
};
