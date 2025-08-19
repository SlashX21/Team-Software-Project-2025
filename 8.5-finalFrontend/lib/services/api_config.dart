class ApiConfig {
  static const bool useMockData = false;
  
  // Different service endpoints - 只需要注释/取消注释对应行即可切换
  //static const String hostIp = '127.0.0.1'; // Web端本地测试
  static const String hostIp = '20.117.201.3'; // 云测试

  static String get springBootBaseUrl => 'http://$hostIp:8080';
  static String get ocrBaseUrl => 'http://$hostIp:8080';
  static String get recommendationBaseUrl => 'http://$hostIp:8080';
  static String get loyaltyBaseUrl => 'http://$hostIp:8080';


  static String get baseUrl => springBootBaseUrl;
  
  // Timeout configuration - optimized for demo
  static const Duration defaultTimeout = Duration(seconds: 8);
  static const Duration uploadTimeout = Duration(seconds: 45);
  static const Duration ocrTimeout = Duration(seconds: 20);
  static const Duration recommendationTimeout = Duration(seconds: 90);
  static const Duration productFetchTimeout = Duration(seconds: 10);
  static const Duration loyaltyTimeout = Duration(seconds: 60);
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
  static String getLoyaltyUrl(String path) => '$loyaltyBaseUrl$path';
}