import 'dart:io';
import 'package:flutter/material.dart';

class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  /// 处理API错误并返回用户友好的错误信息
  ApiErrorResult handleApiError(dynamic error, {String? context}) {
    final errorString = error.toString().toLowerCase();
    
    // 网络连接错误
    if (error is SocketException || errorString.contains('socket')) {
      return ApiErrorResult(
        type: ErrorType.network,
        userMessage: '网络连接失败，请检查网络设置',
        technicalMessage: error.toString(),
        canRetry: true,
        retryDelay: Duration(seconds: 3),
      );
    }
    
    // 超时错误
    if (errorString.contains('timeout')) {
      return ApiErrorResult(
        type: ErrorType.timeout,
        userMessage: '请求超时，服务器响应较慢',
        technicalMessage: error.toString(),
        canRetry: true,
        retryDelay: Duration(seconds: 5),
      );
    }
    
    // HTTP状态码错误
    if (errorString.contains('404') || errorString.contains('not found')) {
      return ApiErrorResult(
        type: ErrorType.notFound,
        userMessage: _getNotFoundMessage(context),
        technicalMessage: error.toString(),
        canRetry: false,
        suggestions: _getNotFoundSuggestions(context),
      );
    }
    
    if (errorString.contains('500') || errorString.contains('server error')) {
      return ApiErrorResult(
        type: ErrorType.serverError,
        userMessage: '服务器暂时无法处理请求，请稍后重试',
        technicalMessage: error.toString(),
        canRetry: true,
        retryDelay: Duration(seconds: 10),
      );
    }
    
    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return ApiErrorResult(
        type: ErrorType.unauthorized,
        userMessage: '需要重新登录',
        technicalMessage: error.toString(),
        canRetry: false,
        actionRequired: 'login',
      );
    }
    
    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return ApiErrorResult(
        type: ErrorType.forbidden,
        userMessage: '没有权限访问此功能',
        technicalMessage: error.toString(),
        canRetry: false,
      );
    }
    
    // 解析错误
    if (errorString.contains('format') || errorString.contains('json') || errorString.contains('parse')) {
      return ApiErrorResult(
        type: ErrorType.parseError,
        userMessage: '数据格式错误，请稍后重试',
        technicalMessage: error.toString(),
        canRetry: true,
        retryDelay: Duration(seconds: 2),
      );
    }
    
    // 通用错误
    return ApiErrorResult(
      type: ErrorType.unknown,
      userMessage: '操作失败，请重试或联系客服',
      technicalMessage: error.toString(),
      canRetry: true,
      retryDelay: Duration(seconds: 5),
    );
  }

  /// 根据上下文获取404错误的用户友好信息
  String _getNotFoundMessage(String? context) {
    switch (context) {
      case 'product':
        return '未找到该产品信息，可能是新产品或条码识别错误';
      case 'user':
        return '用户信息不存在，请重新登录';
      case 'allergens':
        return '过敏原信息暂时无法获取';
      case 'profile':
        return '个人资料暂时无法加载';
      default:
        return '请求的信息不存在';
    }
  }

  /// 根据上下文获取404错误的建议
  List<String> _getNotFoundSuggestions(String? context) {
    switch (context) {
      case 'product':
        return [
          '检查条码是否清晰',
          '尝试重新扫描',
          '手动输入产品信息',
        ];
      case 'allergens':
        return [
          '手动添加过敏原',
          '稍后再试',
          '联系客服更新数据库',
        ];
      case 'profile':
        return [
          '重新登录',
          '检查网络连接',
          '联系客服',
        ];
      default:
        return ['重试操作', '检查网络连接'];
    }
  }

  /// 显示错误SnackBar
  void showErrorSnackBar(
    BuildContext context,
    ApiErrorResult error, {
    VoidCallback? onRetry,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    final snackBar = SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getErrorIcon(error.type),
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  error.userMessage,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (error.suggestions?.isNotEmpty == true) ...[
            SizedBox(height: 8),
            Text(
              '建议：${error.suggestions!.first}',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
      backgroundColor: _getErrorColor(error.type),
      duration: Duration(seconds: error.canRetry ? 6 : 4),
      action: _buildSnackBarAction(error, onRetry, onAction),
      behavior: SnackBarBehavior.floating,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// 构建SnackBar操作按钮
  SnackBarAction? _buildSnackBarAction(
    ApiErrorResult error,
    VoidCallback? onRetry,
    VoidCallback? onAction,
  ) {
    if (error.actionRequired == 'login' && onAction != null) {
      return SnackBarAction(
        label: '登录',
        textColor: Colors.white,
        onPressed: onAction,
      );
    }
    
    if (error.canRetry && onRetry != null) {
      return SnackBarAction(
        label: '重试',
        textColor: Colors.white,
        onPressed: onRetry,
      );
    }
    
    return null;
  }

  /// 获取错误图标
  IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.timeout:
        return Icons.access_time;
      case ErrorType.notFound:
        return Icons.search_off;
      case ErrorType.serverError:
        return Icons.error_outline;
      case ErrorType.unauthorized:
      case ErrorType.forbidden:
        return Icons.lock_outline;
      case ErrorType.parseError:
        return Icons.data_usage;
      default:
        return Icons.warning_amber;
    }
  }

  /// 获取错误颜色
  Color _getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.timeout:
        return Colors.amber;
      case ErrorType.notFound:
        return Colors.blue;
      case ErrorType.serverError:
        return Colors.red;
      case ErrorType.unauthorized:
      case ErrorType.forbidden:
        return Colors.purple;
      default:
        return Colors.red.shade400;
    }
  }

  /// 显示错误对话框
  void showErrorDialog(
    BuildContext context,
    ApiErrorResult error, {
    VoidCallback? onRetry,
    VoidCallback? onAction,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getErrorIcon(error.type), color: _getErrorColor(error.type)),
            SizedBox(width: 8),
            Text('操作失败'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error.userMessage),
            if (error.suggestions?.isNotEmpty == true) ...[
              SizedBox(height: 16),
              Text('解决建议：', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              ...error.suggestions!.map((suggestion) => 
                Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(suggestion)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('关闭'),
          ),
          if (error.canRetry && onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Future.delayed(error.retryDelay ?? Duration.zero, onRetry);
              },
              child: Text('重试'),
            ),
          if (error.actionRequired == 'login' && onAction != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onAction();
              },
              child: Text('前往登录'),
            ),
        ],
      ),
    );
  }
}

/// 错误类型枚举
enum ErrorType {
  network,      // 网络错误
  timeout,      // 超时错误
  notFound,     // 404错误
  serverError,  // 服务器错误
  unauthorized, // 401未授权
  forbidden,    // 403禁止访问
  parseError,   // 解析错误
  unknown,      // 未知错误
}

/// API错误结果
class ApiErrorResult {
  final ErrorType type;
  final String userMessage;
  final String technicalMessage;
  final bool canRetry;
  final Duration? retryDelay;
  final List<String>? suggestions;
  final String? actionRequired;

  ApiErrorResult({
    required this.type,
    required this.userMessage,
    required this.technicalMessage,
    this.canRetry = false,
    this.retryDelay,
    this.suggestions,
    this.actionRequired,
  });

  @override
  String toString() {
    return 'ApiErrorResult(type: $type, userMessage: $userMessage, canRetry: $canRetry)';
  }
}