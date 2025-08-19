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
    print('🔍 ReceiptHistoryItem.fromJson received: $json');
    print('🔍 Backend displayTitle: "${json['displayTitle']}"');
    
    return ReceiptHistoryItem(
      receiptId: json['receiptId'] as int? ?? 0,
      scanTime: DateTime.parse(json['scanTime'] as String? ?? DateTime.now().toIso8601String()),
      displayTitle: json['displayTitle']?.toString() ?? 'Receipt',
      itemCount: json['itemCount'] as int? ?? 0,
      hasRecommendations: json['hasRecommendations'] as bool? ?? false,
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
    // Split the display title by comma to get individual items
    final items = displayTitle.split(', ').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
    
    if (items.length <= 2) {
      return displayTitle;
    }
    
    // Take first two items and add "..." to indicate more items
    final firstTwoItems = items.take(2).join(', ');
    final remainingCount = items.length - 2;
    return '$firstTwoItems... (+$remainingCount more)';
  }
  
  // Add a method for better formatting
  String get formattedTitle {
    final items = displayTitle.split(', ').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
    
    if (items.isEmpty) {
      return 'Receipt';
    }
    
    if (items.length <= 2) {
      return items.join(', ');
    }
    
    // Show first item with count for better space usage
    final firstItem = items.first;
    final remainingCount = items.length - 1;
    return '$firstItem (+$remainingCount)';
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