class HistoryResponse {
  final List<HistoryItem> items;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  HistoryResponse({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
  });

  factory HistoryResponse.fromJson(Map<String, dynamic> json) {
    return HistoryResponse(
      items: (json['items'] as List)
          .map((item) => HistoryItem.fromJson(item))
          .toList(),
      totalCount: json['totalCount'] ?? 0,
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      hasMore: json['hasMore'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'totalCount': totalCount,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'hasMore': hasMore,
    };
  }
}

class HistoryItem {
  final String id;
  final String scanType;
  final DateTime createdAt;
  final String productName;
  final String? productImage;
  final String? barcode;
  final int recommendationCount;
  final Map<String, dynamic>? summary;

  HistoryItem({
    required this.id,
    required this.scanType,
    required this.createdAt,
    required this.productName,
    this.productImage,
    this.barcode,
    required this.recommendationCount,
    this.summary,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] ?? '',
      scanType: json['scanType'] ?? 'barcode',
      createdAt: DateTime.parse(json['createdAt']),
      productName: json['productName'] ?? '',
      productImage: json['productImage'],
      barcode: json['barcode'],
      recommendationCount: json['recommendationCount'] ?? 0,
      summary: json['summary'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scanType': scanType,
      'createdAt': createdAt.toIso8601String(),
      'productName': productName,
      'productImage': productImage,
      'barcode': barcode,
      'recommendationCount': recommendationCount,
      'summary': summary,
    };
  }
}