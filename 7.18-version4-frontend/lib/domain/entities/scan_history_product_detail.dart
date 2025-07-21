import 'dart:convert';

class ProductInfo {
  final String? barcode;  // Made optional since backend doesn't always provide it
  final String name;
  final String? brand;
  final String? category;
  final List<String> allergens;
  final String? ingredients;
  
  ProductInfo({
    this.barcode,  // Made optional
    required this.name,
    this.brand,
    this.category,
    required this.allergens,
    this.ingredients,
  });
  
  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      barcode: json['barcode'] as String? ?? json['barCode'] as String?,  // Handle both field names
      name: json['name']?.toString() ?? json['productName']?.toString() ?? 'Unknown Product',  // Handle both field names
      brand: json['brand'] as String?,
      category: json['category'] as String?,
      allergens: (json['allergens'] as List<dynamic>?)
          ?.map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList() ?? [],
      ingredients: json['ingredients']?.toString(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'category': category,
      'allergens': allergens,
      'ingredients': ingredients,
    };
  }
}

class AIAnalysis {
  final String summary;
  final String detailedAnalysis;
  final List<String> actionSuggestions;
  
  AIAnalysis({
    required this.summary,
    required this.detailedAnalysis,
    required this.actionSuggestions,
  });
  
  factory AIAnalysis.fromJson(Map<String, dynamic> json) {
    print('🔍 AIAnalysis.fromJson received JSON with ${json.length} keys: $json');
    print('🔍 JSON keys: ${json.keys.toList()}');
    print('🔍 JSON values types: ${json.values.map((v) => v.runtimeType).toList()}');
    
    for (final entry in json.entries) {
      print('🔍 Key "${entry.key}" -> Value: "${entry.value}" (Type: ${entry.value.runtimeType})');
    }
    
    String summary = '';
    String detailedAnalysis = '';
    List<String> actionSuggestions = [];
    
    // Check if any field contains the malformed JSON string
    String? rawAIString;
    
    // Look through all fields to find the one with AI analysis data
    for (final entry in json.entries) {
      if (entry.value is String) {
        final stringValue = entry.value as String;
        // Check if this string contains AI analysis data
        if (stringValue.contains('"summary"') || 
            stringValue.contains('"healthScore"') || 
            stringValue.contains('Analysis Summary:')) {
          rawAIString = stringValue;
          print('🔍 Found AI analysis in field "${entry.key}": $stringValue');
          break;
        }
      }
    }
    
    if (rawAIString != null) {
      // Parse the malformed JSON-like string manually
      print('🔍 Processing raw AI analysis string: $rawAIString');
      final parsedData = _parseAIAnalysisString(rawAIString);
      summary = parsedData['summary'] ?? '';
      detailedAnalysis = parsedData['detailedAnalysis'] ?? '';
      actionSuggestions = parsedData['actionSuggestions'] ?? [];
    } else {
      // Handle normal JSON structure
      summary = json['summary']?.toString() ?? '';
      detailedAnalysis = json['detailedAnalysis']?.toString() ?? '';
      
      final rawActionSuggestions = json['actionSuggestions'];
      if (rawActionSuggestions is List) {
        actionSuggestions = rawActionSuggestions
            .map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (rawActionSuggestions != null) {
        actionSuggestions = [rawActionSuggestions.toString()];
      }
      
      // If still empty, check if any field might be the raw analysis
      if (summary.isEmpty && detailedAnalysis.isEmpty) {
        print('🔍 No standard fields found, checking all string fields for content...');
        for (final entry in json.entries) {
          if (entry.value is String && (entry.value as String).length > 10) {
            print('🔍 Using field "${entry.key}" as summary: ${entry.value}');
            summary = entry.value as String;
            break;
          }
        }
      }
    }
        
    print('🔍 Final parsed summary: "$summary" (${summary.length} chars)');
    print('🔍 Final parsed detailedAnalysis: "$detailedAnalysis" (${detailedAnalysis.length} chars)');
    print('🔍 Final parsed actionSuggestions: $actionSuggestions (${actionSuggestions.length} items)');
    
    return AIAnalysis(
      summary: summary,
      detailedAnalysis: detailedAnalysis,
      actionSuggestions: actionSuggestions,
    );
  }
  
  static Map<String, dynamic> _parseAIAnalysisString(String rawString) {
    // Extract summary from the malformed JSON
    String summary = '';
    String detailedAnalysis = '';
    List<String> actionSuggestions = [];
    
    // Look for summary field
    final summaryMatch = RegExp(r'"summary":\s*"([^"]*)"').firstMatch(rawString);
    if (summaryMatch != null) {
      summary = summaryMatch.group(1) ?? '';
    }
    
    // Look for recommendations field (use as detailed analysis)
    final recommendationsMatch = RegExp(r'"recommendations"[:\s]*"([^"]*)"').firstMatch(rawString);
    if (recommendationsMatch != null) {
      detailedAnalysis = recommendationsMatch.group(1) ?? '';
    }
    
    // Look for health score and create a more detailed analysis
    final healthScoreMatch = RegExp(r'"healthScore":\s*(\d+)').firstMatch(rawString);
    final totalItemsMatch = RegExp(r'"totalltems":\s*(\d+)').firstMatch(rawString);
    
    // Extract healthy items
    String healthyItems = '';
    final healthyItemsMatch = RegExp(r'"healthyltems":\s*"([^"]*)"').firstMatch(rawString);
    if (healthyItemsMatch != null) {
      healthyItems = healthyItemsMatch.group(1) ?? '';
    }
    
    // Extract concern items
    String concernItems = '';
    final concernItemsMatch = RegExp(r'"concernltems":\s*"([^"]*)"').firstMatch(rawString);
    if (concernItemsMatch != null) {
      concernItems = concernItemsMatch.group(1) ?? '';
    }
    
    // Build enhanced detailed analysis
    List<String> analysisComponents = [];
    
    if (healthScoreMatch != null) {
      analysisComponents.add('Health Score: ${healthScoreMatch.group(1)}/100');
    }
    
    if (totalItemsMatch != null) {
      analysisComponents.add('Total Items Analyzed: ${totalItemsMatch.group(1)}');
    }
    
    if (healthyItems.isNotEmpty) {
      analysisComponents.add('Healthy Items: $healthyItems');
    }
    
    if (concernItems.isNotEmpty) {
      analysisComponents.add('Items of Concern: $concernItems');
    }
    
    if (detailedAnalysis.isNotEmpty) {
      analysisComponents.add('Recommendations: $detailedAnalysis');
    }
    
    // Combine all analysis components
    if (analysisComponents.isNotEmpty) {
      detailedAnalysis = analysisComponents.join('\n\n');
    }
    
    // Extract nutrition breakdown for action suggestions
    final proteinsMatch = RegExp(r'"proteins":\s*(\d+)').firstMatch(rawString);
    final carbsMatch = RegExp(r'"carbohydrates":\s*(\d+)').firstMatch(rawString);
    final fatsMatch = RegExp(r'"fats":\s*(\d+)').firstMatch(rawString);
    
    if (proteinsMatch != null || carbsMatch != null || fatsMatch != null) {
      List<String> nutritionSuggestions = [];
      nutritionSuggestions.add('Nutrition Breakdown:');
      
      if (proteinsMatch != null) {
        nutritionSuggestions.add('• Protein: ${proteinsMatch.group(1)}%');
      }
      if (carbsMatch != null) {
        nutritionSuggestions.add('• Carbohydrates: ${carbsMatch.group(1)}%');
      }
      if (fatsMatch != null) {
        nutritionSuggestions.add('• Fats: ${fatsMatch.group(1)}%');
      }
      
      actionSuggestions = nutritionSuggestions;
    }
    
    return {
      'summary': summary,
      'detailedAnalysis': detailedAnalysis,
      'actionSuggestions': actionSuggestions,
    };
  }
  
  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'detailedAnalysis': detailedAnalysis,
      'actionSuggestions': actionSuggestions,
    };
  }
}

class NutritionImprovement {
  final String proteinIncrease;
  final String sugarReduction;
  final String calorieChange;
  
  NutritionImprovement({
    required this.proteinIncrease,
    required this.sugarReduction,
    required this.calorieChange,
  });
  
  factory NutritionImprovement.fromJson(Map<String, dynamic> json) {
    return NutritionImprovement(
      proteinIncrease: json['proteinIncrease'] as String,
      sugarReduction: json['sugarReduction'] as String,
      calorieChange: json['calorieChange'] as String,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'proteinIncrease': proteinIncrease,
      'sugarReduction': sugarReduction,
      'calorieChange': calorieChange,
    };
  }
}

class RecommendationItem {
  final int rank;
  final ProductInfo product;
  final double recommendationScore;
  final NutritionImprovement? nutritionImprovement;  // Made optional
  final String reasoning;
  
  RecommendationItem({
    required this.rank,
    required this.product,
    required this.recommendationScore,
    this.nutritionImprovement,  // Made optional
    required this.reasoning,
  });
  
  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      rank: json['rank'] as int,
      product: ProductInfo.fromJson(json['product'] as Map<String, dynamic>),
      recommendationScore: (json['recommendationScore'] as num).toDouble(),
      nutritionImprovement: json['nutritionImprovement'] != null 
          ? NutritionImprovement.fromJson(json['nutritionImprovement'] as Map<String, dynamic>)
          : null,
      reasoning: json['reasoning']?.toString() ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'product': product.toJson(),
      'recommendationScore': recommendationScore,
      'nutritionImprovement': nutritionImprovement?.toJson(),
      'reasoning': reasoning,
    };
  }
}

class ScanHistoryProductDetail {
  final int scanId;
  final String recommendationId;
  final ProductInfo productInfo;
  final AIAnalysis aiAnalysis;
  final List<RecommendationItem> recommendations;
  final DateTime scannedAt;
  
  ScanHistoryProductDetail({
    required this.scanId,
    required this.recommendationId,
    required this.productInfo,
    required this.aiAnalysis,
    required this.recommendations,
    required this.scannedAt,
  });
  
  factory ScanHistoryProductDetail.fromJson(Map<String, dynamic> json) {
    print('🔍 ScanHistoryProductDetail.fromJson received data: $json');
    print('🔍 aiAnalysis raw data: ${json['aiAnalysis']}');
    
    return ScanHistoryProductDetail(
      scanId: json['barcodeId'] as int,  // Backend returns 'barcodeId' not 'scanId'
      recommendationId: json['recommendationId']?.toString() ?? '',
      productInfo: ProductInfo.fromJson(json['productInfo'] as Map<String, dynamic>),
      aiAnalysis: AIAnalysis.fromJson(json['aiAnalysis'] as Map<String, dynamic>),
      recommendations: (json['recommendations'] as List<dynamic>?)
          ?.map((item) => RecommendationItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      scannedAt: DateTime.parse(json['scannedAt'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'scanId': scanId,
      'recommendationId': recommendationId,
      'productInfo': productInfo.toJson(),
      'aiAnalysis': aiAnalysis.toJson(),
      'recommendations': recommendations.map((item) => item.toJson()).toList(),
      'scannedAt': scannedAt.toIso8601String(),
    };
  }
}