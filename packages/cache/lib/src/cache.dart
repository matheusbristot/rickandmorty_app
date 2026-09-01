abstract interface class Cache {
  Future<String?> getString(String key);

  Future<void> setString(String key, String value);
}
