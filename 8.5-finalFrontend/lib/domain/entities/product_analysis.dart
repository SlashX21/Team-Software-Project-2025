class ProductAnalysis {
  final String name;
  final String imageUrl;
  final List<String> ingredients;
  final List<String> detectedAllergens;
  final String summary;
  final String detailedAnalysis;
  final List<String> actionSuggestions;
  
  // 新增属性以支持推荐功能
  final String? barcode;
  final List<ProductAnalysis> recommendations;
  final Map<String, dynamic>? llmAnalysis;
  final String? detailedSummary; // 新增：详细推荐理由（用于详情页面）

  ProductAnalysis({
    required this.name,
    required this.imageUrl,
    required this.ingredients,
    required this.detectedAllergens,
    this.summary = '',
    this.detailedAnalysis = '',
    this.actionSuggestions = const [],
    this.barcode,
    this.recommendations = const [],
    this.llmAnalysis,
    this.detailedSummary, // 新增：详细推荐理由参数
  });

  // 智能解析成分字符串，正确处理括号内容 - 静态方法
  static List<String> _parseIngredientsString(String ingredientsString) {
    List<String> ingredients = [];
    String current = '';
    int bracketLevel = 0;
    
    for (int i = 0; i < ingredientsString.length; i++) {
      String char = ingredientsString[i];
      
      if (char == '(') {
        bracketLevel++;
        current += char;
      } else if (char == ')') {
        bracketLevel--;
        // Fix negative bracket count (unmatched closing bracket/parenthesis)
        if (bracketLevel < 0) {
          bracketLevel = 0;
        }
        current += char;
      } else if (char == ',' && bracketLevel == 0) {
        // 只有在括号外的逗号才分割
        String ingredient = current.trim();
        if (ingredient.isNotEmpty) {
          ingredients.add(ingredient);
        }
        current = '';
      } else {
        current += char;
      }
    }
    
    // 添加最后一个成分
    String lastIngredient = current.trim();
    if (lastIngredient.isNotEmpty) {
      ingredients.add(lastIngredient);
    }
    
    // 修复未闭合的括号
    ingredients = _fixUnmatchedParentheses(ingredients);
    
    return ingredients;
  }
  
  // 修复未闭合的括号
  static List<String> _fixUnmatchedParentheses(List<String> ingredients) {
    List<String> fixed = [];
    String pendingIngredient = '';
    
    for (int i = 0; i < ingredients.length; i++) {
      String current = ingredients[i];
      
      // 如果有未完成的成分，先合并
      if (pendingIngredient.isNotEmpty) {
        current = pendingIngredient + ', ' + current;
        pendingIngredient = '';
      }
      
      // 计算括号数量
      int openCount = current.split('(').length - 1;
      int closeCount = current.split(')').length - 1;
      
      if (openCount > closeCount) {
        // 有未闭合的括号，需要与下一个成分合并
        pendingIngredient = current;
      } else {
        // 括号匹配或无括号，可以添加
        fixed.add(current);
      }
    }
    
    // 如果最后还有未完成的成分，直接添加
    if (pendingIngredient.isNotEmpty) {
      fixed.add(pendingIngredient);
    }
    
    return fixed;
  }

  // 公共方法，供其他页面使用相同的解析逻辑
  static List<String>? parseIngredientsFromString(String? ingredientsString) {
    if (ingredientsString == null || ingredientsString.trim().isEmpty) {
      return null;
    }
    return _parseIngredientsString(ingredientsString.trim());
  }

  factory ProductAnalysis.fromJson(Map<String, dynamic> json) {
    // 处理 ingredients，可能是字符串数组或逗号分隔的字符串
    List<String> parseIngredients(dynamic ingredientsData) {
      if (ingredientsData == null) return [];
      if (ingredientsData is List) {
        return List<String>.from(ingredientsData);
      }
      if (ingredientsData is String) {
        // 改进的成分解析：正确处理括号内容
        return _parseIngredientsString(ingredientsData);
      }
      return [];
    }

    // 处理 allergens，可能是字符串数组或逗号分隔的字符串
    List<String> parseAllergens(dynamic allergensData) {
      if (allergensData == null) return [];
      if (allergensData is List) {
        return List<String>.from(allergensData);
      }
      if (allergensData is String) {
        return allergensData
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return [];
    }

    // 处理推荐列表
    List<ProductAnalysis> parseRecommendations(dynamic recommendationsData) {
      if (recommendationsData == null) return [];
      if (recommendationsData is List) {
        return recommendationsData
            .map((item) => ProductAnalysis.fromJson(item))
            .toList();
      }
      return [];
    }

    return ProductAnalysis(
      name: json['name'] ?? json['productName'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image'] ?? '',
      ingredients: parseIngredients(json['ingredients']),
      detectedAllergens: parseAllergens(json['detectedAllergens'] ?? json['allergens']),
      summary: json['summary'] ?? '',
      detailedAnalysis: json['detailedAnalysis'] ?? json['analysis'] ?? '',
      actionSuggestions: List<String>.from(json['actionSuggestions'] ?? json['suggestions'] ?? []),
      barcode: json['barcode'] ?? json['barCode'],
      recommendations: parseRecommendations(json['recommendations']),
      llmAnalysis: json['llmAnalysis'],
      detailedSummary: json['detailedSummary'] ?? json['detailed_reasoning'], // 修复：正确解析详细推荐理由
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'ingredients': ingredients,
      'detectedAllergens': detectedAllergens,
      'summary': summary,
      'detailedAnalysis': detailedAnalysis,
      'actionSuggestions': actionSuggestions,
      'barcode': barcode,
      'recommendations': recommendations.map((r) => r.toJson()).toList(),
      'llmAnalysis': llmAnalysis,
      'detailedSummary': detailedSummary, // 修复：添加详细推荐理由序列化
    };
  }

  ProductAnalysis copyWith({
    String? name,
    String? imageUrl,
    List<String>? ingredients,
    List<String>? detectedAllergens,
    String? summary,
    String? detailedAnalysis,
    List<String>? actionSuggestions,
    String? barcode,
    List<ProductAnalysis>? recommendations,
    Map<String, dynamic>? llmAnalysis,
    String? detailedSummary,
  }) {
    return ProductAnalysis(
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredients: ingredients ?? this.ingredients,
      detectedAllergens: detectedAllergens ?? this.detectedAllergens,
      summary: summary ?? this.summary,
      detailedAnalysis: detailedAnalysis ?? this.detailedAnalysis,
      actionSuggestions: actionSuggestions ?? this.actionSuggestions,
      barcode: barcode ?? this.barcode,
      recommendations: recommendations ?? this.recommendations,
      llmAnalysis: llmAnalysis ?? this.llmAnalysis,
      detailedSummary: detailedSummary ?? this.detailedSummary,
  );
  }
}