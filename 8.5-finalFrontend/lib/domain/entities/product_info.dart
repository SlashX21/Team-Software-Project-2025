class ProductInfo {
  final String barCode;
  final String productName;
  final String brand;
  final String category;
  final String? ingredients;
  final String? allergens;
  final double? energy100g;
  final double? energyKcal100g;
  final double? fat100g;
  final double? saturatedFat100g;
  final double? carbohydrates100g;
  final double? sugars100g;
  final double? proteins100g;
  final String? servingSize;

  const ProductInfo({
    required this.barCode,
    required this.productName,
    required this.brand,
    required this.category,
    this.ingredients,
    this.allergens,
    this.energy100g,
    this.energyKcal100g,
    this.fat100g,
    this.saturatedFat100g,
    this.carbohydrates100g,
    this.sugars100g,
    this.proteins100g,
    this.servingSize,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      barCode: json['barCode'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      category: json['category'] as String? ?? '',
      ingredients: json['ingredients'] as String?,
      allergens: json['allergens'] as String?,
      energy100g: (json['energy100g'] as num?)?.toDouble(),
      energyKcal100g: (json['energyKcal100g'] as num?)?.toDouble(),
      fat100g: (json['fat100g'] as num?)?.toDouble(),
      saturatedFat100g: (json['saturatedFat100g'] as num?)?.toDouble(),
      carbohydrates100g: (json['carbohydrates100g'] as num?)?.toDouble(),
      sugars100g: (json['sugars100g'] as num?)?.toDouble(),
      proteins100g: (json['proteins100g'] as num?)?.toDouble(),
      servingSize: json['servingSize'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barCode': barCode,
      'productName': productName,
      'brand': brand,
      'category': category,
      'ingredients': ingredients,
      'allergens': allergens,
      'energy100g': energy100g,
      'energyKcal100g': energyKcal100g,
      'fat100g': fat100g,
      'saturatedFat100g': saturatedFat100g,
      'carbohydrates100g': carbohydrates100g,
      'sugars100g': sugars100g,
      'proteins100g': proteins100g,
      'servingSize': servingSize,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductInfo &&
        other.barCode == barCode &&
        other.productName == productName &&
        other.brand == brand &&
        other.category == category &&
        other.ingredients == ingredients &&
        other.allergens == allergens &&
        other.energy100g == energy100g &&
        other.energyKcal100g == energyKcal100g &&
        other.fat100g == fat100g &&
        other.saturatedFat100g == saturatedFat100g &&
        other.carbohydrates100g == carbohydrates100g &&
        other.sugars100g == sugars100g &&
        other.proteins100g == proteins100g &&
        other.servingSize == servingSize;
  }

  @override
  int get hashCode {
    return barCode.hashCode ^
        productName.hashCode ^
        brand.hashCode ^
        category.hashCode ^
        ingredients.hashCode ^
        allergens.hashCode ^
        energy100g.hashCode ^
        energyKcal100g.hashCode ^
        fat100g.hashCode ^
        saturatedFat100g.hashCode ^
        carbohydrates100g.hashCode ^
        sugars100g.hashCode ^
        proteins100g.hashCode ^
        servingSize.hashCode;
  }

  @override
  String toString() {
    return 'ProductInfo(barCode: $barCode, productName: $productName, brand: $brand, category: $category, ingredients: $ingredients, allergens: $allergens, energy100g: $energy100g, energyKcal100g: $energyKcal100g, fat100g: $fat100g, saturatedFat100g: $saturatedFat100g, carbohydrates100g: $carbohydrates100g, sugars100g: $sugars100g, proteins100g: $proteins100g, servingSize: $servingSize)';
  }
}