class HistoryStatistics {
  final int totalScans;
  final int barcodeScans;
  final int receiptScans;
  final Map<String, int> scansByDate;
  final List<String> topCategories;

  HistoryStatistics({
    required this.totalScans,
    required this.barcodeScans,
    required this.receiptScans,
    required this.scansByDate,
    required this.topCategories,
  });

  factory HistoryStatistics.fromJson(Map<String, dynamic> json) {
    return HistoryStatistics(
      totalScans: json['totalScans'] ?? 0,
      barcodeScans: json['barcodeScans'] ?? 0,
      receiptScans: json['receiptScans'] ?? 0,
      scansByDate: Map<String, int>.from(json['scansByDate'] ?? {}),
      topCategories: List<String>.from(json['topCategories'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalScans': totalScans,
      'barcodeScans': barcodeScans,
      'receiptScans': receiptScans,
      'scansByDate': scansByDate,
      'topCategories': topCategories,
    };
  }
}