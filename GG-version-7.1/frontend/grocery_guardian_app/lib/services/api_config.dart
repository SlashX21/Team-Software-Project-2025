class ApiConfig {
  static const bool useMockData = false;
  
  // Different service endpoints
  static const String springBootBaseUrl = 'http://localhost:8080';  // Spring Boot backend
  static const String ocrBaseUrl = 'http://localhost:8000';         // OCR system
  static const String recommendationBaseUrl = 'http://localhost:8001'; // Recommendation system
  
  // For backward compatibility, keep original baseUrl pointing to main backend
  static const String baseUrl = springBootBaseUrl;
  
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