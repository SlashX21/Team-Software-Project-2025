class ProductAnalysis {
  final String name;
  final String imageUrl;
  final List<String> ingredients;
  final List<String> detectedAllergens;

  const ProductAnalysis({
    required this.name,
    required this.imageUrl,
    required this.ingredients,
    required this.detectedAllergens,
  });
}