class PagedResponse<T> {
  final List<T> data;
  final PaginationInfo pagination;

  const PagedResponse({
    required this.data,
    required this.pagination,
  });

  factory PagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PagedResponse(
      data: (json['data'] as List<dynamic>)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      pagination: PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return {
      'data': data.map((item) => toJsonT(item)).toList(),
      'pagination': pagination.toJson(),
    };
  }

  bool get hasMore => pagination.currentPage < pagination.totalPages;
  bool get isEmpty => data.isEmpty;
  bool get isNotEmpty => data.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PagedResponse<T> &&
        _listEquals(other.data, data) &&
        other.pagination == pagination;
  }

  bool _listEquals<E>(List<E>? a, List<E>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    if (identical(a, b)) return true;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode => data.hashCode ^ pagination.hashCode;

  @override
  String toString() {
    return 'PagedResponse(data: $data, pagination: $pagination)';
  }
}

class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int totalItems;

  const PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['currentPage'] as int,
      totalPages: json['totalPages'] as int,
      totalItems: json['totalItems'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentPage': currentPage,
      'totalPages': totalPages,
      'totalItems': totalItems,
    };
  }

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaginationInfo &&
        other.currentPage == currentPage &&
        other.totalPages == totalPages &&
        other.totalItems == totalItems;
  }

  @override
  int get hashCode {
    return currentPage.hashCode ^ totalPages.hashCode ^ totalItems.hashCode;
  }

  @override
  String toString() {
    return 'PaginationInfo(currentPage: $currentPage, totalPages: $totalPages, totalItems: $totalItems)';
  }
}