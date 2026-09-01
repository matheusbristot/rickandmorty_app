abstract interface class NetworkClient {
  Future<dynamic> getJson(String path);

  Future<dynamic> getJsonUri(Uri uri);

  void close();
}
