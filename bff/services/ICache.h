#pragma once

#include <optional>
#include <string>

/// Cache abstraction so the service layer never depends on a concrete store.
/// The current implementation is [InMemoryCache]; this interface exists so a
/// persistent cache can be dropped in later without touching PlacesService.
///
/// An earlier version of this comment named Redis specifically, and that name
/// was taken as a decision it was never meant to be. See
/// specs/002-bff-durable-cache/: the durable backend is the PostgreSQL already
/// running on the host, because nothing here needs a second datastore.
///
/// Values are pre-serialized, normalized JSON strings (what the client should
/// receive), so a cache HIT can be returned verbatim with no re-parsing.
class ICache {
  public:
    virtual ~ICache() = default;

    /// Returns the cached value for [key], or nullopt if missing/expired.
    virtual std::optional<std::string> get(const std::string& key) = 0;

    /// Stores [value] under [key] for [ttlSeconds].
    virtual void set(const std::string& key, const std::string& value, int ttlSeconds) = 0;

    /// Clears all entries from the cache.
    virtual void clear() = 0;
};
