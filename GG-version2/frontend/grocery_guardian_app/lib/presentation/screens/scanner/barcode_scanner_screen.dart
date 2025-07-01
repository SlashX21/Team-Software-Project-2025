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
import '../../../services/user_service.dart';
import '../../../services/performance_monitor.dart';
import '../../../services/error_handler.dart';
import '../../../services/progressive_loader.dart';
import '../../widgets/enhanced_loading.dart';

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

  @override
  void initState() {
    super.initState();
    _currentAnalysis = widget.productAnalysis;
    _showScanner = true;
    
    try {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
        returnImage: false,
        autoStart: true,
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
      print('✅ MobileScannerController created successfully with optimized settings');
    } catch (e) {
      print('❌ Error creating MobileScannerController: $e');
    }
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
      print('Processing barcode: $barcode');
      
      // 先查本地缓存
      if (_localCache.containsKey(barcode)) {
        print('Found in local cache: $barcode');
        _safeSetState(() {
          _currentAnalysis = _localCache[barcode];
          _isProcessing = false;
          _isLoading = false;
          _scannedOnce = true;
          _errorMsg = null;
        });
        return;
      }
      
      // 获取用户ID
      final userId = await UserService.instance.getCurrentUserId() ?? widget.userId;
      
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
    });
    
    final errorHandler = ErrorHandler();
    final errorResult = errorHandler.handleApiError(error, context: 'product');
    
    errorHandler.showErrorSnackBar(
      context,
      errorResult,
      onRetry: errorResult.canRetry ? () => _processBarcodeData(_loadingState?.product?.name ?? 'unknown') : null,
    );
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

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    _controller?.dispose();
    _loadingSubscription?.cancel();
    
    // Print performance summary
    PerformanceMonitor().printSummary();
    
    super.dispose();
  }

  Future<void> _uploadReceipt() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _isLoading = true;
      _receiptItems.clear();
      _currentAnalysis = null;
    });

    try {
      final result = await ApiService.uploadReceiptImage(picked, widget.userId);

      final items = result['itemAnalyses'] ?? [];
      final llm = result['llmInsights'] ?? {};

      setState(() {
        _receiptItems = List<Map<String, dynamic>>.from(items);
        _currentAnalysis = ProductAnalysis(
          name: 'Receipt Summary',
          imageUrl: '',
          ingredients: [],
          detectedAllergens: [],
          summary: (llm['summary'] as String?)?.isNotEmpty == true
              ? llm['summary']
              : 'No summary provided by AI. The product seems acceptable based on available data.',
          detailedAnalysis: (llm['keyFindings'] is List && llm['keyFindings'].isNotEmpty)
              ? (llm['keyFindings'] as List).join('\n')
              : 'No key findings were detected from your receipt items.',
          actionSuggestions: (llm['improvementSuggestions'] is List && llm['improvementSuggestions'].isNotEmpty)
              ? List<String>.from(llm['improvementSuggestions'])
              : ['Try selecting more varied products for better AI suggestions.'],
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppColors.alert,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
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
              // 结果页返回，切换回扫码状态并重启摄像头
              setState(() {
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
              await _controller?.start();
            } else {
              // 扫码页返回，正常pop
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
        if (_currentAnalysis!.summary.isNotEmpty ||
            _currentAnalysis!.detailedAnalysis.isNotEmpty ||
            _currentAnalysis!.actionSuggestions.isNotEmpty)
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
          Text(
            _errorMsg!,
            style: AppStyles.bodyBold.copyWith(color: AppColors.alert, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          _buildRescanButton(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        SizedBox(width: 12),
        Text(title, style: AppStyles.h2),
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
        _buildSectionHeader("Product Information", Icons.info_outline),
        SizedBox(height: 16),

        if (_currentAnalysis!.detectedAllergens.isNotEmpty) ...[
          _buildInfoCard(
            title: "Allergens",
            content: _currentAnalysis!.detectedAllergens.join(', '),
            icon: Icons.warning,
            color: AppColors.alert,
          ),
          SizedBox(height: 12),
        ],

        _buildInfoCard(
          title: "Ingredients",
          content: _currentAnalysis!.ingredients.isNotEmpty
              ? _currentAnalysis!.ingredients.join(', ')
              : 'No ingredients listed.',
          icon: Icons.list,
          color: AppColors.primary,
        ),
        SizedBox(height: 24),
      ],
    );
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
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Text(title, style: AppStyles.bodyBold.copyWith(color: color)),
            ],
          ),
          SizedBox(height: 8),
          Text(content, style: AppStyles.bodyRegular),
        ],
      ),
    );
  }

  Widget _buildAIInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("AI Nutrition Insights", Icons.psychology),
        SizedBox(height: 16),

        if (_currentAnalysis!.summary.isNotEmpty) ...[
          _buildInsightCard(
            title: "Summary",
            content: _currentAnalysis!.summary,
            icon: Icons.summarize,
          ),
          SizedBox(height: 12),
        ],

        if (_currentAnalysis!.detailedAnalysis.isNotEmpty) ...[
          _buildInsightCard(
            title: "Detailed Analysis",
            content: _currentAnalysis!.detailedAnalysis,
            icon: Icons.analytics,
          ),
          SizedBox(height: 12),
        ],

        if (_currentAnalysis!.actionSuggestions.isNotEmpty) ...[
          _buildInsightCard(
            title: "Recommendations",
            content: _currentAnalysis!.actionSuggestions.map((s) => "• $s").join('\n'),
            icon: Icons.lightbulb,
          ),
        ],
      ],
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: AppColors.primary, size: 16),
              ),
              SizedBox(width: 8),
              Text(title, style: AppStyles.bodyBold.copyWith(color: AppColors.primary)),
            ],
          ),
          SizedBox(height: 12),
          Text(content, style: AppStyles.bodyRegular),
        ],
      ),
    );
  }

  Widget _buildRescanButton() {
    return ElevatedButton.icon(
      onPressed: () async {
        await _controller?.stop();
        setState(() {
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
        await _controller?.start();
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
}