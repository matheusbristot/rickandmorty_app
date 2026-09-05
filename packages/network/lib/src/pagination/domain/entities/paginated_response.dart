import 'pagination_info.dart';

final class PaginatedResponse<T> {
  PaginatedResponse({required this.info, required List<T> results})
    : results = List<T>.unmodifiable(results);

  final PaginationInfo info;
  final List<T> results;
}
