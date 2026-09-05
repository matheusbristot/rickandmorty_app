Map<String, dynamic> paginatedJson({
  int count = 826,
  int pages = 42,
  String? next,
  String? prev,
  List<Map<String, dynamic>>? results,
}) => {
  'info': {'count': count, 'pages': pages, 'next': next, 'prev': prev},
  'results':
      results ??
      [
        {'id': 1, 'name': 'Rick Sanchez'},
      ],
};
