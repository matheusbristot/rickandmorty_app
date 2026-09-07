import '../../domain/entities/episode_failure.dart';

abstract interface class EpisodeMessageMapper {
  String invalidEpisode();

  String forEpisodeFailure(Exception error);

  String get cachedAfterFailure;

  String get partialCharacterFailure;

  String get characterFailure;
}

final class EpisodeMessageMapperImpl implements EpisodeMessageMapper {
  @override
  String invalidEpisode() => 'Digite um número de episódio válido.';

  @override
  String forEpisodeFailure(Exception error) {
    if (error is EpisodeFailure) {
      return switch (error.kind) {
        EpisodeFailureKind.notFound => 'Episódio não encontrado.',
        EpisodeFailureKind.tooManyRequests =>
          'Muitas solicitações. Tente novamente em instantes.',
        EpisodeFailureKind.invalidData => 'Os dados do episódio são inválidos.',
        EpisodeFailureKind.network => 'Não foi possível carregar o episódio. Verifique sua conexão e tente novamente.',
      };
    }
    return 'Não foi possível carregar o episódio.';
  }

  @override
  String get cachedAfterFailure =>
      'Sem conexão. Exibindo a última versão salva.';

  @override
  String get partialCharacterFailure =>
      'Alguns personagens não puderam ser carregados.';

  @override
  String get characterFailure => 'Não foi possível carregar este personagem.';
}
