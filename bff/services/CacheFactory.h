#pragma once

#include "ICache.h"

#include <cstddef>
#include <json/json.h>
#include <memory>

/// Builds the cache backend named in config.
///
/// Exists so backend selection lives in one testable place rather than
/// branching inside main(), and so the fallback rule has a single home: if the
/// configured durable backend cannot be reached, the BFF still starts and still
/// serves, using the in-memory cache (spec FR-005). Startup must never be
/// blocked by a cache being down.
/// Returns the configured cache, or the in-memory cache if the durable backend
/// is unavailable. Throws only for an unrecognized `cache_backend` value, which
/// is a configuration mistake and must fail loudly rather than silently
/// defaulting (spec US3 scenario 3).
std::shared_ptr<ICache> createCache(const Json::Value& config);
