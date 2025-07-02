import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 环境配置管理类
/// 从项目根目录的 .env 文件加载配置
class EnvConfig {
  static bool _isInitialized = false;

  /// 初始化环境配置
  /// 从项目根目录加载 .env 文件
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // 从项目根目录加载 .env 文件
      await dotenv.load(fileName: "../../../.env");
      _isInitialized = true;
    } catch (e) {
      print('Warning: Failed to load .env file: $e');
      print('Using fallback configuration');
      _isInitialized = true;
    }
  }

  /// 确保配置已初始化
  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('EnvConfig not initialized. Call EnvConfig.initialize() first.');
    }
  }

  // ============================================
  // API配置
  // ============================================
  
  /// API基础URL
  static String get apiBaseUrl {
    _ensureInitialized();
    return dotenv.env['FLUTTER_API_BASE_URL'] ?? 'http://localhost:8080/api/v1';
  }

  /// 后端服务端口
  static int get backendPort {
    _ensureInitialized();
    return int.tryParse(dotenv.env['BACKEND_PORT'] ?? '8080') ?? 8080;
  }

  /// OCR服务端口
  static int get ocrServicePort {
    _ensureInitialized();
    return int.tryParse(dotenv.env['OCR_SERVICE_PORT'] ?? '8000') ?? 8000;
  }

  /// 推荐服务端口
  static int get recommendationServicePort {
    _ensureInitialized();
    return int.tryParse(dotenv.env['RECOMMENDATION_SERVICE_PORT'] ?? '8001') ?? 8001;
  }

  // ============================================
  // 环境配置
  // ============================================

  /// 当前环境
  static String get environment {
    _ensureInitialized();
    return dotenv.env['FLUTTER_APP_ENV'] ?? 'development';
  }

  /// 是否为开发环境
  static bool get isDevelopment => environment == 'development';

  /// 是否为生产环境
  static bool get isProduction => environment == 'production';

  /// 是否为测试环境
  static bool get isTest => environment == 'test';

  // ============================================
  // 日志配置
  // ============================================

  /// 日志级别
  static String get logLevel {
    _ensureInitialized();
    return dotenv.env['LOG_LEVEL'] ?? 'INFO';
  }

  /// 是否启用调试日志
  static bool get enableDebugLog => isDevelopment || logLevel == 'DEBUG';

  // ============================================
  // API端点配置
  // ============================================

  /// 用户认证相关API
  static String get authApiUrl => '$apiBaseUrl/auth';
  
  /// 产品相关API
  static String get productApiUrl => '$apiBaseUrl/products';
  
  /// 推荐相关API
  static String get recommendationApiUrl => '$apiBaseUrl/recommendations';
  
  /// OCR相关API
  static String get ocrApiUrl => '$apiBaseUrl/ocr';
  
  /// 用户相关API
  static String get userApiUrl => '$apiBaseUrl/users';

  // ============================================
  // 工具方法
  // ============================================

  /// 获取完整的API URL
  static String getFullApiUrl(String endpoint) {
    if (endpoint.startsWith('http')) {
      return endpoint;
    }
    return '$apiBaseUrl${endpoint.startsWith('/') ? '' : '/'}$endpoint';
  }

  /// 打印当前配置（仅在开发环境）
  static void printConfig() {
    if (!isDevelopment) return;
    
    print('=== Grocery Guardian App Configuration ===');
    print('Environment: $environment');
    print('API Base URL: $apiBaseUrl');
    print('Backend Port: $backendPort');
    print('OCR Service Port: $ocrServicePort');
    print('Recommendation Service Port: $recommendationServicePort');
    print('Log Level: $logLevel');
    print('==========================================');
  }

  /// 验证必要的配置项
  static bool validateConfig() {
    try {
      _ensureInitialized();
      
      // 检查必要的配置项
      final requiredConfigs = {
        'API Base URL': apiBaseUrl,
        'Environment': environment,
      };

      for (final entry in requiredConfigs.entries) {
        if (entry.value.isEmpty) {
          print('Error: Missing required config: ${entry.key}');
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Error validating config: $e');
      return false;
    }
  }
}