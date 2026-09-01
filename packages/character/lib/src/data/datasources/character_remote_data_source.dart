import '../models/character_model.dart';

abstract interface class CharacterRemoteDataSource {
  Future<CharacterModel> getCharacterByUrl(Uri url);

  Future<Map<Uri, CharacterModel>> getCharactersByUrls(List<Uri> urls);
}
