class SugarContributor {
  final int id;
  final String foodName;
  final double sugarAmountMg;
  final double quantity;
  final DateTime consumedAt;

  SugarContributor({
    required this.id,
    required this.foodName,
    required this.sugarAmountMg,
    required this.quantity,
    required this.consumedAt,
  });

  factory SugarContributor.fromJson(Map<String, dynamic> json) {
    return SugarContributor(
      id: _parseIntId(json['id']),
      foodName: json['foodName'] ?? '',
      sugarAmountMg: json['sugarAmountMg']?.toDouble() ?? 0.0,
      quantity: json['quantity']?.toDouble() ?? 1.0,
      consumedAt: DateTime.parse(json['consumedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'foodName': foodName,
      'sugarAmountMg': sugarAmountMg,
      'quantity': quantity,
      'consumedAt': consumedAt.toIso8601String(),
    };
  }

  static int _parseIntId(dynamic id) {
    if (id is int) return id;
    if (id is String) return int.parse(id);
    throw ArgumentError('Invalid ID type: $id');
  }

  // 格式化糖分显示
  String get formattedSugarAmount {
    if (sugarAmountMg >= 1000) {
      return '${(sugarAmountMg / 1000).toStringAsFixed(1)}g';
    } else {
      return '${sugarAmountMg.toInt()}mg';
    }
  }

  // 格式化摄入时间显示
  String get formattedConsumedTime {
    final now = DateTime.now();
    final difference = now.difference(consumedAt);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes.abs()} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours.abs()} hr ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays.abs()} days ago';
    } else {
      return '${consumedAt.day}/${consumedAt.month}/${consumedAt.year}';
    }
  }

  // 计算总糖分（考虑数量）
  double get totalSugarAmount => sugarAmountMg * quantity;

  // 格式化总糖分显示
  String get formattedTotalSugarAmount {
    final total = totalSugarAmount;
    if (total >= 1000) {
      return '${(total / 1000).toStringAsFixed(1)}g';
    } else {
      return '${total.toInt()}mg';
    }
  }
}