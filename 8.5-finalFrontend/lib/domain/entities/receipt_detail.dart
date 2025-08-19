import 'dart:convert';
import 'purchased_item.dart';
import 'recommendation_group.dart';
import 'alternative_product.dart';
import 'product_info.dart';

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
      purchasedItems: _parsePurchasedItems(json['purchasedItems']),
      llmSummary: _parseLlmSummary(json['llmSummary']),
      recommendationsList: _parseRecommendationsList(json['recommendationsList']),
      hasLLMAnalysis: json['hasLLMAnalysis'] as bool? ?? false,
      hasRecommendations: json['hasRecommendations'] as bool? ?? false,
    );
  }
  
  static List<PurchasedItem> _parsePurchasedItems(dynamic purchasedItemsRaw) {
    print('🔍 Parsing purchasedItems: $purchasedItemsRaw (type: ${purchasedItemsRaw.runtimeType})');
    
    if (purchasedItemsRaw == null) {
      return [];
    }
    
    // 如果已经是List，直接处理
    if (purchasedItemsRaw is List<dynamic>) {
      return purchasedItemsRaw
          .map((item) => PurchasedItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    
    // 如果是字符串，先解析JSON再处理
    if (purchasedItemsRaw is String) {
      try {
        print('🔍 Attempting to parse purchasedItems JSON string...');
        final List<dynamic> parsedList = jsonDecode(purchasedItemsRaw);
        print('🔍 Successfully parsed purchasedItems: $parsedList');
        return parsedList
            .map((item) => PurchasedItem.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print('❌ Failed to parse purchasedItems JSON string: $e');
        return [];
      }
    }
    
    print('❌ Unexpected purchasedItems type: ${purchasedItemsRaw.runtimeType}');
    return [];
  }

  static List<RecommendationGroup> _parseRecommendationsList(dynamic recommendationsListRaw) {
    print('🔍 Parsing recommendationsList: $recommendationsListRaw (type: ${recommendationsListRaw.runtimeType})');
    
    if (recommendationsListRaw == null) {
      return [];
    }
    
    List<dynamic> parsedList;
    
    // 如果已经是List，直接处理
    if (recommendationsListRaw is List<dynamic>) {
      parsedList = recommendationsListRaw;
    }
    // 如果是字符串，先解析JSON再处理
    else if (recommendationsListRaw is String) {
      try {
        print('🔍 Attempting to parse recommendationsList JSON string...');
        parsedList = jsonDecode(recommendationsListRaw);
        print('🔍 Successfully parsed recommendationsList: $parsedList');
      } catch (e) {
        print('❌ Failed to parse recommendationsList JSON string: $e');
        return [];
      }
    } else {
      print('❌ Unexpected recommendationsList type: ${recommendationsListRaw.runtimeType}');
      return [];
    }
    
    if (parsedList.isEmpty) {
      print('🔍 Empty recommendationsList');
      return [];
    }
    
    // 检查新的推荐格式 [{"product": {...}, "reasoning": "...", "score": 1.0}]
    if (parsedList.first is Map<String, dynamic>) {
      final firstItem = parsedList.first as Map<String, dynamic>;
      if (firstItem.containsKey('product') && firstItem.containsKey('reasoning')) {
        print('🔍 Detected new recommendation format with product and reasoning');
        
        // 将新推荐格式转换为 RecommendationGroup 格式
        final List<AlternativeProduct> alternatives = [];
        
        for (int i = 0; i < parsedList.length; i++) {
          final item = parsedList[i] as Map<String, dynamic>;
          final productData = item['product'] as Map<String, dynamic>?;
          
          if (productData != null) {
            try {
              final product = ProductInfo(
                barCode: productData['barCode']?.toString() ?? '',
                productName: productData['productName']?.toString() ?? 'Unknown Product',
                brand: productData['brand']?.toString() ?? '',
                category: productData['category']?.toString() ?? '',
                ingredients: productData['ingredients']?.toString(),
                allergens: productData['allergens']?.toString(),
                energy100g: productData['energy100g']?.toDouble(),
                energyKcal100g: productData['energyKcal100g']?.toDouble(),
                fat100g: productData['fat100g']?.toDouble(),
                saturatedFat100g: productData['saturatedFat100g']?.toDouble(),
                carbohydrates100g: productData['carbohydrates100g']?.toDouble(),
                sugars100g: productData['sugars100g']?.toDouble(),
                proteins100g: productData['proteins100g']?.toDouble(),
                servingSize: productData['servingSize']?.toString(),
              );
              
              alternatives.add(AlternativeProduct(
                rank: i + 1,
                product: product,
                recommendationScore: (item['score'] as num?)?.toDouble() ?? 0.0,
                reasoning: item['reasoning']?.toString() ?? '',
              ));
            } catch (e) {
              print('❌ Error parsing product data: $e');
            }
          }
        }
        
        if (alternatives.isNotEmpty) {
          return [RecommendationGroup(
            originalItem: PurchasedItem(productName: 'Shopping Receipt', quantity: 1),
            alternatives: alternatives,
          )];
        }
      }
      
      // 检查是否是简单建议格式 [{"category": "meal_prep", "suggestion": "..."}]
      if (firstItem.containsKey('category') && firstItem.containsKey('suggestion')) {
        print('🔍 Detected simple recommendation format, converting to RecommendationGroup format');
        
        // 将简单建议转换为 RecommendationGroup 格式
        return parsedList.map((item) {
          final itemMap = item as Map<String, dynamic>;
          return RecommendationGroup(
            originalItem: PurchasedItem(productName: 'General', quantity: 1),
            alternatives: [
              AlternativeProduct(
                rank: 1,
                product: ProductInfo(
                  barCode: '',
                  productName: itemMap['suggestion'] ?? 'Suggestion',
                  brand: '',
                  category: itemMap['category'] ?? 'General',
                ),
                recommendationScore: 0.8,
                reasoning: itemMap['suggestion'] ?? '',
              ),
            ],
          );
        }).toList();
      }
    }
    
    // 尝试解析为标准的 RecommendationGroup 格式
    try {
      return parsedList
          .map((item) => RecommendationGroup.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Failed to parse as RecommendationGroup: $e');
      return [];
    }
  }

  static String _parseLlmSummary(dynamic llmSummaryRaw) {
    print('🔍 Parsing llmSummary: $llmSummaryRaw (type: ${llmSummaryRaw.runtimeType})');
    
    if (llmSummaryRaw == null) {
      return '';
    }
    
    // Handle Map<String, dynamic> (parsed JSON object)
    // IMPORTANT: Keep the original JSON structure for UI parsing
    if (llmSummaryRaw is Map<String, dynamic>) {
      print('🔍 llmSummary is a Map, preserving JSON structure for UI...');
      
      // Return the JSON string to preserve the structure for UI parsing
      try {
        String jsonString = jsonEncode(llmSummaryRaw);
        print('🔍 Preserved JSON structure: $jsonString');
        return jsonString;
      } catch (e) {
        print('❌ Failed to encode JSON, falling back to summary extraction: $e');
        
        // Fallback: extract just the summary if JSON encoding fails
        if (llmSummaryRaw['summary'] != null) {
          return llmSummaryRaw['summary'].toString();
        }
        return '';
      }
    }
    
    if (llmSummaryRaw is String) {
      final summary = llmSummaryRaw;
      
      // Check if it's a malformed JSON string containing detailed analysis
      if (summary.contains('"summary"') && summary.contains('"healthScore"')) {
        print('🔍 Detected detailed JSON in llmSummary, parsing...');
        
        // Extract the summary field from the JSON
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
      
      // If it's not detailed JSON, return as is
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