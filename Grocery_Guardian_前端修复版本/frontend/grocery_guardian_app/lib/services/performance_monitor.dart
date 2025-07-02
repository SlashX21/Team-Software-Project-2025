import 'dart:io';

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, DateTime> _startTimes = {};
  final Map<String, Duration> _durations = {};
  final List<PerformanceMetric> _metrics = [];

  /// 开始计时
  void startTimer(String operation) {
    _startTimes[operation] = DateTime.now();
    print('⏱️ [PERF] Started: $operation at ${_formatTime(DateTime.now())}');
  }

  /// 结束计时并记录
  Duration endTimer(String operation) {
    final startTime = _startTimes[operation];
    if (startTime == null) {
      print('⚠️ [PERF] No start time found for: $operation');
      return Duration.zero;
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    _durations[operation] = duration;

    final metric = OperationPerformanceMetric(
      operation: operation,
      duration: duration,
      timestamp: endTime,
    );
    _metrics.add(metric);

    print('✅ [PERF] Completed: $operation in ${duration.inMilliseconds}ms');
    
    // 性能警告
    if (duration.inMilliseconds > 3000) {
      print('🚨 [PERF] SLOW OPERATION: $operation took ${duration.inMilliseconds}ms');
    } else if (duration.inMilliseconds > 1000) {
      print('⚠️ [PERF] MODERATE DELAY: $operation took ${duration.inMilliseconds}ms');
    }

    _startTimes.remove(operation);
    return duration;
  }

  /// 记录API调用性能
  void recordApiCall({
    required String endpoint,
    required int statusCode,
    required Duration duration,
    String? errorMessage,
  }) {
    final metric = ApiPerformanceMetric(
      endpoint: endpoint,
      statusCode: statusCode,
      duration: duration,
      timestamp: DateTime.now(),
      errorMessage: errorMessage,
    );
    _metrics.add(metric);

    final statusIcon = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';
    print('$statusIcon [API] $endpoint: ${statusCode} (${duration.inMilliseconds}ms)');
    
    if (errorMessage != null) {
      print('   ❌ Error: $errorMessage');
    }
  }

  /// 记录扫码性能细节
  void recordScanPerformance({
    required String barcode,
    required Duration detectionTime,
    required Duration apiTime,
    required Duration renderTime,
    required Duration totalTime,
    bool success = true,
    String? errorMessage,
  }) {
    final metric = ScanPerformanceMetric(
      barcode: barcode,
      detectionTime: detectionTime,
      apiTime: apiTime,
      renderTime: renderTime,
      totalTime: totalTime,
      success: success,
      timestamp: DateTime.now(),
      errorMessage: errorMessage,
    );
    _metrics.add(metric);

    print('📊 [SCAN] Barcode: $barcode');
    print('   🔍 Detection: ${detectionTime.inMilliseconds}ms');
    print('   🌐 API Call: ${apiTime.inMilliseconds}ms');
    print('   🎨 Render: ${renderTime.inMilliseconds}ms');
    print('   ⏱️ Total: ${totalTime.inMilliseconds}ms');
    
    if (!success && errorMessage != null) {
      print('   ❌ Failed: $errorMessage');
    }
  }

  /// 获取性能报告
  PerformanceReport getReport() {
    final scanMetrics = _metrics.whereType<ScanPerformanceMetric>().toList();
    final apiMetrics = _metrics.whereType<ApiPerformanceMetric>().toList();

    return PerformanceReport(
      scanMetrics: scanMetrics,
      apiMetrics: apiMetrics,
      allMetrics: List.from(_metrics),
    );
  }

  /// 打印性能摘要
  void printSummary() {
    final report = getReport();
    
    print('\n📊 === PERFORMANCE SUMMARY ===');
    
    if (report.scanMetrics.isNotEmpty) {
      final avgScanTime = report.scanMetrics
          .map((m) => m.totalTime.inMilliseconds)
          .reduce((a, b) => a + b) / report.scanMetrics.length;
      final successRate = report.scanMetrics.where((m) => m.success).length / 
          report.scanMetrics.length * 100;
      
      print('🔍 SCANNING:');
      print('   • Average Time: ${avgScanTime.toInt()}ms');
      print('   • Success Rate: ${successRate.toInt()}%');
      print('   • Total Scans: ${report.scanMetrics.length}');
    }

    if (report.apiMetrics.isNotEmpty) {
      final avgApiTime = report.apiMetrics
          .map((m) => m.duration.inMilliseconds)
          .reduce((a, b) => a + b) / report.apiMetrics.length;
      final successfulCalls = report.apiMetrics.where((m) => 
          m.statusCode >= 200 && m.statusCode < 300).length;
      final successRate = successfulCalls / report.apiMetrics.length * 100;
      
      print('🌐 API CALLS:');
      print('   • Average Time: ${avgApiTime.toInt()}ms');
      print('   • Success Rate: ${successRate.toInt()}%');
      print('   • Total Calls: ${report.apiMetrics.length}');
    }
    
    print('=========================\n');
  }

  /// 清理旧数据
  void cleanup({int keepLastMinutes = 30}) {
    final cutoff = DateTime.now().subtract(Duration(minutes: keepLastMinutes));
    _metrics.removeWhere((metric) => metric.timestamp.isBefore(cutoff));
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
           '${time.minute.toString().padLeft(2, '0')}:'
           '${time.second.toString().padLeft(2, '0')}.'
           '${time.millisecond.toString().padLeft(3, '0')}';
  }
}

// 性能指标基类
abstract class PerformanceMetric {
  final DateTime timestamp;
  
  PerformanceMetric({required this.timestamp});
}

// 通用性能指标
class OperationPerformanceMetric extends PerformanceMetric {
  final String operation;
  final Duration duration;

  OperationPerformanceMetric({
    required this.operation,
    required this.duration,
    required DateTime timestamp,
  }) : super(timestamp: timestamp);
}

// API性能指标
class ApiPerformanceMetric extends PerformanceMetric {
  final String endpoint;
  final int statusCode;
  final Duration duration;
  final String? errorMessage;

  ApiPerformanceMetric({
    required this.endpoint,
    required this.statusCode,
    required this.duration,
    required DateTime timestamp,
    this.errorMessage,
  }) : super(timestamp: timestamp);
}

// 扫码性能指标
class ScanPerformanceMetric extends PerformanceMetric {
  final String barcode;
  final Duration detectionTime;
  final Duration apiTime;
  final Duration renderTime;
  final Duration totalTime;
  final bool success;
  final String? errorMessage;

  ScanPerformanceMetric({
    required this.barcode,
    required this.detectionTime,
    required this.apiTime,
    required this.renderTime,
    required this.totalTime,
    required this.success,
    required DateTime timestamp,
    this.errorMessage,
  }) : super(timestamp: timestamp);
}

// 性能报告
class PerformanceReport {
  final List<ScanPerformanceMetric> scanMetrics;
  final List<ApiPerformanceMetric> apiMetrics;
  final List<PerformanceMetric> allMetrics;

  PerformanceReport({
    required this.scanMetrics,
    required this.apiMetrics,
    required this.allMetrics,
  });
}
