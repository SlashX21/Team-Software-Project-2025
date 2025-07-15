import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class NetworkService {
  static NetworkService? _instance;
  static NetworkService get instance => _instance ??= NetworkService._();
  
  NetworkService._();
  
  /// 检查基本网络连接
  static Future<bool> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }
  
  /// 检查所有后端服务的状态
  static Future<Map<String, bool>> checkBackendServices() async {
    final results = <String, bool>{};
    
    // 并行检查所有服务
    final futures = <Future<void>>[
      _checkService('springboot', ApiConfig.springBootBaseUrl).then((status) {
        results['springboot'] = status;
      }),
      _checkService('ocr', ApiConfig.ocrBaseUrl).then((status) {
        results['ocr'] = status;
      }),
      _checkService('recommendation', ApiConfig.recommendationBaseUrl).then((status) {
        results['recommendation'] = status;
      }),
    ];
    
    try {
      await Future.wait(futures).timeout(Duration(seconds: 10));
    } catch (e) {
      print('Backend services check timeout: $e');
    }
    
    return results;
  }
  
  /// 检查单个服务状态
  static Future<bool> _checkService(String serviceName, String baseUrl) async {
    try {
      print('Checking $serviceName service at $baseUrl');
      
      // 解析URL获取host和port
      final uri = Uri.parse(baseUrl);
      final host = uri.host;
      final port = uri.port;
      
      // 尝试TCP连接
      final socket = await Socket.connect(
        host, 
        port, 
        timeout: Duration(seconds: 3),
      );
      socket.destroy();
      
      print('$serviceName service ($host:$port) - TCP connection successful');
      return true;
      
    } catch (e) {
      print('$serviceName service check failed: $e');
      return false;
    }
  }
  
  /// 检查特定服务的HTTP健康状态
  static Future<Map<String, dynamic>> checkServiceHealth() async {
    final healthStatus = <String, dynamic>{};
    
    // 检查Spring Boot健康状态
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.springBootBaseUrl}/user/1'), // 测试一个简单的端点
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));
      
      healthStatus['springboot'] = {
        'status': response.statusCode == 200 || response.statusCode == 404, // 404也说明服务在运行
        'statusCode': response.statusCode,
        'responseTime': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      healthStatus['springboot'] = {
        'status': false,
        'error': e.toString(),
      };
    }
    
    // 检查推荐系统健康状态
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.recommendationBaseUrl}/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 8));
      
      healthStatus['recommendation'] = {
        'status': response.statusCode == 200,
        'statusCode': response.statusCode,
        'responseTime': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      healthStatus['recommendation'] = {
        'status': false,
        'error': e.toString(),
      };
    }
    
    // 检查OCR服务健康状态
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.ocrBaseUrl}/'),
      ).timeout(Duration(seconds: 5));
      
      healthStatus['ocr'] = {
        'status': response.statusCode == 200,
        'statusCode': response.statusCode,
        'responseTime': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      healthStatus['ocr'] = {
        'status': false,
        'error': e.toString(),
      };
    }
    
    return healthStatus;
  }
  
  /// 获取网络诊断信息
  static Future<Map<String, dynamic>> getDiagnosticInfo() async {
    final startTime = DateTime.now();
    
    final diagnostic = <String, dynamic>{
      'timestamp': startTime.toIso8601String(),
      'connectivity': await checkConnectivity(),
      'services': await checkBackendServices(),
      'healthChecks': await checkServiceHealth(),
    };
    
    final endTime = DateTime.now();
    diagnostic['totalCheckTime'] = endTime.difference(startTime).inMilliseconds;
    
    return diagnostic;
  }
  
  /// 打印网络诊断报告
  static Future<void> printDiagnosticReport() async {
    print('=== Network Diagnostic Report ===');
    
    final info = await getDiagnosticInfo();
    
    print('Timestamp: ${info['timestamp']}');
    print('Internet Connectivity: ${info['connectivity']}');
    print('Total Check Time: ${info['totalCheckTime']}ms');
    
    print('\n--- Service Status ---');
    final services = info['services'] as Map<String, bool>;
    services.forEach((service, status) {
      print('$service: ${status ? "✅ Online" : "❌ Offline"}');
    });
    
    print('\n--- Health Checks ---');
    final healthChecks = info['healthChecks'] as Map<String, dynamic>;
    healthChecks.forEach((service, health) {
      final status = health['status'] as bool;
      final statusCode = health['statusCode'];
      print('$service: ${status ? "✅" : "❌"} ${statusCode != null ? "($statusCode)" : ""}');
      
      if (health['error'] != null) {
        print('  Error: ${health['error']}');
      }
    });
    
    print('=== End Report ===\n');
  }
}