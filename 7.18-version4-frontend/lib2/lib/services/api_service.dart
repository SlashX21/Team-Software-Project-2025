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
      final response = await http.post(
        Uri.parse('$baseUrl/user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userName': userName,
          'passwordHash': passwordHash,
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
        body: jsonEncode({
          'userName': userName,
          'passwordHash': passwordHash,
        }),
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
  // 历史记录管理接口
  // ============================================================================

  /// 获取用户历史记录
  Future<List<Map<String, dynamic>>?> getHistory(
    int userId, {
    int page = 1,
    int limit = 20,
    String? search,
    String? type,
    String? range,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null) 'search': search,
        if (type != null) 'type': type,
        if (range != null) 'range': range,
      };
      
      final uri = Uri.parse('$baseUrl/user/$userId/history').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']['items']);
      }
      return null;
    } catch (e) {
      print('GetHistory error: $e');
      return null;
    }
  }

  /// 获取历史记录详情
  Future<Map<String, dynamic>?> getHistoryDetail(int userId, String historyId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/history/$historyId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('GetHistoryDetail error: $e');
      return null;
    }
  }

  /// 删除历史记录
  Future<bool> deleteHistory(int userId, String historyId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/user/$userId/history/$historyId'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('DeleteHistory error: $e');
      return false;
    }
  }

  /// 获取历史统计数据
  Future<Map<String, dynamic>?> getHistoryStatistics(int userId, {String period = 'month'}) async {
    try {
      final queryParams = {'period': period};
      final uri = Uri.parse('$baseUrl/user/$userId/history/statistics').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('GetHistoryStatistics error: $e');
      return null;
    }
  }

  /// 保存扫描历史记录
  Future<int?> saveScanHistory({
    required int userId,
    required String barcode,
    required String scanTime,
    String? location,
    bool? allergenDetected,
    String? actionTaken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/history'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'barcode': barcode,
          'scanTime': scanTime,
          if (location != null) 'location': location,
          if (allergenDetected != null) 'allergenDetected': allergenDetected,
          if (actionTaken != null) 'actionTaken': actionTaken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['scanId'];
      }
      return null;
    } catch (e) {
      print('SaveScanHistory error: $e');
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
  Future<Map<String, dynamic>?> getDailySugarTracking(int userId, String date) async {
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
    required String mealType,
    String? productBarcode,
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
          'mealType': mealType,
          if (productBarcode != null) 'productBarcode': productBarcode,
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
  Future<Map<String, dynamic>?> getSugarHistoryStats(int userId, {String period = 'week'}) async {
    try {
      final queryParams = {'period': period};
      final uri = Uri.parse('$baseUrl/user/$userId/sugar-tracking/history').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: {'Content-Type': 'application/json'});

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
  Future<Map<String, dynamic>?> setSugarGoal(int userId, double dailyGoalMg) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/$userId/sugar-tracking/goal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'dailyGoalMg': dailyGoalMg,
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

  /// 获取月度糖分统计
  Future<Map<String, dynamic>?> getMonthlySugarStats(int userId, String month) async {
    try {
      final queryParams = {'month': month};
      final uri = Uri.parse('$baseUrl/sugar-tracking/$userId/monthly').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('GetMonthlySugarStats error: $e');
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
      final uri = Uri.parse('$baseUrl/product/search').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: {'Content-Type': 'application/json'});

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
      final queryParams = {
        'page': page.toString(),
        'size': size.toString(),
      };
      final uri = Uri.parse('$baseUrl/product/category/$category').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: {'Content-Type': 'application/json'});

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
      if (maxCalories != null) queryParams['maxCalories'] = maxCalories.toString();
      if (maxSugar != null) queryParams['maxSugar'] = maxSugar.toString();
      if (minProtein != null) queryParams['minProtein'] = minProtein.toString();

      final uri = Uri.parse('$baseUrl/product/filter').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: {'Content-Type': 'application/json'});

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

      final uri = Uri.parse('$baseUrl/user/$userId/product-preferences').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: {'Content-Type': 'application/json'});

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
      final response = await http.post(
        Uri.parse('$recommendationBaseUrl/recommendations/barcode'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'productBarcode': barcode,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('GetBarcodeRecommendation error: $e');
      return null;
    }
  }

  /// 小票分析推荐
  Future<Map<String, dynamic>?> getReceiptAnalysis({
    required int userId,
    required List<Map<String, dynamic>> purchasedItems,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$recommendationBaseUrl/recommendations/receipt'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'purchasedItems': purchasedItems,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('GetReceiptAnalysis error: $e');
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
        body: jsonEncode({
          'barcode': barcode,
        }),
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
}