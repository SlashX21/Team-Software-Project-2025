class HistoryItem {
  final String productId;
  final String productName;
  final DateTime scanDate;
  final String thumbnailUrl;
  final List<String> detectedAllergens;
  final bool hasAllergenAlert;

  HistoryItem({
    required this.productId,
    required this.productName,
    required this.scanDate,
    required this.thumbnailUrl,
    this.detectedAllergens = const [],
    this.hasAllergenAlert = false,
  });

  // Helper method to format scan date for display
  String get formattedScanDate {
    final now = DateTime.now();
    final difference = now.difference(scanDate);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${scanDate.day}/${scanDate.month}/${scanDate.year}';
    }
  }

  // Factory constructor for creating from JSON
  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      scanDate: DateTime.parse(json['scanDate'] as String),
      thumbnailUrl: json['thumbnailUrl'] as String,
      detectedAllergens: List<String>.from(json['detectedAllergens'] ?? []),
      hasAllergenAlert: json['hasAllergenAlert'] as bool? ?? false,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'scanDate': scanDate.toIso8601String(),
      'thumbnailUrl': thumbnailUrl,
      'detectedAllergens': detectedAllergens,
      'hasAllergenAlert': hasAllergenAlert,
    };
  }
}