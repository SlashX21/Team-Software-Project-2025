class ReceiptHistoryItem {
  final int receiptId;
  final DateTime scanTime;
  final String displayTitle;
  final int itemCount;
  final bool hasRecommendations;

  const ReceiptHistoryItem({
    required this.receiptId,
    required this.scanTime,
    required this.displayTitle,
    required this.itemCount,
    required this.hasRecommendations,
  });

  factory ReceiptHistoryItem.fromJson(Map<String, dynamic> json) {
    return ReceiptHistoryItem(
      receiptId: json['receiptId'] as int,
      scanTime: DateTime.parse(json['scanTime'] as String),
      displayTitle: json['displayTitle'] as String,
      itemCount: json['itemCount'] as int,
      hasRecommendations: json['hasRecommendations'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receiptId': receiptId,
      'scanTime': scanTime.toIso8601String(),
      'displayTitle': displayTitle,
      'itemCount': itemCount,
      'hasRecommendations': hasRecommendations,
    };
  }

  String get truncatedTitle {
    if (displayTitle.length <= 100) {
      return displayTitle;
    }
    return '${displayTitle.substring(0, 100)}...';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReceiptHistoryItem &&
        other.receiptId == receiptId &&
        other.scanTime == scanTime &&
        other.displayTitle == displayTitle &&
        other.itemCount == itemCount &&
        other.hasRecommendations == hasRecommendations;
  }

  @override
  int get hashCode {
    return receiptId.hashCode ^
        scanTime.hashCode ^
        displayTitle.hashCode ^
        itemCount.hashCode ^
        hasRecommendations.hashCode;
  }

  @override
  String toString() {
    return 'ReceiptHistoryItem(receiptId: $receiptId, scanTime: $scanTime, displayTitle: $displayTitle, itemCount: $itemCount, hasRecommendations: $hasRecommendations)';
  }
}