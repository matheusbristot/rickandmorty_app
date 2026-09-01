extension JsonMapExtensions on Map<String, dynamic> {
  int asInt(String key) {
    final value = this[key];
    if (value is int) return value;
    return int.parse(value.toString());
  }

  String asString(String key) => this[key]?.toString() ?? '';
}
