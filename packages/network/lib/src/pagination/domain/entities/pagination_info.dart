/// Metadata returned by an API using the info/results pagination envelope.
final class PaginationInfo {
  const PaginationInfo({
    required this.count,
    required this.pages,
    required this.next,
    required this.prev,
  });

  final int count;
  final int pages;
  final Uri? next;
  final Uri? prev;

  bool get hasNext => next != null;
  bool get hasPrevious => prev != null;
}
