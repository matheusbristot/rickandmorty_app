import 'package:flutter/foundation.dart';

import '../../domain/entities/episode.dart';
import '../../domain/usecases/load_episode_use_case.dart';
import '../../domain/usecases/retry_character_use_case.dart';
import '../input/episode_input_parser.dart';
import '../messages/episode_message_mapper.dart';
import '../state/episode_screen_state.dart';

abstract class EpisodeViewModel extends ChangeNotifier {
  ValueNotifier<String> get episodeInput;

  EpisodeStatus get status;

  Episode? get episode;

  bool get isFromCache;

  bool get isRefreshing;

  String? get errorMessage;

  List<CharacterItemState> get characters;

  Future<void> search();

  Future<void> retryCharacter(Uri url);
}

final class EpisodeViewModelImpl extends EpisodeViewModel {
  EpisodeViewModelImpl(
    this._loadEpisode,
    this._retryCharacter,
    this._inputParser,
    this._messageMapper,
  );

  final LoadEpisodeUseCase _loadEpisode;
  final RetryCharacterUseCase _retryCharacter;
  final EpisodeInputParser _inputParser;
  final EpisodeMessageMapper _messageMapper;
  @override
  final ValueNotifier<String> episodeInput = ValueNotifier<String>('1');

  EpisodeScreenState _state = const EpisodeScreenState();
  int _requestId = 0;

  @override
  EpisodeStatus get status => _state.status;

  @override
  Episode? get episode => _state.episode;

  @override
  bool get isFromCache => _state.isFromCache;

  @override
  bool get isRefreshing => _state.isRefreshing;

  @override
  String? get errorMessage => _state.errorMessage;

  @override
  List<CharacterItemState> get characters => _state.characters;

  @override
  Future<void> search() async {
    final requestId = ++_requestId;
    final id = _inputParser.parse(episodeInput.value);
    if (id == null) {
      _state = _state.invalid(_messageMapper.invalidEpisode());
      notifyListeners();
      return;
    }

    _state = _state.beginLoading();
    notifyListeners();

    try {
      await for (final event in _loadEpisode.execute(id)) {
        if (requestId != _requestId) return;
        _state = _state.reduce(event, _messageMapper.partialCharacterFailure);
        notifyListeners();
      }
    } on Exception catch (error) {
      if (requestId != _requestId) return;
      _state = _state.fail(
        _messageMapper.forEpisodeFailure(error),
        _messageMapper.cachedAfterFailure,
      );
      notifyListeners();
    }
  }

  @override
  Future<void> retryCharacter(Uri url) async {
    if (!_state.canRetry(url)) return;

    final requestId = _requestId;
    _state = _state.retryingCharacter(url);
    notifyListeners();

    try {
      final character = await _retryCharacter.execute(url);
      if (requestId != _requestId) return;
      _state = _state.characterLoaded(
        url,
        character,
        _messageMapper.partialCharacterFailure,
      );
    } on Exception {
      if (requestId != _requestId) return;
      _state = _state.characterFailed(url, _messageMapper.characterFailure);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    episodeInput.dispose();
    super.dispose();
  }
}
