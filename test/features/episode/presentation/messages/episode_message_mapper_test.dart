import 'package:flutter_test/flutter_test.dart';
import 'package:rickandmorty_app/features/episode/domain/entities/episode_failure.dart';
import 'package:rickandmorty_app/features/episode/presentation/messages/episode_message_mapper.dart';

void main() {
  test('converte falhas de domínio em mensagens da apresentação', () {
    // Arrange
    final mapper = EpisodeMessageMapperImpl();
    final failures = {
      const EpisodeFailure(EpisodeFailureKind.notFound):
          'Episódio não encontrado.',
      const EpisodeFailure(EpisodeFailureKind.tooManyRequests):
          'Muitas solicitações. Tente novamente em instantes.',
      const EpisodeFailure(EpisodeFailureKind.invalidData):
          'Os dados do episódio são inválidos.',
    };

    // Act
    final messages = {
      for (final failure in failures.keys)
        failure: mapper.forEpisodeFailure(failure),
    };

    // Assert
    expect(messages, failures);
  });

  test('usa mensagem genérica para falhas desconhecidas', () {
    // Arrange
    final mapper = EpisodeMessageMapperImpl();
    final error = Exception('technical detail');

    // Act
    final message = mapper.forEpisodeFailure(error);

    // Assert
    expect(message, 'Não foi possível carregar o episódio.');
  });
}
