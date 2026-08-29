#pragma once

#include "ICache.h"

#include <chrono>
#include <cstddef>
#include <functional>
#include <list>
#include <mutex>
#include <string>
#include <unordered_map>

/// Thread-safe, TTL + LRU bounded in-memory cache.
///
/// Bounded at [maxEntries] (config `cache_max_entries`) with least-recently-used
/// eviction so it can't exhaust memory on the 1 GB Nanode. Drogon serves
/// requests on multiple threads, so every operation is guarded by a mutex.
class InMemoryCache : public ICache {
  public:
    /// Source of "now". Injectable purely so TTL expiry is testable without
    /// sleeping for the real TTL (nearby is 3600s). Production always uses the
    /// default steady clock; no production behavior depends on this.
    using Clock = std::function<std::chrono::steady_clock::time_point()>;

    explicit InMemoryCache(std::size_t maxEntries, Clock clock = defaultClock);

    /// The production clock: `std::chrono::steady_clock::now()`.
    static std::chrono::steady_clock::time_point defaultClock();

    std::optional<std::string> get(const std::string& key) override;
    void set(const std::string& key, const std::string& value, int ttlSeconds) override;
    void clear() override;

  private:
    struct Entry {
        std::string value;
        std::chrono::steady_clock::time_point expiry;
        std::list<std::string>::iterator lruIt;  // position in lru_ (front = newest)
    };

    void touch(Entry& entry, const std::string& key);  // move key to LRU front
    void evictIfNeeded();                              // assumes mutex held

    std::size_t maxEntries_;
    Clock clock_;
    std::unordered_map<std::string, Entry> map_;
    std::list<std::string> lru_;  // front = most recently used
    std::mutex mutex_;
};
