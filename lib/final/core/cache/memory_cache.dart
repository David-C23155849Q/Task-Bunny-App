class MemoryCache {
  static final Map<String, dynamic> _cache = {};

  static T? get<T>(String key) {
    if (!_cache.containsKey(key)) return null;

    return _cache[key] as T;
  }

  static void save(
      String key,
      dynamic value,
      ) {
    _cache[key] = value;
  }

  static bool contains(
      String key,
      ) {
    return _cache.containsKey(key);
  }

  static void clear() {
    _cache.clear();
  }
}