import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/entities/receipt_history_item.dart';
import '../domain/entities/receipt_detail.dart';
import '../domain/entities/paged_response.dart';
import 'api_config.dart';

class ReceiptHistoryService {
  static final ReceiptHistoryService _instance = ReceiptHistoryService._internal();
  factory ReceiptHistoryService() => _instance;
  ReceiptHistoryService._internal();

  final String baseUrl = ApiConfig.springBootBaseUrl;

  /// Get paginated receipt history for a user
  /// 
  /// [userId] - User ID to fetch receipts for
  /// [page] - Page number (1-based)
  /// [limit] - Number of items per page (default: 10)
  /// 
  /// Returns [PagedResponse<ReceiptHistoryItem>] containing receipt list and pagination info
  Future<PagedResponse<ReceiptHistoryItem>> getReceiptHistory({
    required int userId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/receipt-history')
          .replace(queryParameters: {
        'userId': userId.toString(),
        'page': page.toString(),
        'limit': limit.toString(),
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return PagedResponse.fromJson(
          jsonData,
          (json) => ReceiptHistoryItem.fromJson(json),
        );
      } else {
        throw _handleHttpError(response);
      }
    } catch (e) {
      if (e is ReceiptHistoryException) {
        rethrow;
      }
      throw ReceiptHistoryException('Failed to load receipt history: ${e.toString()}');
    }
  }

  /// Get detailed information for a specific receipt
  /// 
  /// [receiptId] - ID of the receipt to fetch details for
  /// 
  /// Returns [ReceiptDetail] containing all receipt information including
  /// purchased items, LLM analysis, and recommendations
  Future<ReceiptDetail> getReceiptDetails(int receiptId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/receipt-history/$receiptId/details');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ReceiptDetail.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        throw ReceiptNotFoundException('Receipt with ID $receiptId not found');
      } else {
        throw _handleHttpError(response);
      }
    } catch (e) {
      if (e is ReceiptHistoryException) {
        rethrow;
      }
      throw ReceiptHistoryException('Failed to load receipt details: ${e.toString()}');
    }
  }

  /// Get monthly statistics for receipt uploads and scans
  /// 
  /// [userId] - User ID to fetch statistics for
  /// [month] - Month in YYYY-MM format (e.g., "2025-07")
  /// 
  /// Returns [MonthlyStats] containing receipt uploads, scan times, and other metrics
  Future<MonthlyStats> getMonthlyStats({
    required int userId,
    required String month,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/monthly-stats')
          .replace(queryParameters: {
        'userId': userId.toString(),
        'month': month,
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return MonthlyStats.fromJson(jsonData);
      } else {
        throw _handleHttpError(response);
      }
    } catch (e) {
      if (e is ReceiptHistoryException) {
        rethrow;
      }
      throw ReceiptHistoryException('Failed to load monthly stats: ${e.toString()}');
    }
  }

  /// Handle HTTP errors and convert them to appropriate exceptions
  Exception _handleHttpError(http.Response response) {
    switch (response.statusCode) {
      case 400:
        return BadRequestException('Invalid request: ${response.body}');
      case 401:
        return AuthenticationException('Authentication failed');
      case 403:
        return AuthorizationException('Access denied');
      case 404:
        return ReceiptNotFoundException('Receipt not found');
      case 409:
        return ConflictException('Data conflict occurred');
      case 500:
        return InternalServerException('Internal server error');
      case 502:
      case 503:
      case 504:
        return ServiceUnavailableException('Service temporarily unavailable');
      default:
        return ReceiptHistoryException('HTTP ${response.statusCode}: ${response.body}');
    }
  }
}

/// Monthly statistics data class
class MonthlyStats {
  final String month;
  final int receiptUploads;
  final int scanTimes;
  final int totalRecommendations;
  final double averageItemsPerReceipt;

  const MonthlyStats({
    required this.month,
    required this.receiptUploads,
    required this.scanTimes,
    required this.totalRecommendations,
    required this.averageItemsPerReceipt,
  });

  factory MonthlyStats.fromJson(Map<String, dynamic> json) {
    final statistics = json['statistics'] as Map<String, dynamic>;
    return MonthlyStats(
      month: json['month'] as String,
      receiptUploads: statistics['receiptUploads'] as int,
      scanTimes: statistics['scanTimes'] as int,
      totalRecommendations: statistics['totalRecommendations'] as int,
      averageItemsPerReceipt: (statistics['averageItemsPerReceipt'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'statistics': {
        'receiptUploads': receiptUploads,
        'scanTimes': scanTimes,
        'totalRecommendations': totalRecommendations,
        'averageItemsPerReceipt': averageItemsPerReceipt,
      },
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MonthlyStats &&
        other.month == month &&
        other.receiptUploads == receiptUploads &&
        other.scanTimes == scanTimes &&
        other.totalRecommendations == totalRecommendations &&
        other.averageItemsPerReceipt == averageItemsPerReceipt;
  }

  @override
  int get hashCode {
    return month.hashCode ^
        receiptUploads.hashCode ^
        scanTimes.hashCode ^
        totalRecommendations.hashCode ^
        averageItemsPerReceipt.hashCode;
  }

  @override
  String toString() {
    return 'MonthlyStats(month: $month, receiptUploads: $receiptUploads, scanTimes: $scanTimes, totalRecommendations: $totalRecommendations, averageItemsPerReceipt: $averageItemsPerReceipt)';
  }
}

/// Custom exception classes for receipt history operations
class ReceiptHistoryException implements Exception {
  final String message;
  ReceiptHistoryException(this.message);

  @override
  String toString() => 'ReceiptHistoryException: $message';
}

class ReceiptNotFoundException extends ReceiptHistoryException {
  ReceiptNotFoundException(String message) : super(message);
}

class BadRequestException extends ReceiptHistoryException {
  BadRequestException(String message) : super(message);
}

class AuthenticationException extends ReceiptHistoryException {
  AuthenticationException(String message) : super(message);
}

class AuthorizationException extends ReceiptHistoryException {
  AuthorizationException(String message) : super(message);
}

class ConflictException extends ReceiptHistoryException {
  ConflictException(String message) : super(message);
}

class InternalServerException extends ReceiptHistoryException {
  InternalServerException(String message) : super(message);
}

class ServiceUnavailableException extends ReceiptHistoryException {
  ServiceUnavailableException(String message) : super(message);
}