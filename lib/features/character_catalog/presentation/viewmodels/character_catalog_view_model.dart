import 'package:character_catalog_feature/character_catalog.dart';
import 'package:flutter/foundation.dart';

abstract class CharacterCatalogViewModel extends ChangeNotifier {
  CharacterCatalogState get state;
  CharacterFilter get filter;
  Future<void> search(CharacterFilter filter);
  Future<void> refresh();
  Future<void> loadMore();
  Future<void> retry();
}

final class CharacterCatalogViewModelImpl extends CharacterCatalogViewModel {
  CharacterCatalogViewModelImpl(this._load);

  final LoadCharacterCatalog _load;
  CharacterCatalogState _state = CharacterCatalogState();
  CharacterFilter _filter = const CharacterFilter();
  int _generation = 0;
  bool _disposed = false;
  bool _hasRequested = false;
  CharacterCatalogState _retryBase = CharacterCatalogState();
  Uri? _retryNext;

  @override
  CharacterCatalogState get state => _state;
  @override
  CharacterFilter get filter => _filter;

  @override
  Future<void> search(CharacterFilter filter) {
    if (_hasRequested && filter == _filter) return Future<void>.value();
    _hasRequested = true;
    _filter = filter;
    return _request(CharacterCatalogState(), null);
  }

  @override
  Future<void> refresh() {
    _hasRequested = true;
    return _request(CharacterCatalogState(), null);
  }

  @override
  Future<void> retry() async {
    if (_state.loading) return;
    await _request(_retryBase, _retryNext);
  }

  @override
  Future<void> loadMore() async {
    if (_state.loading || _state.next == null) return;
    await _request(_state, _state.next);
  }

  Future<void> _request(CharacterCatalogState base, Uri? next) async {
    if (_disposed) return;
    _retryBase = base;
    _retryNext = next;
    final generation = ++_generation;
    _state = base.begin();
    notifyListeners();
    try {
      await for (final snapshot in _load.execute(_filter, next: next)) {
        if (_disposed || generation != _generation) return;
        _state = base.accept(snapshot);
        notifyListeners();
      }
      if (_disposed || generation != _generation) return;
      _state = _state.finish();
    } on Exception catch (error) {
      if (_disposed || generation != _generation) return;
      _state = _state.finish(error);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
