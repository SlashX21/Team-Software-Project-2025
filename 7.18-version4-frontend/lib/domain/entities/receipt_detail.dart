import 'dart:convert';
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
      receiptId: json['receiptId'] as int? ?? 0,
      scanTime: DateTime.parse(json['scanTime'] as String? ?? DateTime.now().toIso8601String()),
      recommendationId: json['recommendationId'] as String?,
      purchasedItems: (json['purchasedItems'] as List<dynamic>?)
          ?.map((item) => PurchasedItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      llmSummary: _parseLlmSummary(json['llmSummary']),
      recommendationsList: (json['recommendationsList'] as List<dynamic>?)
          ?.map((item) => RecommendationGroup.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      hasLLMAnalysis: json['hasLLMAnalysis'] as bool? ?? false,
      hasRecommendations: json['hasRecommendations'] as bool? ?? false,
    );
  }
  
  static String _parseLlmSummary(dynamic llmSummaryRaw) {
    print('🔍 Parsing llmSummary: $llmSummaryRaw (type: ${llmSummaryRaw.runtimeType})');
    
    if (llmSummaryRaw == null) {
      return '';
    }
    
    if (llmSummaryRaw is String) {
      final summary = llmSummaryRaw;
      
      // Check if it's a malformed JSON string like the one you showed
      if (summary.contains('"summary"') && summary.contains('"healthScore"')) {
        print('🔍 Detected malformed JSON in llmSummary, parsing...');
        
        // Extract the summary field from the malformed JSON
        final summaryMatch = RegExp(r'"summary":\s*"([^"]*)"').firstMatch(summary);
        if (summaryMatch != null) {
          final extractedSummary = summaryMatch.group(1) ?? '';
          print('🔍 Extracted summary: $extractedSummary');
          
          // Extract additional useful information
          List<String> analysisComponents = [extractedSummary];
          
          // Extract health score
          final healthScoreMatch = RegExp(r'"healthScore":\s*(\d+)').firstMatch(summary);
          if (healthScoreMatch != null) {
            analysisComponents.add('Health Score: ${healthScoreMatch.group(1)}/100');
          }
          
          // Extract total items
          final totalItemsMatch = RegExp(r'"totalItems":\s*(\d+)').firstMatch(summary);
          if (totalItemsMatch != null) {
            analysisComponents.add('Total Items: ${totalItemsMatch.group(1)}');
          }
          
          // Extract healthy items
          final healthyItemsMatch = RegExp(r'"healthyItems":\s*\[([\s\S]*?)\]').firstMatch(summary);
          if (healthyItemsMatch != null) {
            final healthyItemsStr = healthyItemsMatch.group(1) ?? '';
            final healthyItems = RegExp(r'"([^"]*)"').allMatches(healthyItemsStr)
                .map((m) => m.group(1) ?? '').where((item) => item.isNotEmpty).toList();
            if (healthyItems.isNotEmpty) {
              analysisComponents.add('Healthy Items:\n${healthyItems.map((item) => '• $item').join('\n')}');
            }
          }
          
          // Extract concern items
          final concernItemsMatch = RegExp(r'"concernItems":\s*\[([\s\S]*?)\]').firstMatch(summary);
          if (concernItemsMatch != null) {
            final concernItemsStr = concernItemsMatch.group(1) ?? '';
            final concernItems = RegExp(r'"([^"]*)"').allMatches(concernItemsStr)
                .map((m) => m.group(1) ?? '').where((item) => item.isNotEmpty).toList();
            if (concernItems.isNotEmpty) {
              analysisComponents.add('Items of Concern:\n${concernItems.map((item) => '• $item').join('\n')}');
            }
          }
          
          // Extract recommendations
          final recommendationsMatch = RegExp(r'"recommendations":\s*"([^"]*)"').firstMatch(summary);
          if (recommendationsMatch != null) {
            analysisComponents.add('Recommendations:\n${recommendationsMatch.group(1)}');
          }
          
          // Extract nutrition breakdown
          final proteinsMatch = RegExp(r'"proteins":\s*(\d+)').firstMatch(summary);
          final carbsMatch = RegExp(r'"carbohydrates":\s*(\d+)').firstMatch(summary);
          final fatsMatch = RegExp(r'"fats":\s*(\d+)').firstMatch(summary);
          final processedMatch = RegExp(r'"processed_foods":\s*(\d+)').firstMatch(summary);
          final wholeMatch = RegExp(r'"whole_foods":\s*(\d+)').firstMatch(summary);
          
          if (proteinsMatch != null || carbsMatch != null || fatsMatch != null) {
            List<String> nutritionInfo = ['Nutrition Breakdown:'];
            if (proteinsMatch != null) nutritionInfo.add('• Protein: ${proteinsMatch.group(1)}%');
            if (carbsMatch != null) nutritionInfo.add('• Carbohydrates: ${carbsMatch.group(1)}%');
            if (fatsMatch != null) nutritionInfo.add('• Fats: ${fatsMatch.group(1)}%');
            if (processedMatch != null) nutritionInfo.add('• Processed Foods: ${processedMatch.group(1)}%');
            if (wholeMatch != null) nutritionInfo.add('• Whole Foods: ${wholeMatch.group(1)}%');
            analysisComponents.add(nutritionInfo.join('\n'));
          }
          
          final result = analysisComponents.join('\n\n');
          print('🔍 Final parsed llmSummary: $result');
          return result;
        }
      }
      
      // If it's not malformed JSON, return as is
      return summary;
    }
    
    // For any other type, convert to string
    return llmSummaryRaw.toString();
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