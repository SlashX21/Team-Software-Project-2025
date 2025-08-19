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
      barcode: json['barcode'] as String? ?? json['barCode'] as String?,  // Handle both field names (backend will fix barCode -> barcode)
      name: json['name']?.toString() ?? json['productName']?.toString() ?? 'Unknown Product',  // Handle both field names
      brand: json['brand'] as String?,  // May be null after backend removes it
      category: json['category'] as String?,  // May be null after backend removes it
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
  
  factory RecommendationItem.fromJson(Map<String, dynamic> json, {int index = 0}) {
    // Print detailed debug information for recommendation item
    print('\n' + '=' * 80);
    print('🔍 RECOMMENDATION ITEM DEBUG #$index');
    print('=' * 80);
    print('Raw JSON: $json');
    print('-' * 40);
    
    // Handle simplified database structure
    if (json.containsKey('productName') && json.containsKey('summary')) {
      print('📝 Using SIMPLIFIED structure (productName + summary)');
      // This is from the simplified database structure
      return RecommendationItem.fromSimplifiedJson(json, index);
    }
    
    // Handle normal structure
    print('📝 Using NORMAL structure (product + reasoning)');
    
    // Extract and debug each field
    final rank = json['rank'] as int;
    final productData = json['product'] as Map<String, dynamic>;
    final score = (json['recommendationScore'] as num).toDouble();
    final reasoning = json['reasoning']?.toString() ?? '';
    
    print('📋 EXTRACTED FIELDS:');
    print('   Rank: $rank');
    print('   Product Data: $productData');
    print('   Score: $score');
    print('   Reasoning: "$reasoning"');
    print('   Reasoning Length: ${reasoning.length} characters');
    print('   Reasoning Type: ${reasoning.runtimeType}');
    
    // Check if reasoning contains any special characters
    print('📊 REASONING ANALYSIS:');
    print('   Contains ###: ${reasoning.contains('###')}');
    print('   Contains **: ${reasoning.contains('**')}');
    print('   Contains emoji 💪: ${reasoning.contains('💪')}');
    print('   Contains emoji 🌟: ${reasoning.contains('🌟')}');
    print('   Contains \\n: ${reasoning.contains('\\n')}');
    print('   Contains actual newlines: ${reasoning.contains('\n')}');
    
    // Show first 200 characters if reasoning is long
    if (reasoning.length > 200) {
      print('   First 200 chars: "${reasoning.substring(0, 200)}..."');
    }
    
    print('=' * 80 + '\n');
    
    return RecommendationItem(
      rank: rank,
      product: ProductInfo.fromJson(productData),
      recommendationScore: score,
      nutritionImprovement: json['nutritionImprovement'] != null 
          ? NutritionImprovement.fromJson(json['nutritionImprovement'] as Map<String, dynamic>)
          : null,
      reasoning: reasoning,
    );
  }
  
  factory RecommendationItem.fromSimplifiedJson(Map<String, dynamic> json, int index) {
    print('\n' + '🔸' * 40);
    print('🔍 SIMPLIFIED STRUCTURE DEBUG #$index');
    print('🔸' * 40);
    print('Raw JSON: $json');
    print('-' * 20);
    
    // Clean up and process the summary content
    String summary = json['summary']?.toString() ?? 'No reasoning provided';
    
    print('📋 ORIGINAL SUMMARY:');
    print('   Raw: "$summary"');
    print('   Length: ${summary.length} characters');
    print('   Type: ${summary.runtimeType}');
    
    // Clean up any escaped characters that might be in the summary
    summary = summary
        .replaceAll('\\n', '\n')  // Convert escaped newlines to actual newlines
        .replaceAll('\\t', '\t')  // Convert escaped tabs to actual tabs
        .trim();
    
    print('📋 PROCESSED SUMMARY:');
    print('   Processed: "$summary"');
    print('   Length: ${summary.length} characters');
    
    // Check if summary contains any special characters
    print('📊 SUMMARY ANALYSIS:');
    print('   Contains ###: ${summary.contains('###')}');
    print('   Contains **: ${summary.contains('**')}');
    print('   Contains emoji 💪: ${summary.contains('💪')}');
    print('   Contains emoji 🌟: ${summary.contains('🌟')}');
    print('   Contains \\n: ${summary.contains('\\n')}');
    print('   Contains actual newlines: ${summary.contains('\n')}');
    
    // Show first 200 characters if summary is long
    if (summary.length > 200) {
      print('   First 200 chars: "${summary.substring(0, 200)}..."');
    }
    
    print('🔸' * 40 + '\n');
    
    return RecommendationItem(
      rank: index + 1, // Use index as rank
      product: ProductInfo(
        barcode: json['barcode']?.toString(),
        name: json['productName']?.toString() ?? 'Unknown Product',
        brand: null,
        category: null,
        allergens: [],
        ingredients: null,
      ),
      recommendationScore: 0.8, // Default score since not provided
      nutritionImprovement: null, // Not available in simplified structure
      reasoning: summary,
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
    return ScanHistoryProductDetail(
      scanId: json['barcodeId'] as int,  // Backend returns 'barcodeId' not 'scanId'
      recommendationId: json['recommendationId']?.toString() ?? '',
      productInfo: ProductInfo.fromJson(json['productInfo'] as Map<String, dynamic>),
      aiAnalysis: AIAnalysis.fromJson(json['aiAnalysis'] as Map<String, dynamic>),
      recommendations: _parseRecommendations(json['recommendations']),
      scannedAt: DateTime.parse(json['scannedAt'] as String),
    );
  }
  
  static List<RecommendationItem> _parseRecommendations(dynamic recommendationsData) {
    if (recommendationsData == null) {
      return [];
    }
    
    List<dynamic> recommendationsList = [];
    
    // Handle different data formats
    if (recommendationsData is String) {
      try {
        final parsed = jsonDecode(recommendationsData);
        if (parsed is List) {
          recommendationsList = parsed;
        } else {
          return [];
        }
      } catch (e) {
        return [];
      }
    } else if (recommendationsData is List) {
      recommendationsList = recommendationsData;
    } else {
      return [];
    }
    
    return recommendationsList
        .asMap()
        .entries
        .map((entry) {
          try {
            return RecommendationItem.fromJson(
                entry.value as Map<String, dynamic>, 
                index: entry.key);
          } catch (e) {
            return null;
          }
        })
        .where((item) => item != null)
        .cast<RecommendationItem>()
        .toList();
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