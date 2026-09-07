import 'package:character/character.dart';

import '../repositories/episode_repository.dart';

abstract interface class RetryCharacterUseCase {
  Future<Character> execute(Uri url);
}

final class RetryCharacterUseCaseImpl implements RetryCharacterUseCase {
  RetryCharacterUseCaseImpl(this._repository);

  final EpisodeRepository _repository;

  @override
  Future<Character> execute(Uri url) => _repository.fetchCharacter(url);
}
