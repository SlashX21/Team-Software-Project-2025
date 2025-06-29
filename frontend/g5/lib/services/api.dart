// lib/services/api.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../domain/entities/history_response.dart';
import '../domain/entities/history_detail.dart';
import '../domain/entities/history_statistics.dart';
import '../domain/entities/daily_sugar_intake.dart';
import '../domain/entities/sugar_contributor.dart';
import '../domain/entities/sugar_intake_history.dart';
import '../domain/entities/sugar_goal.dart';
import '../domain/entities/monthly_overview.dart';
import '../domain/entities/product_analysis.dart';
import '../domain/entities/recommendation_response.dart'; 

//const String baseUrl = 'http://127.0.0.1:8080'; // chrome访问本地服务器的IP地址
const String baseUrl = 'http://10.0.2.2:8080'; // Android模拟器访问本地服务器的IP地址

/// 获取推荐服务的基础URL
/// Android模拟器使用 10.0.2.2，Chrome浏览器使用 127.0.0.1
String get recommendationBaseUrl {
  // 检测当前运行环境，你可以根据需要修改这个逻辑
  // 当前与主API保持一致的配置方式
  //const String host = '127.0.0.1'; // Chrome浏览器
  const String host = '10.0.2.2'; // Android模拟器
  return 'http://$host:8001';
}

Future<bool> registerUser({
  required String userName,
  required String passwordHash,
  required String email,
  required String gender,
  required double heightCm,
  required double weightKg,
}) async {
  final url = Uri.parse('$baseUrl/user');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "userName": userName,
      "passwordHash": passwordHash,
      "email": email,
      "gender": gender,
      "heightCm": heightCm,
      "weightKg": weightKg,
    }),
  );

  // final response = await http.post(
  //   url,
  //   headers: {'Content-Type': 'application/json'},
  //   body: jsonEncode({
  //     "userName": userName,
  //     "password": password,
  //     "email": email
  //   }),
  // );

  if (response.statusCode == 200 || response.statusCode == 201) {
    return true;
  } else {
    print("Register failed: ${response.statusCode} ${response.body}");
    return false;
  }
}

// Future<Map<String, dynamic>?> loginUser({
//   required String userName,
//   required String passwordHash,
// }) async {
//   final url = Uri.parse('http://127.0.0.1:8080/login');

//   final response = await http.post(
//     url,74
//     headers: {'Content-Type': 'application/json'},
//     body: jsonEncode({
//       "userName": userName,
//       "passwordHash": passwordHash,
//     }),
//   );

//   if (response.statusCode == 200) {
//     final Map<String, dynamic> json = jsonDecode(response.body);
//     if (json['code'] == 200 && json['data'] != null) {
//       return json['data']; 
//     }
//   }

//   return null;
// }

Future<Map<String, dynamic>?> loginUser({
  required String userName,
  required String passwordHash,
}) async {
  final url = Uri.parse('$baseUrl/user/login');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "userName": userName,
      "passwordHash": passwordHash,
    }),
  );

  print("Request Body: ${jsonEncode({
    "userName": userName,
    "passwordHash": passwordHash,
  })}");
  print("Response Status: ${response.statusCode}");
  print("Response Body: ${response.body}");

  if (response.statusCode == 200) {
    final Map<String, dynamic> json = jsonDecode(response.body);
    if (json['code'] == 200 && json['data'] != null) {
      return json['data'];
    }
  }

  return null;
}

// ============================================================================
// Monthly Overview APIs
// ============================================================================

Future<MonthlyOverview?> getMonthlyOverview({
  required int userId,
  required int year,
  required int month,
}) async {
  // TODO: Replace with real API call when backend is ready
  return await MockMonthlyOverviewService.getMockMonthlyOverview(
    userId: userId,
    year: year,
    month: month,
  );
}

Future<MonthlypurchaseSummary?> getMonthlypurchaseSummary({
  required int userId,
  required int year,
  required int month,
}) async {
  // TODO: Replace with real API call when backend is ready
  return await MockMonthlyOverviewService.getMockpurchaseSummary(
    userId: userId,
    year: year,
    month: month,
  );
}

Future<MonthlyNutritionInsights?> getMonthlyNutritionInsights({
  required int userId,
  required int year,
  required int month,
}) async {
  // TODO: Replace with real API call when backend is ready
  return await MockMonthlyOverviewService.getMockNutritionInsights(
    userId: userId,
    year: year,
    month: month,
  );
}

Future<MonthlyComparison?> getMonthlyComparison({
  required int userId,
  required int currentYear,
  required int currentMonth,
  required int previousYear,
  required int previousMonth,
}) async {
  // TODO: Replace with real API call when backend is ready
  return null;
}

Future<List<HealthInsight>?> getMonthlyHealthInsights({
  required int userId,
  required int year,
  required int month,
}) async {
  // TODO: Replace with real API call when backend is ready
  return await MockMonthlyOverviewService.getMockHealthInsights(
    userId: userId,
    year: year,
    month: month,
  );
}

// ============================================================================
// History Record APIs
// ============================================================================

// 获取用户历史记录
Future<HistoryResponse?> getUserHistory({
  required int userId,
  int page = 1,
  int limit = 20,
  String? searchKeyword,
  String? filterType,
  String? dateRange,
}) async {
  // TODO: Replace with real API call when backend is ready
  return await MockHistoryService.getMockHistory(
    userId: userId,
    page: page,
    limit: limit,
    searchKeyword: searchKeyword,
    filterType: filterType,
    dateRange: dateRange,
  );
}

// 获取历史记录详情
Future<HistoryDetail?> getHistoryDetail({
  required int userId,
  required String historyId,
}) async {
  // TODO: Replace with real API call when backend is ready
  return await MockHistoryService.getMockHistoryDetail(
    userId: userId,
    historyId: historyId,
  );
}

// 删除历史记录
Future<bool> deleteHistoryRecord({
  required int userId,
  required String historyId,
}) async {
  // TODO: Replace with real API call when backend is ready
  return await MockHistoryService.deleteMockHistory(
    userId: userId,
    historyId: historyId,
  );
}

// 获取历史统计数据
Future<HistoryStatistics?> getHistoryStatistics({
  required int userId,
  String period = 'month',
}) async {
  // TODO: Replace with real API call when backend is ready
  return await MockHistoryService.getMockStatistics(
    userId: userId,
    period: period,
  );
}

// ============================================================================
// Mock Data Service (Remove when real API is ready)
// ============================================================================

class MockHistoryService {
  static Future<HistoryResponse?> getMockHistory({
    required int userId,
    int page = 1,
    int limit = 20,
    String? searchKeyword,
    String? filterType,
    String? dateRange,
  }) async {
    // 模拟网络延迟
    await Future.delayed(Duration(milliseconds: 800));
    
    // 生成模拟数据
    final mockItems = List.generate(15, (index) {
      return HistoryItem(
        id: 'hist_${DateTime.now().millisecondsSinceEpoch}_$index',
        scanType: index % 3 == 0 ? 'receipt' : 'barcode',
        createdAt: DateTime.now().subtract(Duration(days: index)),
        productName: _getMockProductName(index),
        productImage: 'https://via.placeholder.com/60x60',
        barcode: '${1234567890 + index}',
        recommendationCount: (index % 5) + 1,
        summary: {
          'calories': 150 + (index * 10),
          'sugar': '${5 + index}g',
          'status': index % 2 == 0 ? 'healthy' : 'moderate'
        },
      );
    });

    return HistoryResponse(
      items: mockItems,
      totalCount: 45,
      currentPage: page,
      totalPages: 3,
      hasMore: page < 3,
    );
  }

  static Future<HistoryDetail?> getMockHistoryDetail({
    required int userId,
    required String historyId,
  }) async {
    await Future.delayed(Duration(milliseconds: 500));
    
    return HistoryDetail(
      id: historyId,
      scanType: 'barcode',
      createdAt: DateTime.now().subtract(Duration(hours: 2)),
      productName: 'Organic Whole Wheat Bread',
      productImage: 'https://via.placeholder.com/300x200',
      barcode: '1234567890123',
      recommendationCount: 3,
      summary: {
        'calories': 240,
        'sugar': '3g',
        'status': 'healthy'
      },
      fullAnalysis: {
        'ingredients': ['Organic wheat flour', 'Water', 'Sea salt', 'Yeast'],
        'allergens': ['Gluten'],
        'nutrition_per_100g': {
          'calories': 240,
          'protein': 8.5,
          'carbs': 45.0,
          'fiber': 6.0,
          'sugar': 3.0,
          'fat': 2.5,
          'sodium': 450
        }
      },
      recommendations: [
        {
          'type': 'alternative',
          'title': 'Try whole grain alternatives',
          'description': 'This product is already a healthy choice with whole grains.'
        },
        {
          'type': 'portion',
          'title': 'Recommended serving size',
          'description': '2 slices (60g) for a balanced meal.'
        },
        {
          'type': 'pairing',
          'title': 'Perfect pairings',
          'description': 'Great with avocado, hummus, or natural nut butter.'
        }
      ],
      nutritionData: {
        'health_score': 85.5,
        'category': 'Bakery',
        'dietary_info': ['Vegetarian', 'High Fiber'],
        'warnings': []
      },
    );
  }

  static Future<bool> deleteMockHistory({
    required int userId,
    required String historyId,
  }) async {
    await Future.delayed(Duration(milliseconds: 300));
    return true;
  }

  static String _getMockProductName(int index) {
    final products = [
      'Organic Whole Wheat Bread',
      'Greek Yogurt 500ml',
      'Fresh Orange Juice',
      'Dark Chocolate 70%',
      'Quinoa Salad Bowl',
      'Almond Milk Unsweetened',
      'Avocado Toast Mix',
      'Green Tea Bags',
      'Protein Energy Bar',
      'Mixed Nuts & Seeds',
    ];
    return products[index % products.length];
  }

  static Future<HistoryStatistics?> getMockStatistics({
    required int userId,
    String period = 'month',
  }) async {
    await Future.delayed(Duration(milliseconds: 500));
    
    return HistoryStatistics(
      totalScans: 45,
      barcodeScans: 32,
      receiptScans: 13,
      scansByDate: {
        '2024-01-01': 3,
        '2024-01-02': 5,
        '2024-01-03': 2,
        '2024-01-04': 4,
        '2024-01-05': 6,
      },
      topCategories: ['Dairy', 'Beverages', 'Snacks', 'Fruits'],
    );
  }
}

// ============================================================================
// Sugar Tracking APIs
// ============================================================================

// 获取用户当日糖分摄入统计
Future<DailySugarIntake?> getDailySugarIntake({
  required int userId,
  DateTime? date,
}) async {
  // TODO: Replace with real API call when backend is ready
  return await MockSugarTrackingService.getMockDailySugarIntake(
    userId: userId,
    date: date,
  );
}

// 手动添加糖分摄入记录
Future<bool> addSugarIntakeRecord({
  required int userId,
  required String foodName,
  required double sugarAmount,
  required double quantity,
  DateTime? consumedAt,
}) async {
  // TODO: Replace with real API call when backend is ready
  return await MockSugarTrackingService.addMockSugarRecord(
    userId: userId,
    foodName: foodName,
    sugarAmount: sugarAmount,
    quantity: quantity,
    consumedAt: consumedAt,
  );
}

// 获取糖分摄入历史统计
Future<SugarIntakeHistory?> getSugarIntakeHistory({
  required int userId,
  String period = 'week',
}) async {
  // TODO: Replace with real API call when backend is ready
  return await MockSugarTrackingService.getMockSugarHistory(
    userId: userId,
    period: period,
  );
}

// 获取用户糖分摄入目标
Future<SugarGoal?> getSugarGoal({
  required int userId,
}) async {
  // TODO: Replace with real API call when backend is ready
  return await MockSugarTrackingService.getMockSugarGoal(
    userId: userId,
  );
}

// 设置用户糖分摄入目标
Future<bool> setSugarGoal({
  required int userId,
  required double dailyGoalMg,
}) async {
  // TODO: Replace with real API call when backend is ready
  return await MockSugarTrackingService.setMockSugarGoal(
    userId: userId,
    dailyGoalMg: dailyGoalMg,
  );
}

// 删除糖分摄入记录
Future<bool> deleteSugarIntakeRecord({
  required int userId,
  required String recordId,
}) async {
  // TODO: Replace with real API call when backend is ready
  return await MockSugarTrackingService.deleteMockSugarRecord(
    userId: userId,
    recordId: recordId,
  );
}

// ============================================================================
// Mock Sugar Tracking Service (Remove when real API is ready)
// ============================================================================

class MockSugarTrackingService {
  static Future<DailySugarIntake?> getMockDailySugarIntake({
    required int userId,
    DateTime? date,
  }) async {
    // 模拟网络延迟
    await Future.delayed(Duration(milliseconds: 600));
    
    // 生成模拟数据
    final mockContributors = [
      SugarContributor(
        id: 'sugar_001',
        foodName: 'Orange Juice',
        sugarAmountMg: 240.0,
        quantity: 1.0,
        consumedAt: DateTime.now().subtract(Duration(hours: 2)),
      ),
      SugarContributor(
        id: 'sugar_002',
        foodName: 'Chocolate Cookie',
        sugarAmountMg: 180.0,
        quantity: 2.0,
        consumedAt: DateTime.now().subtract(Duration(hours: 4)),
      ),
      SugarContributor(
        id: 'sugar_003',
        foodName: 'Energy Drink',
        sugarAmountMg: 160.0,
        quantity: 1.0,
        consumedAt: DateTime.now().subtract(Duration(hours: 6)),
      ),
      SugarContributor(
        id: 'sugar_004',
        foodName: 'Yogurt',
        sugarAmountMg: 120.0,
        quantity: 1.0,
        consumedAt: DateTime.now().subtract(Duration(hours: 8)),
      ),
      SugarContributor(
        id: 'sugar_005',
        foodName: 'Apple',
        sugarAmountMg: 100.0,
        quantity: 1.0,
        consumedAt: DateTime.now().subtract(Duration(hours: 10)),
      ),
    ];

    double currentIntake = 0.0;
    for (final contributor in mockContributors) {
      currentIntake += contributor.totalSugarAmount;
    }
    final dailyGoal = 1200.0;
    final progress = (currentIntake / dailyGoal) * 100;

    String status;
    if (progress <= 70) {
      status = 'good';
    } else if (progress <= 100) {
      status = 'warning';
    } else {
      status = 'over_limit';
    }

    return DailySugarIntake(
      currentIntakeMg: currentIntake,
      dailyGoalMg: dailyGoal,
      progressPercentage: progress,
      status: status,
      topContributors: mockContributors.take(4).toList(), // 显示前4个
      date: date ?? DateTime.now(),
    );
  }

  static Future<SugarIntakeHistory?> getMockSugarHistory({
    required int userId,
    String period = 'week',
  }) async {
    await Future.delayed(Duration(milliseconds: 400));
    
    final today = DateTime.now();
    final dailyData = List.generate(7, (index) {
      return DailySugarData(
        date: today.subtract(Duration(days: 6 - index)),
        intakeMg: 800.0 + (index * 50) + (index % 3 * 100),
        goalMg: 1200.0,
      );
    });

    return SugarIntakeHistory(
      dailyData: dailyData,
      averageDailyIntake: 950.0,
      totalIntake: 6650.0,
      daysOverGoal: 2,
      topFoodSources: ['Orange Juice', 'Chocolate', 'Soda', 'Yogurt'],
    );
  }

  static Future<SugarGoal?> getMockSugarGoal({
    required int userId,
  }) async {
    await Future.delayed(Duration(milliseconds: 300));
    
    return SugarGoal(
      dailyGoalMg: 1200.0,
      createdAt: DateTime.now().subtract(Duration(days: 30)),
      updatedAt: DateTime.now().subtract(Duration(days: 7)),
    );
  }

  static Future<bool> addMockSugarRecord({
    required int userId,
    required String foodName,
    required double sugarAmount,
    required double quantity,
    DateTime? consumedAt,
  }) async {
    await Future.delayed(Duration(milliseconds: 500));
    
    // 模拟成功添加
    print('Mock: Added sugar record - $foodName: ${sugarAmount}mg x$quantity');
    return true;
  }

  static Future<bool> setMockSugarGoal({
    required int userId,
    required double dailyGoalMg,
  }) async {
    await Future.delayed(Duration(milliseconds: 400));
    
    // 模拟成功设置目标
    print('Mock: Set sugar goal - ${dailyGoalMg}mg for user $userId');
    return true;
  }

  static Future<bool> deleteMockSugarRecord({
    required int userId,
    required String recordId,
  }) async {
    await Future.delayed(Duration(milliseconds: 300));
    
    // 模拟成功删除
    print('Mock: Deleted sugar record - $recordId for user $userId');
    return true;
  }
}

// ============================================================================
// Mock Monthly Overview Service (Remove when real API is ready)
// ============================================================================

class MockMonthlyOverviewService {

  static Future<MonthlyOverview?> getMockMonthlyOverview({
    required int userId,
    required int year,
    required int month,
  }) async {
    await Future.delayed(Duration(milliseconds: 800));
    
    final monthNames = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return MonthlyOverview(
      year: year,
      month: month,
      receiptUploads: 18,
      totalProducts: 156,
      totalSpent: 487.50,
      monthName: monthNames[month],
    );
  }

  static Future<MonthlypurchaseSummary?> getMockpurchaseSummary({
    required int userId,
    required int year,
    required int month,
  }) async {
    await Future.delayed(Duration(milliseconds: 600));
    
    final categories = [
      CategorySummary(
        categoryName: 'Fruits & Vegetables',
        productCount: 45,
        percentage: 35.0,
        totalSpent: 170.60,
        iconName: '🥬',
      ),
      CategorySummary(
        categoryName: 'Protein Foods',
        productCount: 32,
        percentage: 25.0,
        totalSpent: 121.90,
        iconName: '🥩',
      ),
      CategorySummary(
        categoryName: 'Grains & Cereals',
        productCount: 28,
        percentage: 20.0,
        totalSpent: 97.50,
        iconName: '🌾',
      ),
      CategorySummary(
        categoryName: 'Snacks & Drinks',
        productCount: 18,
        percentage: 15.0,
        totalSpent: 73.10,
        iconName: '🍿',
      ),
      CategorySummary(
        categoryName: 'Others',
        productCount: 8,
        percentage: 5.0,
        totalSpent: 24.40,
        iconName: '📦',
      ),
    ];

    final popularProducts = [
      PopularProduct(
        productName: 'Organic Milk',
        purchaseCount: 8,
        barcode: '1234567890',
        averagePrice: 4.50,
        categoryName: 'Protein Foods',
      ),
      PopularProduct(
        productName: 'Whole Wheat Bread',
        purchaseCount: 6,
        barcode: '2345678901',
        averagePrice: 3.20,
        categoryName: 'Grains & Cereals',
      ),
      PopularProduct(
        productName: 'Greek Yogurt',
        purchaseCount: 5,
        barcode: '3456789012',
        averagePrice: 2.80,
        categoryName: 'Protein Foods',
      ),
    ];

    return MonthlypurchaseSummary(
      categoryBreakdown: categories,
      popularProducts: popularProducts,
      spendingByCategory: {
        'Fruits & Vegetables': 170.60,
        'Protein Foods': 121.90,
        'Grains & Cereals': 97.50,
        'Snacks & Drinks': 73.10,
        'Others': 24.40,
      },
      uniqueProducts: 156,
      averageReceiptValue: 27.08,
    );
  }

  static Future<MonthlyNutritionInsights?> getMockNutritionInsights({
    required int userId,
    required int year,
    required int month,
  }) async {
    await Future.delayed(Duration(milliseconds: 700));
    
    final nutritionBreakdown = {
      'Protein': NutritionMetric(
        currentValue: 96.0,
        targetValue: 120.0,
        percentage: 80.0,
        unit: 'g',
        status: 'good',
      ),
      'Sugar': NutritionMetric(
        currentValue: 45.0,
        targetValue: 50.0,
        percentage: 90.0,
        unit: 'g',
        status: 'good',
      ),
      'Fat': NutritionMetric(
        currentValue: 67.5,
        targetValue: 90.0,
        percentage: 75.0,
        unit: 'g',
        status: 'good',
      ),
      'Carbohydrates': NutritionMetric(
        currentValue: 180.0,
        targetValue: 300.0,
        percentage: 60.0,
        unit: 'g',
        status: 'low',
      ),
    };

    return MonthlyNutritionInsights(
      nutritionBreakdown: nutritionBreakdown,
      overallNutritionScore: 78.5,
      nutritionGoalsStatus: {
        'Protein': 'Close to Target',
        'Sugar': 'Well Controlled',
        'Fat': 'Good Balance',
        'Carbohydrates': 'Need to Increase',
      },
    );
  }

  static Future<List<HealthInsight>?> getMockHealthInsights({
    required int userId,
    required int year,
    required int month,
  }) async {
    await Future.delayed(Duration(milliseconds: 400));
    
    return [
      HealthInsight(
        id: 'insight_001',
        title: 'Protein Intake Performance is Good',
        description: 'Your protein intake this month reached 80% of the target. Continue maintaining your current dietary pattern.',
        category: 'nutrition',
        priority: 'medium',
        iconName: '💪',
        createdAt: DateTime.now(),
      ),
      HealthInsight(
        id: 'insight_002',
        title: 'Consider Increasing Complex Carbohydrates',
        description: 'Your carbohydrate intake is low. Consider adding whole grains and oats for complex carbohydrates.',
        category: 'nutrition',
        priority: 'high',
        iconName: '🌾',
        createdAt: DateTime.now(),
      ),
      HealthInsight(
        id: 'insight_003',
        title: 'Monitor Snack Consumption',
        description: 'Snack consumption accounts for 15% this month. Try to keep it below 10% for a healthier diet.',
        category: 'spending',
        priority: 'medium',
        iconName: '🍪',
        createdAt: DateTime.now(),
      ),
      HealthInsight(
        id: 'insight_004',
        title: 'Sugar Control is Good',
        description: 'Your sugar intake this month is well controlled within reasonable range, reaching 90% of target. Keep it up.',
        category: 'nutrition',
        priority: 'low',
        iconName: '🍯',
        createdAt: DateTime.now(),
      ),
    ];
  }
}

// ============================================================================
// Barcode Scanning and Receipt Upload API 
// ============================================================================

Future<ProductAnalysis> fetchProductByBarcode(String barcode) async {
  final response = await http.get(Uri.parse('$baseUrl/product/$barcode'));

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body)['data'];
    
    return ProductAnalysis(
      name: json['productName'] ?? 'Unknown',
      imageUrl: json['imageUrl'] ?? 'https://via.placeholder.com/300x200',
      ingredients: _parseList(json['ingredients']),
      detectedAllergens: _parseList(json['allergens']),
    );
  } else {
    throw Exception('Product not found');
  }
}

// Helper
List<String> _parseList(dynamic value) {
  if (value == null) return [];
  if (value is String) {
    return value.split(',').map((e) => e.trim()).toList();
  }
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return [];
}

Future<Map<String, dynamic>> uploadReceiptImage(XFile imageFile, int userId) async {
  final uri = Uri.parse('$baseUrl/ocr/scan');

  final bytes = await imageFile.readAsBytes();
  final request = http.MultipartRequest('POST', uri)
    ..fields['userId'] = userId.toString()
    ..files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: imageFile.name,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

  final response = await http.Response.fromStream(await request.send());

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to upload receipt: ${response.statusCode}');
  }
}

/// 获取商品推荐
Future<RecommendationResponse> getProductRecommendations({
  required int userId,
  required String productBarcode,
}) async {
  final uri = Uri.parse('$recommendationBaseUrl/recommendations/barcode');
  
  final requestBody = {
    'userId': userId.toString(),
    'productBarcode': productBarcode,
  };

  // 保留一些调试信息，便于开发调试
  print('Calling recommendation API: $uri');
  print('Request: ${jsonEncode(requestBody)}');

  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(requestBody),
  ).timeout(
    const Duration(seconds: 30),
    onTimeout: () => throw Exception('推荐服务响应较慢，请稍等'),
  );

  print('Recommendation response: ${response.statusCode}');

  if (response.statusCode == 200) {
    // =================================================================
    // =============  在这里添加调试代码  ===============
    // =================================================================
    print('--- RAW JSON RESPONSE FROM SERVER ---');
    print(response.body);
    print('--- END OF RAW JSON ---');
    // =================================================================
    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    return RecommendationResponse.fromJson(responseData);
  } else {
    throw Exception('Failed to get recommendations: ${response.statusCode}');
  }
}