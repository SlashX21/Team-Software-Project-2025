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
