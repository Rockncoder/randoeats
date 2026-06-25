#pragma once

#include <chrono>
#include <cstddef>
#include <list>
#include <mutex>
#include <string>
#include <unordered_map>

#include "ICache.h"

/// Thread-safe, TTL + LRU bounded in-memory cache.
///
/// Bounded at [maxEntries] (config `cache_max_entries`) with least-recently-used
/// eviction so it can't exhaust memory on the 1 GB Nanode. Drogon serves
/// requests on multiple threads, so every operation is guarded by a mutex.
class InMemoryCache : public ICache {
 public:
  explicit InMemoryCache(std::size_t maxEntries);

  std::optional<std::string> get(const std::string& key) override;
  void set(const std::string& key, const std::string& value,
           int ttlSeconds) override;

 private:
  struct Entry {
    std::string value;
    std::chrono::steady_clock::time_point expiry;
    std::list<std::string>::iterator lruIt;  // position in lru_ (front = newest)
  };

  void touch(Entry& entry, const std::string& key);  // move key to LRU front
  void evictIfNeeded();                               // assumes mutex held

  std::size_t maxEntries_;
  std::unordered_map<std::string, Entry> map_;
  std::list<std::string> lru_;  // front = most recently used
  std::mutex mutex_;
};
