class ProductAnalysis {
  final String name;
  final String imageUrl;
  final List<String> ingredients;
  final List<String> detectedAllergens;
  final String summary;
  final String detailedAnalysis;
  final List<String> actionSuggestions;

  ProductAnalysis({
    required this.name,
    required this.imageUrl,
    required this.ingredients,
    required this.detectedAllergens,
    this.summary = '',
    this.detailedAnalysis = '',
    this.actionSuggestions = const [],
  });

  factory ProductAnalysis.fromJson(Map<String, dynamic> json) {
    // 处理 ingredients，可能是字符串数组或逗号分隔的字符串
    List<String> parseIngredients(dynamic ingredientsData) {
      if (ingredientsData == null) return [];
      if (ingredientsData is List) {
        return List<String>.from(ingredientsData);
      }
      if (ingredientsData is String) {
        return ingredientsData
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
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

    return ProductAnalysis(
      name: json['name'] ?? json['productName'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image'] ?? '',
      ingredients: parseIngredients(json['ingredients']),
      detectedAllergens: parseAllergens(json['detectedAllergens'] ?? json['allergens']),
      summary: json['summary'] ?? '',
      detailedAnalysis: json['detailedAnalysis'] ?? json['analysis'] ?? '',
      actionSuggestions: List<String>.from(json['actionSuggestions'] ?? json['suggestions'] ?? []),
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
  }) {
    return ProductAnalysis(
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredients: ingredients ?? this.ingredients,
      detectedAllergens: detectedAllergens ?? this.detectedAllergens,
      summary: summary ?? this.summary,
      detailedAnalysis: detailedAnalysis ?? this.detailedAnalysis,
      actionSuggestions: actionSuggestions ?? this.actionSuggestions,
  );
  }
}