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
import 'api_config.dart';
import 'api_real.dart';

// Custom Exception Classes for better error handling
class UserNotFoundException implements Exception {
  final String message;
  UserNotFoundException([this.message = 'User not found']);
  
  @override
  String toString() => message;
}

class AuthenticationException implements Exception {
  final String message;
  AuthenticationException([this.message = 'Authentication failed']);
  
  @override
  String toString() => message;
}

class ConflictException implements Exception {
  final String message;
  ConflictException([this.message = 'Resource conflict']);
  
  @override
  String toString() => message;
}

class InternalServerException implements Exception {
  final String message;
  InternalServerException([this.message = 'Internal server error']);
  
  @override
  String toString() => message;
}

class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'Server error']);
  
  @override
  String toString() => message;
}

class ApiService {
  // ============================================================================
  // User Authentication
  // ============================================================================
  
  static Future<bool> registerUser({
    required String userName,
    required String passwordHash,
    required String email,
    required String gender,
    required double heightCm,
    required double weightKg,
  }) async {
    return RealApiService.registerUser(
      userName: userName,
      passwordHash: passwordHash,
      email: email,
      gender: gender,
      heightCm: heightCm,
      weightKg: weightKg,
    );
  }

  static Future<Map<String, dynamic>?> loginUser({
    required String userName,
    required String passwordHash,
  }) async {
    return RealApiService.loginUser(
      userName: userName,
      passwordHash: passwordHash,
    );
  }

  // ============================================================================
  // User Profile APIs
  // ============================================================================
  
  static Future<Map<String, dynamic>?> getUserProfile({required int userId}) async {
    return RealApiService.getUserProfile(userId: userId);
  }

  static Future<bool> updateUserProfile({
    required int userId,
    required Map<String, dynamic> userData,
  }) async {
    return RealApiService.updateUserProfile(userId: userId, userData: userData);
  }

  // ============================================================================
  // User Allergen APIs
  // ============================================================================
  
  static Future<List<Map<String, dynamic>>?> getUserAllergens({required int userId}) async {
    return RealApiService.getUserAllergens(userId: userId);
  }

  static Future<bool> addUserAllergen({
    required int userId,
    required int allergenId,
    required String severityLevel,
    required String notes,
  }) async {
    return RealApiService.addUserAllergen(
      userId: userId,
      allergenId: allergenId,
      severityLevel: severityLevel,
      notes: notes,
    );
  }

  static Future<bool> removeUserAllergen({
    required int userId,
    required int allergenId,
  }) async {
    return RealApiService.removeUserAllergen(
      userId: userId,
      allergenId: allergenId,
    );
  }

  // ============================================================================
  // Barcode Scanning and Receipt Upload
  // ============================================================================
  
  static Future<ProductAnalysis> fetchProductByBarcode(String barcode, int userId) async {
    return RealApiService.fetchProductByBarcode(barcode, userId);
  }

  static Future<Map<String, dynamic>> uploadReceiptImage(XFile imageFile, int userId) async {
    return RealApiService.uploadReceiptImage(imageFile, userId);
  }

  // ============================================================================
  // Monthly Overview APIs
  // ============================================================================

  static Future<MonthlyOverview?> getMonthlyOverview({
    required int userId,
    required int year,
    required int month,
  }) async {
    // 暂时返回null，等待后端实现
    return null;
  }

  static Future<MonthlypurchaseSummary?> getMonthlypurchaseSummary({
    required int userId,
    required int year,
    required int month,
  }) async {
    // 暂时返回null，等待后端实现
    return null;
  }

  static Future<MonthlyNutritionInsights?> getMonthlyNutritionInsights({
    required int userId,
    required int year,
    required int month,
  }) async {
    // 暂时返回null，等待后端实现
    return null;
  }

  static Future<MonthlyComparison?> getMonthlyComparison({
    required int userId,
    required int currentYear,
    required int currentMonth,
    required int previousYear,
    required int previousMonth,
  }) async {
    // 暂时返回null，等待后端实现
    return null;
  }

  static Future<List<HealthInsight>?> getMonthlyHealthInsights({
    required int userId,
    required int year,
    required int month,
  }) async {
    // 暂时返回null，等待后端实现
    return null;
  }

  // ============================================================================
  // History Record APIs
  // ============================================================================

  static Future<HistoryResponse?> getUserHistory({
    required int userId,
    int page = 1,
    int limit = 20,
    String? searchKeyword,
    String? filterType,
    String? dateRange,
  }) async {
    // 暂时返回null，等待后端实现
    return null;
  }

  static Future<HistoryDetail?> getHistoryDetail({
    required int userId,
    required String historyId,
  }) async {
    // 暂时返回null，等待后端实现
    return null;
  }

  static Future<bool> deleteHistoryRecord({
    required int userId,
    required String historyId,
  }) async {
    // 暂时返回false，等待后端实现
    return false;
  }

  static Future<HistoryStatistics?> getHistoryStatistics({
    required int userId,
    String? dateRange,
  }) async {
    // 暂时返回null，等待后端实现
    return null;
  }

  // ============================================================================
  // Sugar Tracking APIs
  // ============================================================================

  static Future<DailySugarIntake?> getDailySugarIntake({required int userId}) async {
    // 暂时返回null，等待后端实现
    return null;
  }

  static Future<bool> addSugarIntakeRecord({
    required int userId,
    required String foodName,
    required double sugarAmount,
    DateTime? time,
  }) async {
    // 暂时返回false，等待后端实现
    return false;
  }

  static Future<SugarIntakeHistory?> getSugarIntakeHistory({
    required int userId,
    int days = 7,
  }) async {
    // 暂时返回null，等待后端实现
    return null;
  }

  static Future<SugarGoal?> getSugarGoal({required int userId}) async {
    // 暂时返回null，等待后端实现
    return null;
  }

  static Future<bool> setSugarGoal({
    required int userId,
    required double dailyGoalMg,
    required double weeklyGoalMg,
  }) async {
    // 暂时返回false，等待后端实现
    return false;
  }

  static Future<bool> deleteSugarIntakeRecord({
    required int userId,
    required String recordId,
  }) async {
    // 暂时返回false，等待后端实现
    return false;
  }
}