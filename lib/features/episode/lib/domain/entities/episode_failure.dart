enum EpisodeFailureKind { notFound, tooManyRequests, network, invalidData }

final class EpisodeFailure implements Exception {
  const EpisodeFailure(this.kind);

  final EpisodeFailureKind kind;
}
