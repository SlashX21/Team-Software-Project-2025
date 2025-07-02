import 'history_response.dart';

class HistoryDetail extends HistoryItem {
  final Map<String, dynamic> fullAnalysis;
  final List<Map<String, dynamic>> recommendations;
  final Map<String, dynamic> nutritionData;

  HistoryDetail({
    required String id,
    required String scanType,
    required DateTime createdAt,
    required String productName,
    String? productImage,
    String? barcode,
    required int recommendationCount,
    Map<String, dynamic>? summary,
    required this.fullAnalysis,
    required this.recommendations,
    required this.nutritionData,
  }) : super(
          id: id,
          scanType: scanType,
          createdAt: createdAt,
          productName: productName,
          productImage: productImage,
          barcode: barcode,
          recommendationCount: recommendationCount,
          summary: summary,
        );

  factory HistoryDetail.fromJson(Map<String, dynamic> json) {
    return HistoryDetail(
      id: json['id'] ?? '',
      scanType: json['scanType'] ?? 'barcode',
      createdAt: DateTime.parse(json['createdAt']),
      productName: json['productName'] ?? '',
      productImage: json['productImage'],
      barcode: json['barcode'],
      recommendationCount: json['recommendationCount'] ?? 0,
      summary: json['summary'],
      fullAnalysis: json['fullAnalysis'] ?? {},
      recommendations: List<Map<String, dynamic>>.from(json['recommendations'] ?? []),
      nutritionData: json['nutritionData'] ?? {},
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'fullAnalysis': fullAnalysis,
      'recommendations': recommendations,
      'nutritionData': nutritionData,
    };
  }
}