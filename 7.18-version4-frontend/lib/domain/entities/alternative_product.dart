import 'product_info.dart';

class AlternativeProduct {
  final int rank;
  final ProductInfo product;
  final double recommendationScore;
  final String reasoning;

  const AlternativeProduct({
    required this.rank,
    required this.product,
    required this.recommendationScore,
    required this.reasoning,
  });

  factory AlternativeProduct.fromJson(Map<String, dynamic> json) {
    return AlternativeProduct(
      rank: json['rank'] as int,
      product: ProductInfo.fromJson(json['product'] as Map<String, dynamic>),
      recommendationScore: (json['recommendationScore'] as num).toDouble(),
      reasoning: json['reasoning'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'product': product.toJson(),
      'recommendationScore': recommendationScore,
      'reasoning': reasoning,
    };
  }

  String get formattedScore {
    return '${(recommendationScore * 100).toStringAsFixed(0)}%';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlternativeProduct &&
        other.rank == rank &&
        other.product == product &&
        other.recommendationScore == recommendationScore &&
        other.reasoning == reasoning;
  }

  @override
  int get hashCode {
    return rank.hashCode ^
        product.hashCode ^
        recommendationScore.hashCode ^
        reasoning.hashCode;
  }

  @override
  String toString() {
    return 'AlternativeProduct(rank: $rank, product: $product, recommendationScore: $recommendationScore, reasoning: $reasoning)';
  }
}