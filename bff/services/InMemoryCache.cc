#include "InMemoryCache.h"

InMemoryCache::InMemoryCache(std::size_t maxEntries, Clock clock)
    : maxEntries_(maxEntries == 0 ? 1 : maxEntries), clock_(std::move(clock)) {}

std::chrono::steady_clock::time_point InMemoryCache::defaultClock() {
    return std::chrono::steady_clock::now();
}

std::optional<std::string> InMemoryCache::get(const std::string& key) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = map_.find(key);
    if (it == map_.end())
        return std::nullopt;

    if (clock_() >= it->second.expiry) {
        lru_.erase(it->second.lruIt);
        map_.erase(it);
        return std::nullopt;
    }

    touch(it->second, key);
    return it->second.value;
}

void InMemoryCache::set(const std::string& key, const std::string& value, int ttlSeconds) {
    std::lock_guard<std::mutex> lock(mutex_);
    const auto expiry = clock_() + std::chrono::seconds(ttlSeconds);

    auto it = map_.find(key);
    if (it != map_.end()) {
        it->second.value = value;
        it->second.expiry = expiry;
        touch(it->second, key);
        return;
    }

    lru_.push_front(key);
    map_.emplace(key, Entry{value, expiry, lru_.begin()});
    evictIfNeeded();
}

void InMemoryCache::clear() {
    std::lock_guard<std::mutex> lock(mutex_);
    map_.clear();
    lru_.clear();
}

void InMemoryCache::touch(Entry& entry, const std::string& key) {
    // Move this key to the front (most-recently-used) of the LRU list.
    lru_.erase(entry.lruIt);
    lru_.push_front(key);
    entry.lruIt = lru_.begin();
}

void InMemoryCache::evictIfNeeded() {
    while (map_.size() > maxEntries_ && !lru_.empty()) {
        const std::string& oldest = lru_.back();
        map_.erase(oldest);
        lru_.pop_back();
    }
}
