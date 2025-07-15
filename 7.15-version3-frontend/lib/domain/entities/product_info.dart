class ProductInfo {
  final String barCode;
  final String productName;
  final String brand;
  final String category;

  const ProductInfo({
    required this.barCode,
    required this.productName,
    required this.brand,
    required this.category,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      barCode: json['barCode'] as String,
      productName: json['productName'] as String,
      brand: json['brand'] as String,
      category: json['category'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barCode': barCode,
      'productName': productName,
      'brand': brand,
      'category': category,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductInfo &&
        other.barCode == barCode &&
        other.productName == productName &&
        other.brand == brand &&
        other.category == category;
  }

  @override
  int get hashCode {
    return barCode.hashCode ^
        productName.hashCode ^
        brand.hashCode ^
        category.hashCode;
  }

  @override
  String toString() {
    return 'ProductInfo(barCode: $barCode, productName: $productName, brand: $brand, category: $category)';
  }
}