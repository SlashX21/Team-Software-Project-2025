class ApiConfig {
  static const bool useMockData = false;
  
  // Different service endpoints
  static const String hostIp = '10.0.2.2'; // 手机/模拟器调试用
  // static const String hostIp = 'localhost'; // Web端（Chrome）本地测试用

  static String get springBootBaseUrl => 'http://$hostIp:8080';
  static String get ocrBaseUrl => 'http://$hostIp:8080';
  static String get recommendationBaseUrl => 'http://$hostIp:8080';
  
  // For backward compatibility, keep original baseUrl pointing to main backend
  // static const String baseUrl = springBootBaseUrl; // 原始配置，供Chrome/Web端使用
  // static const String baseUrl = "http://127.0.0.1:8080"; // Web端（Chrome）本地测试用
  // static const String baseUrl = "http://172.18.68.91:8080"; // 手机/模拟器调试用
  static String get baseUrl => springBootBaseUrl;
  
  // Timeout configuration - optimized for demo
  static const Duration defaultTimeout = Duration(seconds: 8);
  static const Duration uploadTimeout = Duration(seconds: 45);
  static const Duration ocrTimeout = Duration(seconds: 20);
  static const Duration recommendationTimeout = Duration(seconds: 15);
  static const Duration productFetchTimeout = Duration(seconds: 10);
  
  // Retry configuration
  static const int maxRetries = 2;
  static const Duration retryDelay = Duration(milliseconds: 1500);
  
  // Demo optimization settings
  static const bool enableQuickMode = true;
  static const bool showDetailedProgress = true;
  static const bool enableFallbackMode = true;
  
  // API endpoint construction methods
  static String getOcrUrl(String path) => '$ocrBaseUrl$path';
  static String getRecommendationUrl(String path) => '$recommendationBaseUrl$path';
  static String getSpringBootUrl(String path) => '$springBootBaseUrl$path';
}