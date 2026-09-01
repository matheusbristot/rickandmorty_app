import 'package:shared_preferences/shared_preferences.dart';

import 'cache.dart';

final class SharedPreferencesCacheImpl implements Cache {
  SharedPreferencesCacheImpl({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> getString(String key) => _preferences.getString(key);

  @override
  Future<void> setString(String key, String value) {
    return _preferences.setString(key, value);
  }
}
