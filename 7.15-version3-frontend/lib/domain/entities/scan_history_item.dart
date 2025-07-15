class ScanHistoryItem {
  final int scanId;
  final String productName;
  final String? brand;
  final DateTime scannedAt;
  
  ScanHistoryItem({
    required this.scanId,
    required this.productName,
    this.brand,
    required this.scannedAt,
  });
  
  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    return ScanHistoryItem(
      scanId: json['scanId'] as int,
      productName: json['productName'] as String,
      brand: json['brand'] as String?,
      scannedAt: DateTime.parse(json['scannedAt'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'scanId': scanId,
      'productName': productName,
      'brand': brand,
      'scannedAt': scannedAt.toIso8601String(),
    };
  }
}