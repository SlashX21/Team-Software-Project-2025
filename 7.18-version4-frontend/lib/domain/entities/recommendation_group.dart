import 'purchased_item.dart';
import 'alternative_product.dart';

class RecommendationGroup {
  final PurchasedItem originalItem;
  final List<AlternativeProduct> alternatives;

  const RecommendationGroup({
    required this.originalItem,
    required this.alternatives,
  });

  factory RecommendationGroup.fromJson(Map<String, dynamic> json) {
    return RecommendationGroup(
      originalItem: PurchasedItem.fromJson(json['originalItem'] as Map<String, dynamic>? ?? {}),
      alternatives: (json['alternatives'] as List<dynamic>?)
          ?.map((item) => AlternativeProduct.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalItem': originalItem.toJson(),
      'alternatives': alternatives.map((item) => item.toJson()).toList(),
    };
  }

  bool get hasAlternatives => alternatives.isNotEmpty;

  AlternativeProduct? get topAlternative => 
      alternatives.isNotEmpty ? alternatives.first : null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecommendationGroup &&
        other.originalItem == originalItem &&
        _listEquals(other.alternatives, alternatives);
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
  int get hashCode => originalItem.hashCode ^ alternatives.hashCode;

  @override
  String toString() {
    return 'RecommendationGroup(originalItem: $originalItem, alternatives: $alternatives)';
  }
}