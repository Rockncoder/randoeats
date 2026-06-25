#pragma once

#include <optional>
#include <string>

/// Cache abstraction so the service layer never depends on a concrete store.
/// The current implementation is [InMemoryCache]; this interface exists so a
/// Redis-backed cache can be dropped in later without touching PlacesService.
///
/// Values are pre-serialized, normalized JSON strings (what the client should
/// receive), so a cache HIT can be returned verbatim with no re-parsing.
class ICache {
 public:
  virtual ~ICache() = default;

  /// Returns the cached value for [key], or nullopt if missing/expired.
  virtual std::optional<std::string> get(const std::string& key) = 0;

  /// Stores [value] under [key] for [ttlSeconds].
  virtual void set(const std::string& key, const std::string& value,
                   int ttlSeconds) = 0;
};
