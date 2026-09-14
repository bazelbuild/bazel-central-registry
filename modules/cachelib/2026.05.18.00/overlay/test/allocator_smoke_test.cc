#include <cstring>
#include <iostream>
#include <string>
#include <string_view>
#include <utility>

#include "cachelib/allocator/CacheAllocator.h"

int main() {
  using Cache = facebook::cachelib::LruAllocator;

  Cache::Config config;
  config.setCacheName("bcr-consumer-smoke");
  config.setCacheSize(64 * 1024 * 1024);

  Cache cache(config);
  const auto pool_id = cache.addPool(
      "default", cache.getCacheMemoryStats().ramCacheSize);

  const std::string key = "cachelib-bcr-smoke-key";
  const std::string value = "cachelib-bcr-smoke-value";
  auto item = cache.allocate(pool_id, key, value.size());
  if (!item) {
    std::cerr << "failed to allocate cache item\n";
    return 1;
  }

  std::memcpy(item->getMemory(), value.data(), value.size());
  cache.insertOrReplace(std::move(item));

  const auto found = cache.find(key);
  if (!found) {
    std::cerr << "failed to find inserted cache item\n";
    return 1;
  }

  const std::string_view actual{
      static_cast<const char*>(found->getMemory()), found->getSize()};
  if (actual != value) {
    std::cerr << "cache item contents do not match\n";
    return 1;
  }

  return 0;
}
