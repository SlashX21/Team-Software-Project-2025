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
import 'api_service.dart';
import 'api_config.dart';

// Use new ApiService instance
final ApiService _apiService = ApiService();

// ============================================================================
// User Authentication APIs
// ============================================================================

Future<Map<String, dynamic>?> registerUser({
  required String userName,
  required String passwordHash,
  String? email,
  String? phoneNumber,
  int? age,
  String? gender,
  double? height,
  double? weight,
  String? activityLevel,
  String? goal,
}) async {
  try {
    return await _apiService.registerUser(
      userName: userName,
      passwordHash: passwordHash,
      email: email,
      phoneNumber: phoneNumber,
      age: age,
      gender: gender,
      height: height,
      weight: weight,
      activityLevel: activityLevel,
      goal: goal,
    );
  } catch (e) {
    print("Error registering user: $e");
    return null;
  }
}

Future<Map<String, dynamic>?> loginUser({
  required String userName,
  required String passwordHash,
}) async {
  try {
    return await _apiService.loginUser(
      userName: userName,
      passwordHash: passwordHash,
    );
  } catch (e) {
    print("Error logging in user: $e");
    return null;
  }
}

// ============================================================================
// User Profile APIs
// ============================================================================

Future<Map<String, dynamic>?> getUser(int userId) async {
  try {
    return await _apiService.getUser(userId);
  } catch (e) {
    print("Error getting user: $e");
    return null;
  }
}

Future<bool> updateUserDetails(int userId, Map<String, dynamic> userData) async {
  try {
    final response = await http.put(
      Uri.parse('${ApiConfig.springBootBaseUrl}/user'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "userId": userId,
        ...userData,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return json['code'] == 200;
    }
  } catch (e) {
    print("Error updating user details: $e");
  }
  return false;
}

// ============================================================================
// Allergen APIs
// ============================================================================

Future<List<Map<String, dynamic>>?> getAllergens() async {
  try {
    final data = await _apiService.getAllAllergens();
    if (data != null && data['allergens'] != null) {
      return List<Map<String, dynamic>>.from(data['allergens']);
    }
    return null;
  } catch (e) {
    print("Error getting allergens: $e");
    return null;
  }
}

Future<List<Map<String, dynamic>>?> getUserAllergens(int userId) async {
  try {
    final data = await _apiService.getUserAllergens(userId);
    if (data != null && data['userAllergens'] != null) {
      return List<Map<String, dynamic>>.from(data['userAllergens']);
    }
    return null;
  } catch (e) {
    print("Error getting user allergens: $e");
    return null;
  }
}

Future<bool> addUserAllergen({
  required int userId,
  required int allergenId,
  required String severityLevel,
  String? notes,
}) async {
  try {
    final result = await _apiService.addUserAllergen(
      userId: userId,
      allergenId: allergenId,
      severityLevel: severityLevel,
      notes: notes,
    );
    return result != null;
  } catch (e) {
    print("Error adding user allergen: $e");
    return false;
  }
}

Future<bool> deleteUserAllergen(int userId, int userAllergenId) async {
  try {
    return await _apiService.deleteUserAllergen(userId, userAllergenId);
  } catch (e) {
    print("Error deleting user allergen: $e");
    return false;
  }
}

// ============================================================================
// Product Analysis APIs
// ============================================================================

Future<ProductAnalysis?> analyzeProduct(String barcode) async {
  try {
    print('🌐 analyzeProduct: Calling getProduct for barcode: $barcode');
    final data = await _apiService.getProduct(barcode);
    print('📋 analyzeProduct: Raw API response: $data');
    
    if (data != null) {
      print('✅ analyzeProduct: Converting to ProductAnalysis');
      final product = ProductAnalysis.fromJson(data);
      print('🎯 analyzeProduct: Product created - ${product.name}');
      return product;
    } else {
      print('❌ analyzeProduct: API returned null data');
    }
    return null;
  } catch (e) {
    print("❌ analyzeProduct: Error analyzing product: $e");
    print("❌ analyzeProduct: Error type: ${e.runtimeType}");
    return null;
  }
}

Future<Map<String, dynamic>?> getProduct(String barcode) async {
  try {
    return await _apiService.getProduct(barcode);
  } catch (e) {
    print("Error getting product: $e");
    return null;
  }
}

Future<Map<String, dynamic>?> searchProducts({
  required String name,
  int page = 0,
  int size = 10,
}) async {
  try {
    return await _apiService.searchProducts(
      name: name,
      page: page,
      size: size,
    );
  } catch (e) {
    print("Error searching products: $e");
    return null;
  }
}

Future<Map<String, dynamic>?> getProductsByCategory({
  required String category,
  int page = 0,
  int size = 10,
}) async {
  try {
    return await _apiService.getProductsByCategory(
      category: category,
      page: page,
      size: size,
    );
  } catch (e) {
    print("Error getting products by category: $e");
    return null;
  }
}

Future<Map<String, dynamic>?> filterProductsByNutrition({
  double? maxCalories,
  double? maxSugar,
  double? minProtein,
  int page = 0,
  int size = 10,
}) async {
  try {
    return await _apiService.filterProductsByNutrition(
      maxCalories: maxCalories,
      maxSugar: maxSugar,
      minProtein: minProtein,
      page: page,
      size: size,
    );
  } catch (e) {
    print("Error filtering products by nutrition: $e");
    return null;
  }
}

// ============================================================================
// Monthly Overview APIs
// ============================================================================

Future<MonthlyOverview?> getMonthlyOverview({
  required int userId,
  required int year,
  required int month,
}) async {
  try {
    // Build monthly overview using historical statistics data
    final historyStats = await _apiService.getHistoryStatistics(userId, period: 'month');
    final sugarStats = await _apiService.getMonthlySugarStats(userId, '$year-${month.toString().padLeft(2, '0')}');
    
    if (historyStats != null) {
      // Build MonthlyOverview object, matching actual class definition
      return MonthlyOverview(
        year: year,
        month: month,
        receiptUploads: historyStats['totalScans'] ?? 0,
        totalProducts: historyStats['totalScans'] ?? 0,
        totalSpent: 0.0, // Default value, as there is no spending data
        monthName: _getMonthName(month),
      );
    }
    return null;
  } catch (e) {
    print("Error getting monthly overview: $e");
    return null;
  }
}

// ============================================================================
// History APIs
// ============================================================================

Future<HistoryResponse?> getUserHistory({
  required int userId,
  int page = 1,
  int limit = 20,
  String? search,
  String? type,
  String? range,
}) async {
  try {
    final items = await _apiService.getHistory(
      userId,
      page: page,
      limit: limit,
      search: search,
      type: type,
      range: range,
    );
    if (items != null) {
      // Convert Map<String, dynamic> to HistoryItem
      final historyItems = items.map((item) => HistoryItem.fromJson(item)).toList();
      return HistoryResponse(
        items: historyItems,
        totalCount: items.length,
        currentPage: page,
        totalPages: (items.length / limit).ceil(),
        hasMore: items.length >= limit,
      );
    }
    return null;
  } catch (e) {
    print("Error getting user history: $e");
    return null;
  }
}

Future<HistoryDetail?> getHistoryDetail(int userId, String historyId) async {
  try {
    final data = await _apiService.getHistoryDetail(userId, historyId);
    if (data != null) {
      return HistoryDetail.fromJson(data);
    }
    return null;
  } catch (e) {
    print("Error getting history detail: $e");
    return null;
  }
}

Future<bool> deleteHistory(int userId, String historyId) async {
  try {
    return await _apiService.deleteHistory(userId, historyId);
  } catch (e) {
    print("Error deleting history: $e");
    return false;
  }
}

Future<HistoryStatistics?> getHistoryStatistics(int userId, {String period = 'month'}) async {
  try {
    final data = await _apiService.getHistoryStatistics(userId, period: period);
    if (data != null) {
      return HistoryStatistics.fromJson(data);
    }
    return null;
  } catch (e) {
    print("Error getting history statistics: $e");
    return null;
  }
}

// ============================================================================
// Sugar Tracking APIs
// ============================================================================

Future<DailySugarIntake?> getDailySugarIntake(int userId, String date) async {
  try {
    final data = await _apiService.getDailySugarTracking(userId, date);
    if (data != null) {
      return DailySugarIntake.fromJson(data);
    }
    return null;
  } catch (e) {
    print("Error getting daily sugar intake: $e");
    return null;
  }
}

Future<bool> addSugarIntakeRecord({
  required int userId,
  required String foodName,
  required double sugarAmount,
  required String mealType,
  String? productBarcode,
  String? notes,
  DateTime? consumedAt,
}) async {
  try {
    final result = await _apiService.addSugarRecord(
      userId: userId,
      foodName: foodName,
      sugarAmount: sugarAmount,
      mealType: mealType,
      productBarcode: productBarcode,
      notes: notes,
      consumedAt: consumedAt,
    );
    return result != null;
  } catch (e) {
    print("Error adding sugar intake record: $e");
    return false;
  }
}

Future<SugarIntakeHistory?> getSugarIntakeHistory(int userId, {String period = 'week'}) async {
  try {
    final data = await _apiService.getSugarHistoryStats(userId, period: period);
    if (data != null) {
      return SugarIntakeHistory.fromJson(data);
    }
    return null;
  } catch (e) {
    print("Error getting sugar intake history: $e");
    return null;
  }
}

Future<SugarGoal?> getSugarGoal(int userId) async {
  try {
    final data = await _apiService.getSugarGoal(userId);
    if (data != null) {
      return SugarGoal.fromJson(data);
    }
    return null;
  } catch (e) {
    print("Error getting sugar goal: $e");
    return null;
  }
}

Future<bool> setSugarGoal(int userId, double dailyGoalMg) async {
  try {
    final result = await _apiService.setSugarGoal(userId, dailyGoalMg);
    return result != null;
  } catch (e) {
    print("Error setting sugar goal: $e");
    return false;
  }
}

Future<bool> deleteSugarIntakeRecord({
  required int userId,
  required int recordId,
}) async {
  try {
    return await _apiService.deleteSugarRecord(userId, recordId);
  } catch (e) {
    print("Error deleting sugar intake record: $e");
    return false;
  }
}

Future<Map<String, dynamic>?> getMonthlySugarStats(int userId, String month) async {
  try {
    return await _apiService.getMonthlySugarStats(userId, month);
  } catch (e) {
    print("Error getting monthly sugar stats: $e");
    return null;
  }
}

// ============================================================================
// Recommendation APIs
// ============================================================================

Future<Map<String, dynamic>?> getBarcodeRecommendation(int userId, String barcode) async {
  try {
    return await _apiService.getBarcodeRecommendation(userId, barcode);
  } catch (e) {
    print("Error getting barcode recommendation: $e");
    return null;
  }
}

Future<Map<String, dynamic>?> getReceiptAnalysis({
  required int userId,
  required List<Map<String, dynamic>> purchasedItems,
}) async {
  try {
    return await _apiService.getReceiptAnalysis(
      userId: userId,
      purchasedItems: purchasedItems,
    );
  } catch (e) {
    print("Error getting receipt analysis: $e");
    return null;
  }
}

// ============================================================================
// OCR Service APIs
// ============================================================================

Future<Map<String, dynamic>?> scanReceipt(XFile imageFile) async {
  try {
    return await _apiService.scanReceipt(imageFile);
  } catch (e) {
    print("Error scanning receipt: $e");
    return null;
  }
}

Future<Map<String, dynamic>?> recognizeBarcode(String barcode) async {
  try {
    return await _apiService.recognizeBarcode(barcode);
  } catch (e) {
    print("Error recognizing barcode: $e");
    return null;
  }
}

// ============================================================================
// User Preferences APIs
// ============================================================================

Future<Map<String, dynamic>?> getUserPreferences(int userId) async {
  try {
    return await _apiService.getUserPreferences(userId);
  } catch (e) {
    print("Error getting user preferences: $e");
    return null;
  }
}

Future<Map<String, dynamic>?> saveUserPreferences({
  required int userId,
  required Map<String, bool> preferences,
}) async {
  try {
    return await _apiService.saveUserPreferences(
      userId: userId,
      preferences: preferences,
    );
  } catch (e) {
    print("Error saving user preferences: $e");
    return null;
  }
}

Future<Map<String, dynamic>?> updateUserPreferences({
  required int userId,
  required Map<String, bool> preferences,
}) async {
  try {
    return await _apiService.updateUserPreferences(
      userId: userId,
      preferences: preferences,
    );
  } catch (e) {
    print("Error updating user preferences: $e");
    return null;
  }
}

// ============================================================================
// Product Preferences APIs
// ============================================================================

Future<Map<String, dynamic>?> setProductPreference({
  required int userId,
  required String barcode,
  required String preferenceType,
  String? reason,
}) async {
  try {
    return await _apiService.setProductPreference(
      userId: userId,
      barcode: barcode,
      preferenceType: preferenceType,
      reason: reason,
    );
  } catch (e) {
    print("Error setting product preference: $e");
    return null;
  }
}

Future<Map<String, dynamic>?> getUserProductPreferences({
  required int userId,
  String? type,
  int page = 0,
  int size = 10,
}) async {
  try {
    return await _apiService.getUserProductPreferences(
      userId: userId,
      type: type,
      page: page,
      size: size,
    );
  } catch (e) {
    print("Error getting user product preferences: $e");
    return null;
  }
}

// ============================================================================
// Helper function
// ============================================================================

String _getMonthName(int month) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return months[month - 1];
}

// ============================================================================
// Compatibility method - maintain compatibility with existing code
// ============================================================================

/// Get user details (compatibility method)
Future<Map<String, dynamic>?> getUserDetails(int userId) async {
  return await getUser(userId);
}

/// Remove user allergen (compatibility method)
Future<bool> removeUserAllergen(int userId, int userAllergenId) async {
  return await deleteUserAllergen(userId, userAllergenId);
}

/// Get product info and return ProductAnalysis object (compatibility method)
Future<ProductAnalysis> fetchProductByBarcode(String barcode, int userId) async {
  try {
    print('🔍 API: Fetching product with barcode: $barcode, userId: $userId');
    final product = await analyzeProduct(barcode);
    print('📦 API: Product result - ${product?.name ?? 'null'}');
    
    if (product != null) {
      // 保存扫描历史
      if (userId > 0) {
        print('💾 API: Saving scan history for user $userId');
        await _apiService.saveScanHistory(
          userId: userId,
          barcode: barcode,
          scanTime: DateTime.now().toIso8601String(),
          actionTaken: 'ANALYZE',
          allergenDetected: product.detectedAllergens.isNotEmpty,
        );
      }
      return product;
    }
  } catch (e) {
    print("❌ API: Error fetching product: $e");
    print("❌ API: Error type: ${e.runtimeType}");
    print("❌ API: Error details: ${e.toString()}");
  }
  
  // 返回默认产品分析
  print('⚠️ API: Returning default product analysis for barcode: $barcode');
  return ProductAnalysis(
    name: 'Unknown Product',
    imageUrl: '',
    ingredients: [],
    detectedAllergens: [],
    summary: 'Unable to retrieve product information',
    detailedAnalysis: 'Please check if the barcode is correct',
    actionSuggestions: ['Please enter product information manually'],
  );
}

/// Upload receipt image (compatibility method)
Future<Map<String, dynamic>> uploadReceiptImage(XFile imageFile, int userId) async {
  try {
    final result = await scanReceipt(imageFile);
    
    if (result != null) {
      // 保存扫描历史
      await _apiService.saveScanHistory(
        userId: userId,
        barcode: 'RECEIPT',
        scanTime: DateTime.now().toIso8601String(),
        actionTaken: 'ANALYZE',
        allergenDetected: false,
      );
      return result;
    }
  } catch (e) {
    print("Error uploading receipt: $e");
  }
  
  return {
    'success': false,
    'message': 'Receipt recognition failed',
    'items': [],
  };
}