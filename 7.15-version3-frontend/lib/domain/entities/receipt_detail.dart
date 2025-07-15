import 'purchased_item.dart';
import 'recommendation_group.dart';

class ReceiptDetail {
  final int receiptId;
  final DateTime scanTime;
  final String? recommendationId;
  final List<PurchasedItem> purchasedItems;
  final String llmSummary;
  final List<RecommendationGroup> recommendationsList;
  final bool hasLLMAnalysis;
  final bool hasRecommendations;

  const ReceiptDetail({
    required this.receiptId,
    required this.scanTime,
    this.recommendationId,
    required this.purchasedItems,
    required this.llmSummary,
    required this.recommendationsList,
    required this.hasLLMAnalysis,
    required this.hasRecommendations,
  });

  factory ReceiptDetail.fromJson(Map<String, dynamic> json) {
    return ReceiptDetail(
      receiptId: json['receiptId'] as int,
      scanTime: DateTime.parse(json['scanTime'] as String),
      recommendationId: json['recommendationId'] as String?,
      purchasedItems: (json['purchasedItems'] as List<dynamic>)
          .map((item) => PurchasedItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      llmSummary: json['llmSummary'] as String,
      recommendationsList: (json['recommendationsList'] as List<dynamic>?)
          ?.map((item) => RecommendationGroup.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      hasLLMAnalysis: json['hasLLMAnalysis'] as bool,
      hasRecommendations: json['hasRecommendations'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receiptId': receiptId,
      'scanTime': scanTime.toIso8601String(),
      'recommendationId': recommendationId,
      'purchasedItems': purchasedItems.map((item) => item.toJson()).toList(),
      'llmSummary': llmSummary,
      'recommendationsList': recommendationsList.map((item) => item.toJson()).toList(),
      'hasLLMAnalysis': hasLLMAnalysis,
      'hasRecommendations': hasRecommendations,
    };
  }

  int get totalItemCount => purchasedItems.fold(0, (sum, item) => sum + item.quantity);

  String get formattedScanTime {
    return '${scanTime.day}/${scanTime.month}/${scanTime.year} ${scanTime.hour.toString().padLeft(2, '0')}:${scanTime.minute.toString().padLeft(2, '0')}';
  }

  bool get isAnalysisAvailable => hasLLMAnalysis && llmSummary.trim().isNotEmpty;

  bool get areRecommendationsAvailable => hasRecommendations && recommendationsList.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReceiptDetail &&
        other.receiptId == receiptId &&
        other.scanTime == scanTime &&
        other.recommendationId == recommendationId &&
        _listEquals(other.purchasedItems, purchasedItems) &&
        other.llmSummary == llmSummary &&
        _listEquals(other.recommendationsList, recommendationsList) &&
        other.hasLLMAnalysis == hasLLMAnalysis &&
        other.hasRecommendations == hasRecommendations;
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    if (identical(a, b)) return true;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return receiptId.hashCode ^
        scanTime.hashCode ^
        recommendationId.hashCode ^
        purchasedItems.hashCode ^
        llmSummary.hashCode ^
        recommendationsList.hashCode ^
        hasLLMAnalysis.hashCode ^
        hasRecommendations.hashCode;
  }

  @override
  String toString() {
    return 'ReceiptDetail(receiptId: $receiptId, scanTime: $scanTime, recommendationId: $recommendationId, purchasedItems: $purchasedItems, llmSummary: $llmSummary, recommendationsList: $recommendationsList, hasLLMAnalysis: $hasLLMAnalysis, hasRecommendations: $hasRecommendations)';
  }
}