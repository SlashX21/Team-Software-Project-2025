class PurchasedItem {
  final String productName;
  final int quantity;

  const PurchasedItem({
    required this.productName,
    required this.quantity,
  });

  factory PurchasedItem.fromJson(Map<String, dynamic> json) {
    return PurchasedItem(
      productName: json['productName']?.toString() ?? 'Unknown Product',
      quantity: json['quantity'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'quantity': quantity,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PurchasedItem &&
        other.productName == productName &&
        other.quantity == quantity;
  }

  @override
  int get hashCode => productName.hashCode ^ quantity.hashCode;

  @override
  String toString() {
    return 'PurchasedItem(productName: $productName, quantity: $quantity)';
  }
}