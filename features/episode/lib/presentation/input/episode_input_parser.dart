abstract interface class EpisodeInputParser {
  int? parse(String input);
}

final class EpisodeInputParserImpl implements EpisodeInputParser {
  @override
  int? parse(String input) {
    final id = int.tryParse(input.trim());
    return id == null || id <= 0 ? null : id;
  }
}
