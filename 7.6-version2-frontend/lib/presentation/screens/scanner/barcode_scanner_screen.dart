import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../domain/entities/product_analysis.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../services/api_service.dart';
import '../../../services/api.dart';
import '../../../services/user_service.dart';
import '../../../services/performance_monitor.dart';
import '../../../services/error_handler.dart';
import '../../../services/progressive_loader.dart';
import '../../widgets/enhanced_loading.dart';
import '../recommendation/recommendation_detail_screen.dart';
import '../../widgets/ingredients_display.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final int userId;
  final ProductAnalysis? productAnalysis;

  const BarcodeScannerScreen({Key? key, this.productAnalysis, required this.userId}) : super(key: key);
  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  ProductAnalysis? _currentAnalysis;
  List<Map<String, dynamic>> _receiptItems = [];
  bool _showScanner = false;
  bool _isLoading = false;
  bool _scannedOnce = false;
  bool _isProcessing = false;
  bool _disposed = false;
  Timer? _debounceTimer;
  MobileScannerController? _controller;
  
  // 本地缓存，避免重复请求
  static final Map<String, ProductAnalysis> _localCache = {};
  
  // Multi-frame detection for better accuracy
  Map<String, int> _detectionCount = {};
  static const int _confirmationThreshold = 3; // 三次一致才处理
  
  // 渐进式加载状态
  ProductLoadingState? _loadingState;
  StreamSubscription<ProductLoadingState>? _loadingSubscription;
  String? _errorMsg; // 新增错误信息字段
  String? _lastConfirmedBarcode;
  Map<String, dynamic>? _recommendationData;
  
  // 用户过敏原状态
  List<String> _userAllergens = [];
  bool _userAllergensLoaded = false;

  @override
  void initState() {
    super.initState();
    _currentAnalysis = widget.productAnalysis;
    _showScanner = true;
    _loadUserAllergens(); // 加载用户过敏原
    
    // 延迟初始化controller，避免立即启动导致的问题
    _initializeController();
  }

  /// 安全初始化控制器
  Future<void> _initializeController() async {
    try {
      // 如果controller已存在，先清理
      if (_controller != null) {
        await _controller?.dispose();
        _controller = null;
      }
      
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
        returnImage: false,
        autoStart: false, // 改为手动启动，避免重复启动问题
        detectionTimeoutMs: 200,
        formats: [
          BarcodeFormat.ean13,
          BarcodeFormat.ean8,
          BarcodeFormat.code128,
          BarcodeFormat.code39,
          BarcodeFormat.upcA,
          BarcodeFormat.upcE,
          BarcodeFormat.code93,
          BarcodeFormat.itf,
          BarcodeFormat.dataMatrix,
          BarcodeFormat.qrCode,
        ],
      );
      
      // 等待一帧后再启动，确保widget已完全构建
      await Future.delayed(Duration(milliseconds: 100));
      if (!_disposed && mounted) {
        await _controller?.start();
        print('✅ MobileScannerController created and started successfully');
      }
    } catch (e) {
      print('❌ Error creating MobileScannerController: $e');
      if (!_disposed && mounted) {
        _safeSetState(() {
          _errorMsg = 'Camera initialization failed. Please restart the app.';
        });
      }
    }
  }

  /// 加载用户过敏原信息
  Future<void> _loadUserAllergens() async {
    try {
      final allergenData = await getUserAllergens(widget.userId);
      if (allergenData != null && !_disposed) {
        setState(() {
          _userAllergens = allergenData
              .map((allergen) => allergen['name']?.toString() ?? '')
              .where((name) => name.isNotEmpty)
              .toList();
          _userAllergensLoaded = true;
        });
        print('✅ Loaded user allergens: $_userAllergens');
      } else {
        setState(() {
          _userAllergensLoaded = true;
        });
      }
    } catch (e) {
      print('❌ Error loading user allergens: $e');
      setState(() {
        _userAllergensLoaded = true;
      });
    }
  }

  /// 获取用户相关的过敏原（产品过敏原与用户过敏原的交集）
  List<String> _getUserRelevantAllergens() {
    if (_currentAnalysis == null || !_userAllergensLoaded) {
      return [];
    }
    
    return _currentAnalysis!.detectedAllergens
        .where((allergen) => _userAllergens.contains(allergen))
        .toList();
  }

  /// 构建用户相关的过敏原警告UI
  List<Widget> _buildUserRelevantAllergenWarning() {
    if (!_userAllergensLoaded) {
      // 加载中状态
      return [
        _buildInfoCard(
          title: "Allergen Check",
          content: "Checking allergen compatibility...",
          icon: Icons.hourglass_empty,
          color: Colors.grey,
        ),
        SizedBox(height: 12),
      ];
    }

    final relevantAllergens = _getUserRelevantAllergens();
    
    if (relevantAllergens.isEmpty) {
      // 没有用户相关的过敏原，不显示警告
      return [];
    }

    // 显示用户相关的过敏原警告
    return [
      _buildInfoCard(
        title: "🚨 Allergen Warning",
        content: "Contains ${relevantAllergens.join(', ')} - Personal allergy match detected!",
        icon: Icons.warning,
        color: AppColors.alert,
      ),
      SizedBox(height: 12),
    ];
  }

  Future<void> _onBarcodeScanned(BarcodeCapture capture) async {
    if (capture.barcodes.isEmpty || _isProcessing || _disposed) return;
    final rawCode = capture.barcodes.first.rawValue?.trim();
    if (rawCode == null || rawCode.isEmpty) return;
    // 只处理2-13位数字条码
    if (!RegExp(r'^[0-9]{2,13}$').hasMatch(rawCode)) {
      print('Invalid barcode: $rawCode');
      _safeSetState(() {
        _isProcessing = false;
        _isLoading = false;
        _currentAnalysis = null;
        _scannedOnce = true;
        _errorMsg = 'Barcode recognition failed. Please align the barcode and try again.';
      });
      return;
    }
    print('Barcode detected: $rawCode');
    // 多帧一致性校验
    _detectionCount[rawCode] = (_detectionCount[rawCode] ?? 0) + 1;
    print('Detection count for $rawCode: ${_detectionCount[rawCode]}');
    if (_detectionCount[rawCode]! >= _confirmationThreshold) {
      print('Barcode confirmed after $_confirmationThreshold detections: $rawCode');
      await _controller?.stop();
      HapticFeedback.mediumImpact();
      _detectionCount.clear();
      _lastConfirmedBarcode = rawCode;
      // 添加淡出动画
      if (mounted) {
        setState(() {
          _showScanner = false;
        });
        await Future.delayed(Duration(milliseconds: 350));
      }
      _processBarcodeData(rawCode);
    }
  }

  void _handleBarcodeDetected(String barcode) {
    // 移除防抖逻辑，直接处理
    _processBarcodeData(barcode);
  }

  Future<void> _processBarcodeData(String barcode) async {
    if (_disposed) return;
    
    final monitor = PerformanceMonitor();
    monitor.startTimer('total_scan_process');
    
    try {
      print('🔍 Processing barcode: $barcode');
      
      // 清除本地缓存以确保获取最新数据
      _localCache.clear();
      print('🗑️ Cleared local cache');
      
      // 获取用户ID
      final dynamic rawUserId = await UserService.instance.getCurrentUserId() ?? widget.userId;
      int userId;
      if (rawUserId is String) {
        userId = int.tryParse(rawUserId) ?? widget.userId;
      } else if (rawUserId is int) {
        userId = rawUserId;
      } else {
        userId = widget.userId;
      }
      print('👤 Using userId: $userId');
      
      // 取消之前的加载
      _loadingSubscription?.cancel();
      
      // 启动渐进式加载，添加超时控制
      final progressiveLoader = ProgressiveLoader();
      _loadingSubscription = progressiveLoader.loadProduct(
        barcode: barcode,
        userId: userId,
      ).listen(
        _handleLoadingStateChange,
        onError: (error) {
          if (error is TimeoutException) {
            print('API request timeout');
            _handleLoadingError('Request timed out. Server is slow to respond.');
          } else {
            _handleLoadingError(error);
          }
        },
      );
      
      // 设置超时定时器
      Timer(Duration(seconds: 15), () {
        if (_isProcessing && _loadingSubscription != null) {
          _loadingSubscription?.cancel();
          _handleLoadingError('Request timed out. Server is slow to respond.');
        }
      });
      
      // 初始状态设置
      _safeSetState(() {
        _isProcessing = true;
        _isLoading = true;
        _receiptItems = [];
        _scannedOnce = true;
        _currentAnalysis = null;
        _errorMsg = null;
      });
      
    } catch (e) {
      final totalTime = monitor.endTimer('total_scan_process');
      
      print('Barcode processing error: $e');
      
      if (!_disposed && mounted) {
        final errorHandler = ErrorHandler();
        final errorResult = errorHandler.handleApiError(e, context: 'product');
        
        errorHandler.showErrorSnackBar(
          context,
          errorResult,
          onRetry: errorResult.canRetry ? () => _processBarcodeData(barcode) : null,
        );
      }
      
      _safeSetState(() {
        _isProcessing = false;
        _isLoading = false;
        _errorMsg = 'Unknown error. Please try again.';
      });
    }
  }
  
  void _handleLoadingStateChange(ProductLoadingState state) {
    if (_disposed || !mounted) return;
    
    _safeSetState(() {
      _loadingState = state;
      
      // 在基础信息加载完成时就显示结果
      if (state.stage == LoadingStage.basicInfoLoaded && state.product != null) {
        _currentAnalysis = state.product;
        _showScanner = false;
        _errorMsg = null;
        print('Basic info loaded, showing results immediately');
      }
      
      // 完全加载完成时更新产品信息并缓存
      if (state.isCompleted && state.product != null) {
        _currentAnalysis = state.product;
        _isLoading = false;
        _isProcessing = false;
        _errorMsg = null;
        _recommendationData = state.product?.llmAnalysis;
        
        // 缓存结果到本地
        final barcode = state.product?.name ?? 'unknown';
        _localCache[barcode] = state.product!;
        print('All data loaded and cached successfully');
        
        if (state.hasPartialData) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product info loaded, but personalized recommendations temporarily unavailable'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }
  
  void _handleLoadingError(dynamic error) {
    if (_disposed || !mounted) return;
    
    String msg = 'Unknown error. Please try again.';
    if (error.toString().contains('not found')) {
      msg = 'Product not found. Please check the barcode or try again.';
    } else if (error.toString().contains('timeout')) {
      msg = 'Request timed out. Server is slow to respond.';
    } else if (error.toString().contains('Exception: Product not found in database')) {
      msg = 'Product not found in database. Please check the barcode.';
    }
    print('Progressive loading error: $error');
    
    _safeSetState(() {
      _isProcessing = false;
      _isLoading = false;
      _currentAnalysis = null;
      _scannedOnce = true;
      _errorMsg = msg;
      _showScanner = false; // 显示错误页面而不是扫描器
    });
    
    final errorHandler = ErrorHandler();
    final errorResult = errorHandler.handleApiError(error, context: 'product');
    
    // 显示错误提示，提供重试选项
    if (errorResult.canRetry && _lastConfirmedBarcode != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.alert,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _processBarcodeData(_lastConfirmedBarcode!),
          ),
          duration: Duration(seconds: 5),
        ),
    );
    }
  }
  
  String _getLoadingSecondaryMessage() {
    if (_loadingState == null) return 'Please wait, getting detailed information...';
    
    switch (_loadingState!.stage) {
      case LoadingStage.initializing:
        return 'Initializing scanning system...';
      case LoadingStage.detecting:
        return 'Detecting barcode, please hold steady...';
      case LoadingStage.fetchingBasicInfo:
        return 'Querying product database, almost there...';
      case LoadingStage.basicInfoLoaded:
        return 'Basic info loaded, getting personalized recommendations...';
      case LoadingStage.fetchingRecommendations:
        return 'Analyzing your nutrition needs, generating personalized suggestions...';
      case LoadingStage.completed:
        return 'All information loaded successfully!';
      case LoadingStage.error:
        return 'Error occurred during loading';
      default:
        return 'Processing...';
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (!_disposed && mounted) {
      setState(fn);
    }
  }
  
  /// 统一的卡片标题样式
  Widget _buildCardTitle({
    required IconData icon,
    required String title,
    Color? iconColor,
  }) {
    return Row(
      children: [
        Icon(
          icon, 
          color: iconColor ?? AppColors.primary, 
          size: 20, // 统一图标尺寸
        ),
        SizedBox(width: 8),
        Text(
          title,
          style: AppStyles.bodyBold.copyWith(
            color: AppColors.primary,
            fontSize: 16, // 统一字体大小
          ),
        ),
      ],
    );
  }
  
  /// 安全重启摄像头
  Future<void> _safeRestartCamera() async {
    try {
      // 检查控制器状态
      if (_controller == null) {
        print('🔄 Controller is null, reinitializing...');
        await _initializeController();
        return;
      }
      
      // 安全停止现有会话
      try {
        await _controller?.stop();
        print('🛑 Camera stopped successfully');
      } catch (e) {
        print('⚠️ Error stopping camera (continuing anyway): $e');
      }
      
      // 等待短暂延迟后重启
      await Future.delayed(Duration(milliseconds: 500));
      
      if (!_disposed && mounted) {
        try {
          await _controller?.start();
          print('🎥 Camera restarted successfully');
        } catch (e) {
          print('❌ Error restarting camera: $e');
          // 如果重启失败，尝试重新初始化
          await _initializeController();
        }
      }
    } catch (e) {
      print('❌ Error in _safeRestartCamera: $e');
      if (!_disposed && mounted) {
        _safeSetState(() {
          _errorMsg = 'Camera restart failed. Please try again.';
        });
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    _loadingSubscription?.cancel();
    
    // 安全停止并清理控制器
    _cleanupController();
    
    // Print performance summary
    PerformanceMonitor().printSummary();
    
    super.dispose();
  }
  
  /// 安全清理控制器
  Future<void> _cleanupController() async {
    try {
      if (_controller != null) {
        await _controller?.stop();
        await _controller?.dispose();
        _controller = null;
        print('🧹 Controller cleaned up successfully');
      }
    } catch (e) {
      print('⚠️ Error cleaning up controller: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _currentAnalysis?.name ?? 'Product Scanner',
          style: AppStyles.h2.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () async {
            if (!_showScanner) {
              // 结果页返回，切换回扫码状态并安全重启摄像头
              _safeSetState(() {
                _showScanner = true;
                _receiptItems.clear();
                _currentAnalysis = null;
                _isLoading = false;
                _isProcessing = false;
                _loadingState = null;
                _errorMsg = null;
                _detectionCount.clear();
                _lastConfirmedBarcode = null;
              });
              
              // 安全重启摄像头
              await _safeRestartCamera();
            } else {
              // 扫码页返回，停止摄像头并退出
              await _controller?.stop();
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _showScanner
          ? Stack(
              children: [
                // 全屏摄像头区域
                MobileScanner(
                  controller: _controller,
                  onDetect: _onBarcodeScanned,
                  scanWindow: Rect.fromLTWH(
                    0,  // 左边界设为0，最大化检测区域
                    0,  // 上边界设为0，最大化检测区域
                    MediaQuery.of(context).size.width,  // 全屏宽度
                    MediaQuery.of(context).size.height,  // 全屏高度
                  ),
                ),
                // 顶部只保留主标题
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(16, 60, 16, 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Point camera at barcode',
                        style: AppStyles.bodyBold.copyWith(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                // 半透明的底部控制区域
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(16, 20, 16, 40),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 取消按钮
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _showScanner = false),
                          icon: Icon(Icons.close, size: 20),
                          label: Text("Cancel"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.9),
                            foregroundColor: AppColors.textDark,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                        // 手电筒按钮
                        ElevatedButton.icon(
                          onPressed: () {
                            _controller?.toggleTorch();
                          },
                          icon: Icon(Icons.flashlight_on, size: 20),
                          label: Text("Flash"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.9),
                            foregroundColor: AppColors.textDark,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 放大的扫码框指示器
                Center(
                  child: Container(
                    width: 350,
                    height: 220,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withOpacity(0.6),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        // 四个角的指示器
                        Positioned(
                          top: -3,
                          left: -3,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: AppColors.primary, width: 4),
                                left: BorderSide(color: AppColors.primary, width: 4),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: -3,
                          right: -3,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: AppColors.primary, width: 4),
                                right: BorderSide(color: AppColors.primary, width: 4),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -3,
                          left: -3,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppColors.primary, width: 4),
                                left: BorderSide(color: AppColors.primary, width: 4),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -3,
                          right: -3,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppColors.primary, width: 4),
                                right: BorderSide(color: AppColors.primary, width: 4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                if (_isLoading)
                  Container(
                    padding: EdgeInsets.all(20),
                    child: EnhancedLoading(
                      message: _loadingState?.message ?? 'Analyzing product',
                      secondaryMessage: _getLoadingSecondaryMessage(),
                      type: LoadingType.scanning,
                      showProgress: true,
                      progress: _loadingState?.progress,
                      estimatedTime: Duration(seconds: 5),
                      onCancel: () {
                        _loadingSubscription?.cancel();
                        setState(() {
                          _isLoading = false;
                          _isProcessing = false;
                          _showScanner = true;
                          _loadingState = null;
                          _errorMsg = null;
                        });
                      },
                    ),
                  )
                else if (_errorMsg != null)
                  Expanded(child: _buildErrorResult())
                else
                  Expanded(child: _buildAnalysisResult()),
              ],
            ),
    );
  }

  Widget _buildAnalysisResult() {
    if (_receiptItems.isNotEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('Purchased Items', Icons.shopping_cart),
          SizedBox(height: 16),
          ..._receiptItems.map((item) => _buildReceiptItem(item)),
          if (_currentAnalysis != null) ...[
            SizedBox(height: 24),
            _buildAIInsights(),
          ],
          SizedBox(height: 24),
          _buildRescanButton(),
        ],
      );
    }

    if (_currentAnalysis == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _scannedOnce ? Icons.search_off : Icons.qr_code_scanner,
              size: 64,
              color: AppColors.textLight,
            ),
            SizedBox(height: 16),
            Text(
              _scannedOnce
                  ? 'No information available for this product.'
                  : 'Scan a product or upload a receipt to get started',
              style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            _buildRescanButton(),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildProductInfo(),
        _buildAIInsights(),
        SizedBox(height: 24),
        _buildRescanButton(),
      ],
    );
  }

  Widget _buildErrorResult() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.alert),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
            _errorMsg!,
              style: AppStyles.bodyBold.copyWith(color: AppColors.alert),
            textAlign: TextAlign.center,
          ),
          ),
          SizedBox(height: 32),
          
          // 重试按钮（如果有上次扫描的条码）
          if (_lastConfirmedBarcode != null) ...[
            ElevatedButton.icon(
              onPressed: () {
                _processBarcodeData(_lastConfirmedBarcode!);
              },
              icon: Icon(Icons.refresh),
              label: Text('Retry Last Scan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
          
          // 重新扫描按钮
          _buildRescanButton(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        SizedBox(width: 8),
        Text(
          title,
          style: AppStyles.bodyBold.copyWith(
            color: AppColors.primary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptItem(Map<String, dynamic> item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.shopping_basket, color: AppColors.primary, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Unknown Item',
                  style: AppStyles.bodyBold,
                ),
                SizedBox(height: 4),
                Text(
                  "Quantity: ${item['quantity'] ?? 1}",
                  style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 构建过敏原显示逻辑
        ..._buildAllergenDisplay(),

        IngredientsDisplay(
          ingredients: _currentAnalysis!.ingredients,
          // 去掉maxDisplayCount参数，使用默认值10（2列×5行）
        ),
        SizedBox(height: 16), // 统一卡片间距
      ],
    );
  }

  /// 构建过敏原显示逻辑：有匹配显示警告，无匹配显示安全提示
  List<Widget> _buildAllergenDisplay() {
    if (_currentAnalysis == null) return [];

    // 如果用户过敏原未加载完成，显示加载状态
    if (!_userAllergensLoaded) {
      return [
        _buildInfoCard(
          title: "Allergen Check",
          content: "Checking allergen compatibility...",
          icon: Icons.hourglass_empty,
          color: Colors.grey,
        ),
        SizedBox(height: 12),
      ];
    }

    // 执行过敏原匹配逻辑（不管用户是否设置过敏原）
    final relevantAllergens = _getUserRelevantAllergens();

    if (relevantAllergens.isNotEmpty) {
      // Case 1: 有匹配的过敏原 - 显示警告，只显示匹配的过敏原
      return [
        _buildInfoCard(
          title: "🚨 Allergen Warning",
          content: "Contains ${relevantAllergens.join(', ')} - Personal allergy match detected!",
          icon: Icons.warning,
          color: AppColors.alert,
        ),
        SizedBox(height: 16), // 统一卡片间距
      ];
    } else {
      // Case 2: 无匹配过敏原 - 显示安全提示
      return [
        _buildInfoCard(
          title: "Allergen Information",
          content: "No allergens detected - No ingredients found related to your allergy history",
          icon: Icons.verified,
          color: AppColors.success,
        ),
        SizedBox(height: 16), // 统一卡片间距
      ];
    }
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle(
            icon: icon,
            title: title,
            iconColor: AppColors.primary,
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: AppStyles.bodyRegular.copyWith(
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 根据加载状态显示内容
        _loadingState?.stage == LoadingStage.fetchingRecommendations
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _buildLLMAnalysisCard(),
        // View Details按钮已移到卡片内部，这里不再需要额外的间距
      ],
    );
  }

  Widget _buildLLMAnalysisCard() {
    // 从ProductAnalysis对象获取LLM数据，而不是从_recommendationData
    if (_currentAnalysis == null) return SizedBox.shrink();

    final summary = _currentAnalysis!.summary;

    print('🔍 Scanner LLM Card: Raw data - Summary: "${summary}"');

    return Container(
      margin: EdgeInsets.only(bottom: 16), // 统一卡片外边距
      padding: EdgeInsets.all(16), // 统一卡片内边距
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          _buildCardTitle(
        icon: Icons.psychology,
            title: 'AI Nutrition Analysis',
            iconColor: AppColors.primary,
          ),
          SizedBox(height: 16),

          // 字段1: Summary
          _buildScannerAnalysisField(
            icon: Icons.summarize,
            title: 'Summary',
            content: summary,
            color: Colors.orange,
            fieldKey: 'summary',
          ),
          
          // 添加推荐产品列表
          if (_currentAnalysis!.recommendations.isNotEmpty) ...[
            SizedBox(height: 16),
            _buildRecommendationsList(),
          ],
          
          SizedBox(height: 16),
          
          // View Details按钮 - 位于卡片右下角
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildViewDetailsButton(),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建推荐产品列表组件
  Widget _buildRecommendationsList() {
    final recommendations = _currentAnalysis!.recommendations;
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 推荐产品标题
          Row(
            children: [
              Icon(
                Icons.recommend, 
                color: AppColors.primary, 
                size: 18
              ),
              SizedBox(width: 6),
              Text(
                'Alternative Products',
                style: AppStyles.bodyBold.copyWith(
                  color: AppColors.primary,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 12,
                      color: AppColors.success,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${recommendations.length} FOUND',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          // 推荐产品列表
          ...recommendations.take(3).map((recommendation) => 
            _buildRecommendationItem(recommendation)
          ).toList(),
          
          // 如果有超过3个推荐，显示更多提示
          if (recommendations.length > 3) ...[
            SizedBox(height: 8),
            _buildMoreAlternativesIndicator(recommendations.length, 3),
          ],
        ],
      ),
    );
  }

  /// 构建单个推荐产品项 - 优化展示体验
  Widget _buildRecommendationItem(ProductAnalysis recommendation) {
    // 确定显示内容：优先显示条码，其次显示推荐标识
    bool hasBarcode = recommendation.barcode != null && recommendation.barcode!.isNotEmpty;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12), // 增加间距，降低视觉密度
      padding: EdgeInsets.all(12), // 增加内边距
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8), // 稍大的圆角
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // 产品图标 - 更大更突出
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 20,
              color: AppColors.success,
            ),
          ),
          SizedBox(width: 12),
          
          // 产品信息 - 简化层级
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.name,
                  style: AppStyles.bodyBold.copyWith( // 使用新字体系统
                    color: AppColors.textDark,
                  ),
                  maxLines: 2, // 允许两行显示完整名称
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  recommendation.summary.isNotEmpty ? 
                    recommendation.summary : 
                    "Better nutritional value for your goals", // 使用真实推荐理由或后备文本
                  style: AppStyles.caption.copyWith( // 使用新字体系统
                    color: AppColors.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // 推荐标识 - 显示条码或推荐图标
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasBarcode ? AppColors.primary : AppColors.success,
              borderRadius: BorderRadius.circular(6),
            ),
            child: hasBarcode 
                ? Text(
                    recommendation.barcode!, // 修复：显示完整条码
                    style: AppStyles.statusLabel.copyWith(
                      color: AppColors.white,
                    ),
                  )
                : Icon(
                    Icons.check,
                    size: 14,
                    color: AppColors.white,
                  ),
          ),
        ],
      ),
    );
  }

  /// 更新推荐产品数量显示样式
  Widget _buildMoreAlternativesIndicator(int totalCount, int displayCount) {
    if (totalCount <= displayCount) return SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.only(top: 8),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '+${totalCount - displayCount} more alternatives available',
            style: AppStyles.caption.copyWith( // 使用新字体系统
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建扫描器的单个分析字段显示 - 应用新字体系统
  Widget _buildScannerAnalysisField({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    required String fieldKey,
    bool isList = false,
    List<String>? listItems,
  }) {
    // 判断字段状态
    bool hasContent = content.isNotEmpty;
    bool isMeaningful = hasContent && content.length > 5 && content != 'null';

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMeaningful ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
          width: 1,
          ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 字段标题和状态
          Row(
            children: [
              Icon(
                icon, 
                color: isMeaningful ? color : Colors.grey, 
                size: 18
              ),
              SizedBox(width: 6),
              Text(
                title,
                style: AppStyles.bodyBold.copyWith(
                  color: isMeaningful ? color : Colors.grey[600]!,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getScannerStatusColor(isMeaningful, hasContent).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getScannerStatusIcon(isMeaningful, hasContent),
                      size: 12,
                      color: _getScannerStatusColor(isMeaningful, hasContent),
                    ),
                    SizedBox(width: 4),
                    Text(
                      _getScannerStatusText(isMeaningful, hasContent),
                      style: AppStyles.statusLabel.copyWith( // 使用新字体系统
                        color: _getScannerStatusColor(isMeaningful, hasContent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          
          // 字段内容
          if (isMeaningful) ...[
            if (isList && listItems != null && listItems.isNotEmpty) ...[
              ...listItems.map((item) => 
                Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.arrow_right, color: color, size: 16),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item,
                          style: AppStyles.bodySmall, // 使用新字体系统
                        ),
                      ),
                    ],
                  ),
                ),
              ).toList(),
            ] else ...[
              Text(
                content,
                style: AppStyles.bodySmall, // 使用新字体系统
              ),
            ],
          ] else ...[
            Text(
              hasContent ? 'Raw content: "$content"' : 'No data received',
              style: AppStyles.caption.copyWith( // 使用新字体系统
                fontStyle: FontStyle.italic,
              ),
            ),
            ],
          
          // 调试信息
          SizedBox(height: 4),
          Text(
            'Field: $fieldKey | Length: ${content.length} chars',
            style: AppStyles.caption.copyWith( // 使用新字体系统
              color: Colors.grey.shade500,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  /// 扫描器字段状态辅助方法
  Color _getScannerStatusColor(bool isMeaningful, bool hasContent) {
    if (isMeaningful) return Colors.green;
    if (hasContent) return Colors.orange;
    return Colors.grey;
  }

  IconData _getScannerStatusIcon(bool isMeaningful, bool hasContent) {
    if (isMeaningful) return Icons.check_circle;
    if (hasContent) return Icons.warning;
    return Icons.help_outline;
  }

  String _getScannerStatusText(bool isMeaningful, bool hasContent) {
    if (isMeaningful) return 'DATA';
    if (hasContent) return 'PLACEHOLDER';
    return 'EMPTY';
  }

  Widget _buildViewDetailsButton() {
    final bool isDataReady = _loadingState?.isCompleted ?? false;
    return ElevatedButton.icon(
      onPressed: isDataReady ? () => _navigateToDetailPage() : null,
      icon: Icon(
        Icons.visibility,
        size: 18,
      ),
      label: Text(
        "View Details",
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDataReady ? AppColors.primary : Colors.grey[300],
        foregroundColor: isDataReady ? AppColors.white : Colors.grey[600],
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: isDataReady ? 2 : 0,
        shadowColor: isDataReady ? AppColors.primary.withOpacity(0.3) : null,
      ),
    );
  }

  void _navigateToDetailPage() {
    if (_currentAnalysis != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecommendationDetailScreen(
            productAnalysis: _currentAnalysis!,
          ),
        ),
      );
    }
  }

  Widget _buildRescanButton() {
    return ElevatedButton.icon(
      onPressed: () async {
        // 重置状态
        _safeSetState(() {
          _showScanner = true;
          _receiptItems.clear();
          _currentAnalysis = null;
          _isLoading = false;
          _isProcessing = false;
          _loadingState = null;
          _errorMsg = null;
          _detectionCount.clear();
          _lastConfirmedBarcode = null;
        });
        
        // 安全重启摄像头
        await _safeRestartCamera();
      },
      icon: Icon(Icons.qr_code_scanner, size: 20),
      label: Text(
        "Scan Another Product",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        shadowColor: AppColors.primary.withOpacity(0.3),
      ),
    );
  }

  /// 构建成分信息卡片
  Widget _buildIngredientsCard() {
    final ingredients = _currentAnalysis?.ingredients ?? [];
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Icon(Icons.list, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                "Ingredients",
                style: AppStyles.bodyBold.copyWith(
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // 成分内容
          _buildIngredientsContent(ingredients),
        ],
      ),
    );
  }

  /// 构建成分内容显示
  Widget _buildIngredientsContent(List<String> ingredients) {
    if (ingredients.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[600], size: 16),
            SizedBox(width: 8),
            Text(
              'No ingredients information available',
              style: AppStyles.bodyRegular.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    // 处理成分数据
    List<String> processedIngredients = _processIngredients(ingredients);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 显示前5个主要成分
        ...processedIngredients.take(5).map((ingredient) => 
          Container(
            margin: EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 8, right: 8),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    ingredient,
                    style: AppStyles.bodyRegular.copyWith(
                      color: AppColors.textDark,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // 如果有更多成分，显示展开按钮
        if (processedIngredients.length > 5) ...[
          SizedBox(height: 8),
          _buildExpandIngredientsButton(processedIngredients),
        ],
      ],
    );
  }

  /// 处理成分数据
  List<String> _processIngredients(List<String> rawIngredients) {
    List<String> processed = [];
    
    for (String ingredient in rawIngredients) {
      if (ingredient.trim().isEmpty) continue;
      
      // 如果是逗号分隔的长字符串，需要分割
      if (ingredient.contains(',') && ingredient.length > 50) {
        List<String> parts = ingredient.split(',');
        for (String part in parts) {
          String cleaned = _cleanIngredient(part.trim());
          if (cleaned.isNotEmpty) {
            processed.add(cleaned);
          }
        }
      } else {
        String cleaned = _cleanIngredient(ingredient.trim());
        if (cleaned.isNotEmpty) {
          processed.add(cleaned);
        }
      }
    }
    
    return processed;
  }

  /// 清理单个成分名称
  String _cleanIngredient(String ingredient) {
    String cleaned = ingredient.trim();
    
    // 移除可能的前缀
    if (cleaned.startsWith('MODIFIED CODE: ')) {
      cleaned = cleaned.substring(15).trim();
    }
    
    // 移除多余的空格
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    
    // 首字母大写（如果是小写开头）
    if (cleaned.isNotEmpty && cleaned[0].toLowerCase() == cleaned[0]) {
      cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
    }
    
    return cleaned;
  }

  /// 构建展开成分按钮
  Widget _buildExpandIngredientsButton(List<String> allIngredients) {
    return Container(
      margin: EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: () => _showAllIngredients(allIngredients),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.expand_more,
                color: AppColors.primary,
                size: 16,
              ),
              SizedBox(width: 4),
              Text(
                'Show all ${allIngredients.length} ingredients',
                style: AppStyles.bodySmall.copyWith( // 使用新字体系统
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示所有成分的弹窗
  void _showAllIngredients(List<String> ingredients) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.list, color: AppColors.primary),
              SizedBox(width: 8),
              Text('All Ingredients'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(maxHeight: 400),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: ingredients.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 8, right: 8),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          ingredients[index],
                          style: AppStyles.bodyRegular.copyWith(
                            color: AppColors.textDark,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}