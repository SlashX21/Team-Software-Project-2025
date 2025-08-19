import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../domain/entities/history_response.dart';
import '../domain/entities/history_detail.dart';
import '../domain/entities/daily_sugar_intake.dart';
import '../domain/entities/sugar_contributor.dart';
import '../domain/entities/sugar_intake_history.dart';
import '../domain/entities/sugar_goal.dart';
import '../domain/entities/monthly_overview.dart';
import '../domain/entities/product_analysis.dart';
import '../domain/entities/recommendation_response.dart';
import 'api_config.dart';

// Custom Exception Classes for better error handling
class UserNotFoundException implements Exception {
  final String message;
  UserNotFoundException([this.message = '用户不存在']);
}

class AuthenticationException implements Exception {
  final String message;
  AuthenticationException([this.message = '认证失败']);
}

class ConflictException implements Exception {
  final String message;
  ConflictException([this.message = '数据冲突']);
}

class InternalServerException implements Exception {
  final String message;
  InternalServerException([this.message = '服务器内部错误']);
}

class ServerException implements Exception {
  final String message;
  ServerException([this.message = '服务器错误']);
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String baseUrl = ApiConfig.springBootBaseUrl;
  final String recommendationBaseUrl = ApiConfig.recommendationBaseUrl;

  // ============================================================================
  // 用户管理接口
  // ============================================================================

  /// 用户注册
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
      final requestBody = {
        'userName': userName,
        'passwordHash': passwordHash,
        if (email != null) 'email': email,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (age != null) 'age': age,
        if (gender != null) 'gender': gender,
        if (height != null) 'heightCm': height,
        if (weight != null) 'weightKg': weight,
        if (activityLevel != null) 'activityLevel': activityLevel,
        if (goal != null) 'nutritionGoal': goal,
      };

      print('Registration request body: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('RegisterUser error: $e');
      return null;
    }
  }

  /// 用户登录
  Future<Map<String, dynamic>?> loginUser({
    required String userName,
    required String passwordHash,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userName': userName, 'passwordHash': passwordHash}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('LoginUser error: $e');
      return null;
    }
  }

  /// 获取用户信息
  Future<Map<String, dynamic>?> getUser(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('GetUser error: $e');
      return null;
    }
  }

  /// 更新用户信息
  Future<Map<String, dynamic>?> updateUser({
    required int userId,
    String? userName,
    String? passwordHash,
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
      final response = await http.put(
        Uri.parse('$baseUrl/user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          if (userName != null) 'userName': userName,
          if (passwordHash != null) 'passwordHash': passwordHash,
          if (email != null) 'email': email,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
          if (age != null) 'age': age,
          if (gender != null) 'gender': gender,
          if (height != null) 'height': height,
          if (weight != null) 'weight': weight,
          if (activityLevel != null) 'activityLevel': activityLevel,
          if (goal != null) 'goal': goal,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('UpdateUser error: $e');
      return null;
    }
  }


  // ============================================================================
  // 过敏原管理接口
  // ============================================================================

  /// 获取用户过敏原列表
  Future<Map<String, dynamic>?> getUserAllergens(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/allergens'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('GetUserAllergens error: $e');
      return null;
    }
  }

  /// 添加用户过敏原
  Future<Map<String, dynamic>?> addUserAllergen({
    required int userId,
    required int allergenId,
    required String severityLevel,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/$userId/allergens'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'allergenId': allergenId,
          'severityLevel': severityLevel,
          if (notes != null) 'notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('AddUserAllergen error: $e');
      return null;
    }
  }

  /// 删除用户过敏原
  Future<bool> deleteUserAllergen(int userId, int userAllergenId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/user/$userId/allergens/$userAllergenId'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('DeleteUserAllergen error: $e');
      return false;
    }
  }

  /// 获取所有过敏原字典
  Future<Map<String, dynamic>?> getAllAllergens() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/allergens'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('GetAllAllergens error: $e');
      return null;
    }
  }

  // ============================================================================
  // 糖分追踪接口
  // ============================================================================

  /// 获取每日糖分数据
  Future<Map<String, dynamic>?> getDailySugarTracking(
    int userId,
    String date,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/sugar-tracking/daily/$date'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('GetDailySugarTracking error: $e');
      return null;
    }
  }

  /// 添加糖分记录
  Future<Map<String, dynamic>?> addSugarRecord({
    required int userId,
    required String foodName,
    required double sugarAmount,
    required double quantity,
    String? notes,
    DateTime? consumedAt,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/$userId/sugar-tracking/record'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'foodName': foodName,
          'sugarAmountMg': sugarAmount,
          'quantity': quantity,
          if (notes != null) 'notes': notes,
          if (consumedAt != null) 'consumedAt': consumedAt.toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('AddSugarRecord error: $e');
      return null;
    }
  }

  /// 获取糖分历史统计
  Future<Map<String, dynamic>?> getSugarHistoryStats(
    int userId, {
    String period = 'week',
  }) async {
    try {
      final queryParams = {'period': period};
      final uri = Uri.parse(
        '$baseUrl/user/$userId/sugar-tracking/history',
      ).replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('GetSugarHistoryStats error: $e');
      return null;
    }
  }

  /// 获取糖分目标
  Future<Map<String, dynamic>?> getSugarGoal(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/sugar-tracking/goal'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('GetSugarGoal error: $e');
      return null;
    }
  }

  /// 设置糖分目标
  Future<Map<String, dynamic>?> setSugarGoal(
    int userId,
    double dailyGoalMg,
    String? goalLevel,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/$userId/sugar-tracking/goal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'dailyGoalMg': dailyGoalMg,
          if (goalLevel != null) 'goalLevel': goalLevel,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('SetSugarGoal error: $e');
      return null;
    }
  }

  /// 删除糖分记录
  Future<bool> deleteSugarRecord(int userId, int recordId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/user/$userId/sugar-tracking/record/$recordId'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('DeleteSugarRecord error: $e');
      return false;
    }
  }

  /// 获取月度糖分日历数据
  Future<Map<String, dynamic>?> getMonthlySugarCalendar(
    int userId,
    int year,
    int month,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/user/$userId/sugar-tracking/monthly-calendar/$year/$month',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('GetMonthlySugarCalendar error: $e');
      return null;
    }
  }

  /// 获取每日糖分汇总数据
  Future<Map<String, dynamic>?> getDailySugarSummary(
    int userId,
    String date,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/sugar-tracking/daily-summary/$date'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('GetDailySugarSummary error: $e');
      return null;
    }
  }

  /// 获取指定日期的详细摄入记录
  Future<List<Map<String, dynamic>>?> getDailySugarDetails(
    int userId,
    String date,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/sugar-tracking/daily/$date'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(
          data['data']['topContributors'] ?? [],
        );
      }
      return null;
    } catch (e) {
      print('GetDailySugarDetails error: $e');
      return null;
    }
  }

  /// 重新计算每日汇总数据
  Future<Map<String, dynamic>?> recalculateDailySummary(
    int userId,
    String date,
  ) async {
    try {
      final response = await http.put(
        Uri.parse(
          '$baseUrl/user/$userId/sugar-tracking/daily-summary/$date/recalculate',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('RecalculateDailySummary error: $e');
      return null;
    }
  }

  /// 批量重新计算汇总数据
  Future<Map<String, dynamic>?> recalculateSummaries(
    int userId,
    String startDate,
    String endDate,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/$userId/sugar-tracking/summaries/recalculate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'startDate': startDate, 'endDate': endDate}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('RecalculateSummaries error: $e');
      return null;
    }
  }

  // ============================================================================
  // 用户偏好管理接口
  // ============================================================================

  /// 获取用户偏好
  Future<Map<String, dynamic>?> getUserPreferences(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/preferences'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('GetUserPreferences error: $e');
      return null;
    }
  }

  /// 保存用户偏好
  Future<Map<String, dynamic>?> saveUserPreferences({
    required int userId,
    required Map<String, bool> preferences,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/$userId/preferences'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(preferences),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('SaveUserPreferences error: $e');
      return null;
    }
  }

  /// 更新用户偏好
  Future<Map<String, dynamic>?> updateUserPreferences({
    required int userId,
    required Map<String, bool> preferences,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/$userId/preferences'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(preferences),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('UpdateUserPreferences error: $e');
      return null;
    }
  }

  // ============================================================================
  // 产品管理接口
  // ============================================================================

  /// 获取产品信息
  Future<Map<String, dynamic>?> getProduct(String barcode) async {
    try {
      final url = '$baseUrl/product/$barcode';
      print('🌐 getProduct: Making request to URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 getProduct: Response status code: ${response.statusCode}');
      print('📄 getProduct: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ getProduct: Successfully parsed JSON response');
        print('📦 getProduct: Response data: $data');
        return data['data'];
      } else {
        print('❌ getProduct: Non-200 status code: ${response.statusCode}');
        print('❌ getProduct: Error response body: ${response.body}');
      }
      return null;
    } catch (e) {
      print('❌ getProduct: Exception occurred: $e');
      print('❌ getProduct: Exception type: ${e.runtimeType}');
      return null;
    }
  }

  /// 搜索产品
  Future<Map<String, dynamic>?> searchProducts({
    required String name,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final queryParams = {
        'name': name,
        'page': page.toString(),
        'size': size.toString(),
      };
      final uri = Uri.parse(
        '$baseUrl/product/search',
      ).replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('SearchProducts error: $e');
      return null;
    }
  }

  /// 按类别获取产品
  Future<Map<String, dynamic>?> getProductsByCategory({
    required String category,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final queryParams = {'page': page.toString(), 'size': size.toString()};
      final uri = Uri.parse(
        '$baseUrl/product/category/$category',
      ).replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('GetProductsByCategory error: $e');
      return null;
    }
  }

  /// 按营养成分筛选产品
  Future<Map<String, dynamic>?> filterProductsByNutrition({
    double? maxCalories,
    double? maxSugar,
    double? minProtein,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };
      if (maxCalories != null)
        queryParams['maxCalories'] = maxCalories.toString();
      if (maxSugar != null) queryParams['maxSugar'] = maxSugar.toString();
      if (minProtein != null) queryParams['minProtein'] = minProtein.toString();

      final uri = Uri.parse(
        '$baseUrl/product/filter',
      ).replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('FilterProductsByNutrition error: $e');
      return null;
    }
  }

  // ============================================================================
  // 产品偏好接口
  // ============================================================================

  /// 设置产品偏好
  Future<Map<String, dynamic>?> setProductPreference({
    required int userId,
    required String barcode,
    required String preferenceType,
    String? reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/$userId/product-preferences'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'barCode': barcode,
          'preferenceType': preferenceType,
          if (reason != null) 'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('SetProductPreference error: $e');
      return null;
    }
  }

  /// 获取用户产品偏好
  Future<Map<String, dynamic>?> getUserProductPreferences({
    required int userId,
    String? type,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };
      if (type != null) queryParams['type'] = type;

      final uri = Uri.parse(
        '$baseUrl/user/$userId/product-preferences',
      ).replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('GetUserProductPreferences error: $e');
      return null;
    }
  }

  // ============================================================================
  // 推荐系统接口
  // ============================================================================

  /// 条码推荐
  Future<Map<String, dynamic>?> getBarcodeRecommendation(int userId, String barcode) async {
    try {
      print('🔍 RECOMMENDATION: Starting barcode recommendation request...');
      print('👤 RECOMMENDATION: User ID: $userId');
      print('📦 RECOMMENDATION: Barcode: $barcode');
      print('📍 RECOMMENDATION: Target URL: $recommendationBaseUrl/recommendations/barcode');

      final requestBody = {
        'userId': userId,
        'productBarcode': barcode,
      };
      print('📦 RECOMMENDATION: Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$recommendationBaseUrl/recommendations/barcode'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(ApiConfig.recommendationTimeout);

      print('📡 RECOMMENDATION: Response status code: ${response.statusCode}');
      print('📄 RECOMMENDATION: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ RECOMMENDATION: Successfully parsed response data');
        
        // 处理双重嵌套的data结构 (Spring Boot -> 推荐系统)
        if (data['code'] == 200 && data['data'] != null) {
          final recommendationData = data['data'] as Map<String, dynamic>;
          if (recommendationData['success'] == true) {
            print('🎉 RECOMMENDATION: Recommendation completed successfully');
            return recommendationData; // 返回推荐系统的响应，包括success字段
          } else {
            print('⚠️ RECOMMENDATION: Recommendation failed - ${recommendationData['message']}');
            return recommendationData; // Return the error data for frontend to handle
          }
        } else {
          print('⚠️ RECOMMENDATION: Spring Boot response failed - ${data['message']}');
          return data; // Return the Spring Boot error for frontend to handle
        }
      } else {
        print('❌ RECOMMENDATION: Non-200 status code: ${response.statusCode}');
        print('❌ RECOMMENDATION: Error response body: ${response.body}');
      }
      return null;
    } catch (e) {
      print('❌ RECOMMENDATION: Exception occurred: $e');
      print('❌ RECOMMENDATION: Exception type: ${e.runtimeType}');
      return null;
    }
  }

  /// 小票分析推荐
  Future<Map<String, dynamic>?> getReceiptAnalysis({
    required int userId,
    required List<Map<String, dynamic>> purchasedItems,
  }) async {
    try {
      print('🤖 RECOMMENDATION: Starting receipt analysis...');
      print('👤 RECOMMENDATION: User ID: $userId');
      print('📋 RECOMMENDATION: Items to analyze: $purchasedItems');
      print(
        '📍 RECOMMENDATION: Target URL: $recommendationBaseUrl/recommendations/receipt',
      );

      final requestBody = {'userId': userId, 'purchasedItems': purchasedItems};
      print('📦 RECOMMENDATION: Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$recommendationBaseUrl/recommendations/receipt'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('📡 RECOMMENDATION: Response status code: ${response.statusCode}');
      print('📄 RECOMMENDATION: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ RECOMMENDATION: Successfully parsed response data');
        
        // 处理嵌套的响应结构: data.data.success == true
        final outerData = data['data'];
        if (outerData != null && outerData['success'] == true) {
          print('🎉 RECOMMENDATION: Analysis completed successfully');
          return outerData['data']; // 返回真正的推荐数据
        } else {
          print('⚠️ RECOMMENDATION: Analysis failed - ${outerData?['message'] ?? data['message']}');
          return outerData ?? data; // Return the error data for frontend to handle
        }
      } else {
        print('❌ RECOMMENDATION: Non-200 status code: ${response.statusCode}');
        print('❌ RECOMMENDATION: Error response body: ${response.body}');
      }
      return null;
    } catch (e) {
      print('❌ RECOMMENDATION: Exception occurred: $e');
      print('❌ RECOMMENDATION: Exception type: ${e.runtimeType}');
      return null;
    }
  }
  
  /// 保存条码扫描历史记录
  Future<Map<String, dynamic>?> saveBarcodeHistory({
    required int userId,
    required String barcode,
    required String scanTime,
    String? recommendationId,
    required String llmAnalysis,
    required String recommendedProducts,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/barcode-history'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'barcode': barcode,
          'scanTime': scanTime,
          if (recommendationId != null) 'recommendationId': recommendationId,
          'llmAnalysis': llmAnalysis,
          'recommendedProducts': recommendedProducts,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      print('SaveBarcodeHistory error: $e');
      return null;
    }
  }

  // ============================================================================
  // OCR服务接口
  // ============================================================================

  /// 扫描收据
  Future<Map<String, dynamic>?> scanReceipt(XFile imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/ocr/scan'),
      );

      final imageBytes = await imageFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: imageFile.name,
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);
      request.headers['Content-Type'] = 'multipart/form-data';

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('ScanReceipt error: $e');
      return null;
    }
  }

  /// 条码识别
  Future<Map<String, dynamic>?> recognizeBarcode(String barcode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ocr/barcode'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'barcode': barcode}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('RecognizeBarcode error: $e');
      return null;
    }
  }

  // ============================================================================
  // 扫描历史记录接口
  // ============================================================================

  /// 获取用户扫描历史列表
  Future<Map<String, dynamic>?> getUserScanHistory(
    int userId, {
    int page = 1,
    int limit = 20,
    String? month,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (month != null) queryParams['month'] = month;

      final uri = Uri.parse(
        '$baseUrl/api/barcode-history',
      ).replace(queryParameters: {...queryParams, 'userId': userId.toString()});
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      print('🌐 getUserScanHistory: Making request to URL: $uri');
      print(
        '📡 getUserScanHistory: Response status code: ${response.statusCode}',
      );
      print('📄 getUserScanHistory: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ getUserScanHistory: Successfully parsed JSON response');
        return data['data'];
      } else {
        print(
          '❌ getUserScanHistory: Non-200 status code: ${response.statusCode}',
        );
        print('❌ getUserScanHistory: Error response body: ${response.body}');
      }
      return null;
    } catch (e) {
      print('❌ getUserScanHistory: Exception occurred: $e');
      print('❌ getUserScanHistory: Exception type: ${e.runtimeType}');
      return null;
    }
  }

  /// 获取扫描记录的产品详情
  Future<Map<String, dynamic>?> getProductDetailsFromScanHistory(
    int scanId,
    int userId,
  ) async {
    try {
      final queryParams = {'userId': userId.toString()};
      final uri = Uri.parse(
        '$baseUrl/api/barcode-history/$scanId/details',
      ).replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      print('🌐 getProductDetailsFromScanHistory: Making request to URL: $uri');
      print(
        '📡 getProductDetailsFromScanHistory: Response status code: ${response.statusCode}',
      );
      print(
        '📄 getProductDetailsFromScanHistory: Response body: ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(
          '✅ getProductDetailsFromScanHistory: Successfully parsed JSON response',
        );
        print('🔍 Raw data structure: ${data.toString()}');
        if (data['data'] != null) {
          print('🔍 data[\'data\']: ${data['data'].toString()}');
          if (data['data']['aiAnalysis'] != null) {
            print(
              '🔍 aiAnalysis field: ${data['data']['aiAnalysis'].toString()}',
            );
            print(
              '🔍 aiAnalysis type: ${data['data']['aiAnalysis'].runtimeType}',
            );
          }
        }
        return data['data'];
      } else {
        print(
          '❌ getProductDetailsFromScanHistory: Non-200 status code: ${response.statusCode}',
        );
        print(
          '❌ getProductDetailsFromScanHistory: Error response body: ${response.body}',
        );
      }
      return null;
    } catch (e) {
      print('❌ getProductDetailsFromScanHistory: Exception occurred: $e');
      print(
        '❌ getProductDetailsFromScanHistory: Exception type: ${e.runtimeType}',
      );
      return null;
    }
  }

  /// 通过产品名称搜索产品并获取完整信息（用于成分显示）
  Future<Map<String, dynamic>?> searchProductByName(String productName) async {
    try {
      print('🔍 Searching product by name: $productName');
      
      // Step 1: Search for product by name to get barcode
      final searchUrl = Uri.parse('$baseUrl/product/search').replace(
        queryParameters: {'name': productName},
      );
      
      final searchResponse = await http.get(
        searchUrl,
        headers: {'Content-Type': 'application/json'},
      );

      print('🔍 Search response status: ${searchResponse.statusCode}');
      print('🔍 Search response body: ${searchResponse.body}');

      if (searchResponse.statusCode == 200) {
        final searchData = jsonDecode(searchResponse.body);
        final products = searchData['data']['products'] as List;
        
        if (products.isNotEmpty) {
          // Find the best match (exact name match or first result)
          Map<String, dynamic>? bestMatch;
          for (var product in products) {
            if (product['productName']?.toLowerCase() == productName.toLowerCase()) {
              bestMatch = product;
              break;
            }
          }
          bestMatch ??= products.first;
          
          final barcode = bestMatch!['barcode'];
          print('🔍 Found matching product with barcode: $barcode');
          
          // Step 2: Get full product details including ingredients
          final detailsResponse = await http.get(
            Uri.parse('$baseUrl/product/$barcode'),
            headers: {'Content-Type': 'application/json'},
          );

          print('🔍 Details response status: ${detailsResponse.statusCode}');
          print('🔍 Details response body: ${detailsResponse.body}');

          if (detailsResponse.statusCode == 200) {
            final detailsData = jsonDecode(detailsResponse.body);
            return detailsData['data'];
          }
        } else {
          print('🔍 No products found for: $productName');
        }
      }
      
      return null;
    } catch (e) {
      print('❌ searchProductByName error: $e');
      return null;
    }
  }

  /// 批量将产品名称转换为条形码（用于推荐API）
  Future<List<Map<String, dynamic>>> batchConvertNamesToBarodes(
    List<Map<String, dynamic>> purchasedItems
  ) async {
    print('🔄 Starting batch name-to-barcode conversion for ${purchasedItems.length} items');
    
    List<Map<String, dynamic>> convertedItems = [];
    
    for (int i = 0; i < purchasedItems.length; i++) {
      final item = purchasedItems[i];
      final productName = item['productName'] as String;
      final quantity = item['quantity'] as int;
      
      print('🔄 Converting item ${i + 1}/${purchasedItems.length}: $productName');
      
      try {
        // Search for the product by name to get barcode
        final searchUrl = Uri.parse('$baseUrl/product/search').replace(
          queryParameters: {'name': productName},
        );
        
        final searchResponse = await http.get(
          searchUrl,
          headers: {'Content-Type': 'application/json'},
        );

        String? barcode;
        if (searchResponse.statusCode == 200) {
          final searchData = jsonDecode(searchResponse.body);
          final products = searchData['data']['products'] as List?;
          
          if (products != null && products.isNotEmpty) {
            // Find the best match (exact name match or first result)
            Map<String, dynamic>? bestMatch;
            for (var product in products) {
              if (product['productName']?.toLowerCase() == productName.toLowerCase()) {
                bestMatch = product;
                break;
              }
            }
            bestMatch ??= products.first;
            barcode = bestMatch!['barcode'] ?? bestMatch['barCode'];
            print('✅ Found barcode for "$productName": $barcode');
          }
        }
        
        if (barcode != null && barcode.isNotEmpty) {
          // Successfully found barcode - add to converted items
          convertedItems.add({
            'barcode': barcode,
            'quantity': quantity,
          });
        } else {
          // Could not find barcode - use a default/placeholder approach
          print('⚠️ Could not find barcode for: $productName');
          // Create a fallback barcode based on product name hash
          final fallbackBarcode = 'UNKNOWN_${productName.hashCode.abs()}';
          convertedItems.add({
            'barcode': fallbackBarcode,
            'quantity': quantity,
          });
        }
        
      } catch (e) {
        print('❌ Error converting "$productName": $e');
        // Add fallback item
        final fallbackBarcode = 'ERROR_${productName.hashCode.abs()}';
        convertedItems.add({
          'barcode': fallbackBarcode,
          'quantity': quantity,
        });
      }
    }
    
    print('🔄 Batch conversion completed: ${convertedItems.length} items converted');
    return convertedItems;
  }

  // ============================================================================
  // Loyalty Points API Methods
  // ============================================================================

  /// Check if user exists in loyalty system
  Future<bool> checkUserExists(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.loyaltyBaseUrl}/loyalty/user-exists'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      ).timeout(ApiConfig.loyaltyTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] ?? false;
      }
      return false;
    } catch (e) {
      print('❌ checkUserExists error: $e');
      return false;
    }
  }

  /// Get current points for a user
  Future<int> getUserPoints(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.loyaltyBaseUrl}/loyalty/check-points'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      ).timeout(ApiConfig.loyaltyTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['points'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('❌ getUserPoints error: $e');
      return 0;
    }
  }

  /// Award points to a user (owner only)
  Future<Map<String, dynamic>?> awardPoints(String userId, int amount) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.loyaltyBaseUrl}/loyalty/award-points'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'amount': amount,
        }),
      ).timeout(ApiConfig.loyaltyTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? false,
          'transaction_hash': data['transaction_hash'] ?? '',
          'message': data['message'] ?? '',
        };
      }
      return null;
    } catch (e) {
      print('❌ awardPoints error: $e');
      return null;
    }
  }

  /// Redeem points for a user
  Future<Map<String, dynamic>?> redeemPoints(String userId) async {
    int retryCount = 0;
    const maxRetries = 2;
    
    while (retryCount <= maxRetries) {
      try {
        print('🔄 Attempting to redeem points for user $userId (attempt ${retryCount + 1}/${maxRetries + 1})');
        
        final response = await http.post(
          Uri.parse('${ApiConfig.loyaltyBaseUrl}/loyalty/redeem-points'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': userId}),
        ).timeout(ApiConfig.loyaltyTimeout);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('✅ Points redeemed successfully for user $userId');
          return {
            'user_id': data['user_id'] ?? '',
            'barcode': data['barcode'] ?? '',
            'points_redeemed': data['points_redeemed'] ?? 0,
            'transaction_hash': data['transaction_hash'] ?? '',
          };
        } else {
          print('❌ Redeem points failed with status: ${response.statusCode}');
          return null;
        }
      } catch (e) {
        retryCount++;
        print('❌ Redeem points error (attempt $retryCount): $e');
        
        if (retryCount <= maxRetries) {
          print('🔄 Retrying in ${ApiConfig.retryDelay.inSeconds} seconds...');
          await Future.delayed(ApiConfig.retryDelay);
        } else {
          print('❌ Max retries reached for redeem points');
          rethrow;
        }
      }
    }
    
    return null;
  }

  /// Get contract information
  Future<Map<String, dynamic>?> getContractInfo() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.loyaltyBaseUrl}/loyalty/contract-info'),
      ).timeout(ApiConfig.loyaltyTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'contract_address': data['contract_address'] ?? '',
          'owner': data['owner'] ?? '',
          'network': data['network'] ?? '',
          'block_number': data['block_number'] ?? 0,
          'version': data['version'] ?? '',
        };
      }
      return null;
    } catch (e) {
      print('❌ getContractInfo error: $e');
      return null;
    }
  }
}
