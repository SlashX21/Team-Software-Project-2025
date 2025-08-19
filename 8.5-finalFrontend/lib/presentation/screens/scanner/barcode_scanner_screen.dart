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
import '../../../services/allergen_detection_helper.dart';
import '../../widgets/multi_stage_progress_indicator.dart';
import '../recommendation/recommendation_detail_screen.dart';
import '../../widgets/ingredients_display.dart';


class BarcodeScannerScreen extends StatefulWidget {
  final int userId;
  final ProductAnalysis? productAnalysis;
  final VoidCallback? onBackToHome; // 添加回到首页的回调

  const BarcodeScannerScreen({
    Key? key, 
    this.productAnalysis, 
    required this.userId,
    this.onBackToHome,
  }) : super(key: key);
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
  Timer? _timeoutTimer;
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
  
  // 用户过敏原状态 - 修复：存储完整对象以保留严重性等级信息
  List<Map<String, dynamic>> _userAllergens = [];
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
          // 修复：保留完整的过敏原对象，包含严重性等级等信息
          // 使用 'allergenName' 字段（API返回的正确字段名）
          _userAllergens = allergenData
              .where((allergen) => allergen['allergenName'] != null && allergen['allergenName'].toString().isNotEmpty)
              .toList();
          _userAllergensLoaded = true;
        });
        print('✅ Loaded user allergens with severity: ${_userAllergens.map((a) => "${a['allergenName']} (${a['severityLevel']})")}');
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

  /// 获取用户相关的过敏原匹配结果（包含严重性等级）- 使用AllergenDetectionHelper
  List<AllergenMatch> _getUserRelevantAllergens() {
    if (_currentAnalysis == null || !_userAllergensLoaded) {
      return [];
    }
    
    // 如果用户没有设置过敏原，返回空列表
    if (_userAllergens.isEmpty) {
      return [];
    }
    
    // 使用升级的AllergenDetectionHelper进行检测
    return AllergenDetectionHelper.detectSingleProduct(
      product: _currentAnalysis!,
      userAllergens: _userAllergens,
    );
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
      // 直接处理，不需要在这里设置 _showScanner = false
      _processBarcodeData(rawCode);
    }
  }

  void _handleBarcodeDetected(String barcode) {
    // 移除防抖逻辑，直接处理
    _processBarcodeData(barcode);
  }

  Future<void> _processBarcodeData(String barcode) async {
    if (_disposed || _isProcessing) return; // 防止重复处理
    
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
      await _loadingSubscription?.cancel();
      _loadingSubscription = null;
      
      // 先设置状态，防止重复触发
      _safeSetState(() {
        _isProcessing = true;
        _isLoading = true;
        _receiptItems = [];
        _scannedOnce = true;
        _currentAnalysis = null;
        _errorMsg = null;
        _showScanner = false; // 立即隐藏扫描器
      });
      
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
      
      // 取消之前的超时定时器
      _timeoutTimer?.cancel();
      
      // 设置新的超时定时器
      _timeoutTimer = Timer(Duration(seconds: 90), () {
        if (_isProcessing && _loadingSubscription != null) {
          _loadingSubscription?.cancel();
          _handleLoadingError('Request timed out. Server is slow to respond.');
        }
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
        _errorMsg = null;
        print('Basic info loaded, showing results immediately');
      }
      
      // 完全加载完成时更新产品信息并缓存
      if (state.isCompleted && state.product != null) {
        _timeoutTimer?.cancel(); // 取消超时定时器
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
    
    _timeoutTimer?.cancel(); // 取消超时定时器
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
    if (_loadingState == null) return 'Processing your request...';
    
    switch (_loadingState!.stage) {
      case LoadingStage.initializing:
      case LoadingStage.detecting:
        return 'Barcode recognized, preparing to fetch product information...';
      case LoadingStage.fetchingBasicInfo:
        return 'Connecting to product database...';
      case LoadingStage.basicInfoLoaded:
        return 'Product found! Starting AI analysis...';
      case LoadingStage.fetchingRecommendations:
        return 'Analyzing nutrition profile and generating personalized recommendations...';
      case LoadingStage.completed:
        return 'Analysis complete!';
      case LoadingStage.error:
        return 'Unable to complete analysis';
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
    _timeoutTimer?.cancel();
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

  /// 导航到首页标签
  void _navigateToHomeTab() {
    // 优先使用回调函数回到首页
    if (widget.onBackToHome != null) {
      widget.onBackToHome!();
      return;
    }
    
    // 如果没有回调函数，使用默认的导航逻辑
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.popUntil((route) => route.isFirst);
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
              // 扫码页返回，停止摄像头并回到主页
              await _controller?.stop();
              // 由于扫描页面在主导航中，直接切换到首页标签
              // 通过查找父级MainNavigationScreen并切换标签
              _navigateToHomeTab();
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
                if (_isLoading && _loadingState != null)
                  Container(
                    padding: EdgeInsets.all(20),
                    child: MultiStageProgressIndicator(
                      currentStage: _loadingState!.stage,
                      progress: _loadingState!.progress,
                      message: _loadingState!.message,
                      secondaryMessage: _getLoadingSecondaryMessage(),
                      onCancel: () {
                        _loadingSubscription?.cancel();
                        _safeSetState(() {
                          _isLoading = false;
                          _isProcessing = false;
                          _showScanner = true;
                          _loadingState = null;
                          _errorMsg = null;
                        });
                        _safeRestartCamera();
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

    // 检查用户是否设置了过敏原
    if (_userAllergens.isEmpty) {
      // Case 1: 用户未设置过敏原 - 显示提示设置
      return [
        _buildInfoCard(
          title: "Allergen Information",
          content: "You haven't set up any allergen preferences. Go to Profile to configure your allergens for personalized warnings.",
          icon: Icons.info_outline,
          color: Colors.blue,
        ),
        SizedBox(height: 16),
      ];
    }

    // 执行过敏原匹配逻辑，获取带严重性等级的匹配结果
    final allergenMatches = _getUserRelevantAllergens();

    if (allergenMatches.isNotEmpty) {
      // Case 2: 有匹配的过敏原 - 按严重性等级显示警告
      final mostSevere = allergenMatches.first; // 已按严重性排序，第一个是最严重的
      
      return [
        _buildSeverityAwareAllergenCard(allergenMatches),
        SizedBox(height: 16),
      ];
    } else {
      // Case 3: 用户有过敏原设置但无匹配 - 显示安全提示
      return [
        _buildInfoCard(
          title: "Allergen Information",
          content: "No allergens detected - Safe based on your allergen profile",
          icon: Icons.verified,
          color: AppColors.success,
        ),
        SizedBox(height: 16),
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
                // 移除推荐理由显示，只展示替代商品名称
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
          
          // 调试信息已移除 - 不向用户显示
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

  /// 获取简化的推荐理由 - 扫描页面使用
  String _getShortRecommendationReason(ProductAnalysis recommendation) {
    const maxLength = 40; // 限制字符长度以确保1行显示
    
    String reason = recommendation.summary.isNotEmpty 
        ? recommendation.summary 
        : "Better choice for your goals";
    
    // 如果太长，截取并添加省略号
    if (reason.length > maxLength) {
      reason = reason.substring(0, maxLength - 3) + "...";
    }
    
    return reason;
  }

  /// 构建严重性感知的过敏原警告卡片
  Widget _buildSeverityAwareAllergenCard(List<AllergenMatch> matches) {
    final mostSevere = matches.first; // 已按严重性排序
    final severityColor = AllergenDetectionHelper.getSeverityColor(mostSevere.severityLevel);
    final severityText = AllergenDetectionHelper.getSeverityText(mostSevere.severityLevel);
    
    // 构建过敏原列表，只显示前3个，其他用"and X more"表示
    String allergenText;
    if (matches.length == 1) {
      allergenText = matches[0].allergenName;
    } else if (matches.length <= 3) {
      allergenText = matches.map((m) => m.allergenName).join(', ');
    } else {
      final firstThree = matches.take(3).map((m) => m.allergenName).join(', ');
      allergenText = '$firstThree and ${matches.length - 3} more';
    }
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor, width: 2), // 严重性等级边框
        boxShadow: [
          BoxShadow(
            color: severityColor.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部：警告图标 + 标题 + 严重性标签
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning,
                  color: severityColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "⚠️ Allergen Warning",
                  style: AppStyles.bodyBold.copyWith(
                    color: severityColor,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  severityText.toUpperCase(),
                  style: AppStyles.captionBold.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          // 过敏原详细列表 - 使用胶囊样式显示严重程度
          SizedBox(height: 8),
          ...matches.take(3).map((match) => Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AllergenDetectionHelper.getSeverityColor(match.severityLevel),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    match.allergenName,
                    style: AppStyles.bodyRegular.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                _buildSeverityBadge(match.severityLevel),
              ],
            ),
          )),
          if (matches.length > 3)
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                "... and ${matches.length - 3} more allergens",
                style: AppStyles.caption.copyWith(
                  color: AppColors.textLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建严重程度胶囊样式组件 - 与右上角标签保持一致
  Widget _buildSeverityBadge(String severityLevel) {
    final severityColor = AllergenDetectionHelper.getSeverityColor(severityLevel);
    final severityText = AllergenDetectionHelper.getSeverityText(severityLevel);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: severityColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        severityText,
        style: AppStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

}