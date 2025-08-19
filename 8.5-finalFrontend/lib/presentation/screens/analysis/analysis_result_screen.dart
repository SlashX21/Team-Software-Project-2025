import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../domain/entities/product_analysis.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../theme/screen_adapter.dart';
import '../../theme/responsive_layout.dart';
import '../../widgets/adaptive_widgets.dart';
import '../../../services/api.dart';
import '../../../services/user_service.dart';
import '../../../domain/entities/recommendation_response.dart';
import '../product/product_detail_page.dart';


class AnalysisResultScreen extends StatefulWidget {
  final ProductAnalysis? productAnalysis;

  const AnalysisResultScreen({Key? key, this.productAnalysis}) : super(key: key);

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  ProductAnalysis? _currentAnalysis;
  List<Map<String, dynamic>> _receiptItems = [];
  bool _showScanner = false;
  bool _isLoading = false;
  bool _scannedOnce = false;
  
  // 扫描控制器
  MobileScannerController? _scannerController;
  bool _scannerStarted = false;
  String? _lastScannedCode;
  DateTime? _lastScanTime;

  // 推荐功能相关状态
  RecommendationResponse? _recommendationData;
  bool _isLoadingRecommendation = false;
  String? _recommendationError;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }
  
  void _initializeScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: kIsWeb 
          ? DetectionSpeed.normal  // Web端使用普通速度，避免过度处理
          : DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
      returnImage: false, // 不返回图像数据以提升性能
    );
  }
  
  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  /// 重置所有扫描相关状态到初始状态
  void _resetScanningState() {
    setState(() {
      _currentAnalysis = null;
      _receiptItems.clear();
      _showScanner = false;
      _isLoading = false;
      _scannedOnce = false;

      // 重置推荐相关状态
      _recommendationData = null;
      _isLoadingRecommendation = false;
      _recommendationError = null;
    });
  }

  /// 开始扫描，清除之前的状态并启动扫描器
  void _startScanning() {
    setState(() {
      _currentAnalysis = null;
      _receiptItems.clear();
      _showScanner = true;
      _isLoading = false;
      _scannedOnce = false;
    });
  }

  Future<void> _onBarcodeScanned(BarcodeCapture capture) async {
    print('=== BARCODE SCAN DEBUG ===');
    print('Platform: ${Theme.of(context).platform}');
    print('Total barcodes detected: ${capture.barcodes.length}');
    
    if (capture.barcodes.isEmpty) {
      print('No barcodes detected - returning early');
      return;
    }

    for (int i = 0; i < capture.barcodes.length; i++) {
      final barcode = capture.barcodes[i];
      print('Barcode $i:');
      print('  - Raw Value: "${barcode.rawValue}"');
      print('  - Display Value: "${barcode.displayValue}"');
      print('  - Format: ${barcode.format}');
      print('  - Corners: ${barcode.corners}');
    }

    final rawCode = capture.barcodes.first.rawValue?.trim();
    print('Final processed code: "$rawCode"');
    
    if (rawCode == null || rawCode.isEmpty || _isLoading) {
      print('Code validation failed - rawCode: $rawCode, isLoading: $_isLoading');
      return;
    }
    
    // 防重复扫描：检查是否是相同条码且时间间隔太短
    final now = DateTime.now();
    if (_lastScannedCode == rawCode && 
        _lastScanTime != null && 
        now.difference(_lastScanTime!).inSeconds < 3) {
      print('Duplicate scan ignored - same code within 3 seconds');
      return;
    }
    
    _lastScannedCode = rawCode;
    _lastScanTime = now;

    setState(() {
      _isLoading = true;
      _receiptItems = [];
      _scannedOnce = true;
    });

    try {
      print('Calling fetchProductByBarcode with: "$rawCode"');
      final userId = await UserService.instance.getCurrentUserId() ?? 0;
      final product = await fetchProductByBarcode(rawCode, userId);
      print('API call successful - Product: ${product.name}');
      setState(() {
        _currentAnalysis = product;
      });

      // 产品信息获取成功后，立即获取推荐
      _getRecommendations(rawCode);
    } catch (e) {
      print('API call failed - Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Scan failed: Unable to find product information',
                  style: TextStyle(color: AppColors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.alert,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 导航到产品详情页面
  void _navigateToProductDetail() {
    if (_currentAnalysis == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(
          barcode: _lastScannedCode,
          productAnalysis: _currentAnalysis,
          productData: {
            'name': _currentAnalysis!.name,
            'ingredients': _currentAnalysis!.ingredients,
            'allergens': _currentAnalysis!.detectedAllergens,
          },
        ),
      ),
    );
  }

  /// 获取商品推荐
  Future<void> _getRecommendations(String barcode) async {
    // 推荐数据已经集成在fetchProductByBarcode中，这里不需要单独获取
    // 只需要从推荐系统获取推荐产品列表数据
    if (_isLoadingRecommendation) return;

    setState(() {
      _isLoadingRecommendation = true;
      _recommendationError = null;
      _recommendationData = null;
    });

    try {
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) {
        setState(() {
          _recommendationError = "用户未登录，无法获取推荐";
          _isLoadingRecommendation = false;
        });
        return;
      }

      print('🔍 Analysis: Fetching recommendation data for barcode: $barcode');
      final recommendationData = await getBarcodeRecommendation(userId, barcode);
      
      print('🔍 Analysis: Raw recommendation response: $recommendationData');

      if (recommendationData != null) {
        // 直接使用返回的数据构建推荐响应
        final responseData = {
          'success': true,
          'message': 'Recommendations retrieved successfully',
          'data': recommendationData,
        };

      setState(() {
          _recommendationData = RecommendationResponse.fromJson(responseData);
        _isLoadingRecommendation = false;
      });
        
        print('✅ Analysis: Successfully parsed ${_recommendationData?.data?.recommendations?.length ?? 0} recommendations');
      } else {
        setState(() {
          _recommendationData = null;
          _isLoadingRecommendation = false;
        });
        print('⚠️ Analysis: No recommendation data received');
      }
    } catch (e) {
      setState(() {
        _recommendationError = e.toString();
        _isLoadingRecommendation = false;
      });
      print('❌ Analysis: Error fetching recommendations: $e');
    }
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
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      final result = await uploadReceiptImage(picked, userId);
      final products = result['data']?['products'];

      if (products is List) {
        _receiptItems = List<Map<String, dynamic>>.from(products);
      } else {
        throw Exception('Invalid response format.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Upload failed: Please check your image and try again',
                  style: TextStyle(color: AppColors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.alert,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _receiptItems.isNotEmpty ? 'Receipt Analysis' : 'Product Analysis',
              style: AppStyles.h2.copyWith(color: AppColors.white),
            ),
            if (_currentAnalysis != null && !_showScanner)
              Text(
                _currentAnalysis!.name,
                style: AppStyles.bodyRegular.copyWith(
                  color: AppColors.white.withOpacity(0.8),
                ),
              ),
          ],
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: BackButton(color: AppColors.white),
      ),
      body: Column(
        children: [
          _showScanner
              ? Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  onDetect: _onBarcodeScanned,
                  controller: _scannerController,
                ),
                // 半透明遮罩
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Container(
                      margin: EdgeInsets.all(40.r),
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            size: 48,
                            color: AppColors.primary,
                          ),
                          AdaptiveSpacing.vertical(12),
                          AdaptiveText(
                            text: 'Scanning...',
                            style: AppStyles.bodyBold,
                            useResponsiveFontSize: true,
                          ),
                          AdaptiveSpacing.vertical(8),
                          AdaptiveText(
                            text: 'Point camera at barcode',
                            style: AppStyles.bodyRegular,
                            textAlign: TextAlign.center,
                            useResponsiveFontSize: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 取消按钮
                Positioned(
                  top: 40,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _resetScanningState,
                      icon: Icon(Icons.close, color: AppColors.textDark),
                    ),
                  ),
                ),
              ],
            ),
          )
              : _buildScannerUI(),

          if (_isLoading)
            AdaptiveCard(
              margin: EdgeInsets.all(20.r),
              padding: EdgeInsets.all(20.r),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AdaptiveLoadingIndicator(
                    size: 20,
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                  AdaptiveSpacing.horizontal(16),
                  AdaptiveText(
                    text: _receiptItems.isEmpty && _currentAnalysis == null
                        ? 'Processing...'
                        : 'Analyzing product...',
                    style: AppStyles.bodyRegular,
                    useResponsiveFontSize: true,
                  ),
                ],
              ),
            )
          else
            Expanded(child: _buildAnalysisResult()),
        ],
      ),
    );
  }

  Widget _buildScannerUI() {
    return AdaptiveCard(
      margin: EdgeInsets.all(16.r),
      padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.qr_code_scanner,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            AdaptiveSpacing.vertical(16),
            AdaptiveText(
              text: 'Scan Product Barcode',
              style: AppStyles.h2,
              textAlign: TextAlign.center,
              useResponsiveFontSize: true,
            ),
            AdaptiveSpacing.vertical(8),
            AdaptiveText(
              text: 'Get AI-powered nutrition analysis and personalized recommendations',
              style: AppStyles.bodyRegular.copyWith(
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
              useResponsiveFontSize: true,
            ),
            AdaptiveSpacing.vertical(24),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _startScanning,
                    icon: Icon(Icons.qr_code_scanner, size: 20),
                    label: Text("Start Scanning"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      elevation: 2,
                      shadowColor: AppColors.primary.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ).copyWith(
                      elevation: MaterialStateProperty.resolveWith<double?>(
                            (Set<MaterialState> states) {
                          if (states.contains(MaterialState.pressed)) return 0;
                          if (states.contains(MaterialState.hovered)) return 4;
                          return 2;
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _uploadReceipt,
                    icon: Icon(Icons.upload_file, size: 20),
                    label: Text("Receipt Upload"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.background,
                      foregroundColor: AppColors.primary,
                      elevation: 1,
                      shadowColor: AppColors.primary.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ).copyWith(
                      elevation: MaterialStateProperty.resolveWith<double?>(
                            (Set<MaterialState> states) {
                          if (states.contains(MaterialState.pressed)) return 0;
                          if (states.contains(MaterialState.hovered)) return 2;
                          return 1;
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }

  Widget _buildAnalysisResult() {
    if (_receiptItems.isNotEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                        Icons.receipt_long, color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    Text('Receipt Analysis', style: AppStyles.h2),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Items purchased: ${_receiptItems.length}',
                  style: AppStyles.bodyRegular,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                        Icons.shopping_bag, color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    Text('Purchased Items', style: AppStyles.bodyBold),
                  ],
                ),
                const SizedBox(height: 16),
                ..._receiptItems.map((item) =>
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.shopping_cart_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'],
                                  style: AppStyles.bodyBold,
                                ),
                                Text(
                                  "Qty: ${item['quantity']}",
                                  style: AppStyles.bodyRegular,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
              ],
            ),
          ),
        ],
      );
    }

    if (_currentAnalysis == null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _scannedOnce ? Icons.search_off : Icons.qr_code_scanner,
                size: 64,
                color: AppColors.textLight,
              ),
              const SizedBox(height: 16),
              Text(
                _scannedOnce
                    ? 'No product information found'
                    : 'Ready to scan',
                style: AppStyles.bodyBold,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _scannedOnce
                    ? 'The scanned barcode doesn\'t match any product in our database. Try scanning another product.'
                    : 'Scan a product barcode or upload a receipt to get started',
                style: AppStyles.bodyRegular,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(_currentAnalysis!.name, style: AppStyles.h1)),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToProductDetail(),
                    icon: Icon(Icons.visibility, size: 16),
                    label: Text("详情", style: AppStyles.bodyRegular),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size(0, 32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_currentAnalysis!.detectedAllergens.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.alert.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.alert.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: AppColors.alert, size: 20),
                          const SizedBox(width: 8),
                          Text("Allergens", style: AppStyles.bodyBold),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentAnalysis!.detectedAllergens.join(', '),
                        style: AppStyles.bodyRegular.copyWith(
                            color: AppColors.alert),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                            Icons.list_alt, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text("Product Ingredients", style: AppStyles.bodyBold),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentAnalysis!.ingredients.isNotEmpty
                          ? _currentAnalysis!.ingredients.join(', ')
                          : 'No ingredients listed.',
                      style: AppStyles.bodyRegular,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 推荐功能区域
        _buildRecommendationSection(),
      ],
    );
  }

  /// 推荐功能主入口组件
  Widget _buildRecommendationSection() {
      return Column(
        children: [
        // 始终显示AI营养分析
          _buildLLMAnalysisCard(),
        // 只有在有推荐数据时才显示推荐列表
        if (_recommendationData != null && _recommendationData!.data?.recommendations.isNotEmpty == true)
          _buildRecommendationsList(),
        // 如果正在加载推荐，显示加载状态（但AI分析已经可见）
        if (_isLoadingRecommendation && _recommendationData == null)
          _buildRecommendationLoading(),
        // 如果推荐失败，显示错误（但AI分析已经可见）
        if (_recommendationError != null && _recommendationData == null)
          _buildRecommendationError(),
      ],
    );
  }

  /// 推荐加载状态组件
  Widget _buildRecommendationLoading() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '正在获取个性化推荐...',
                style: AppStyles.bodyRegular,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '这可能需要一些时间，请耐心等待',
            style: AppStyles.bodyRegular.copyWith(
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 推荐错误状态组件
  Widget _buildRecommendationError() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: AppColors.alert, size: 48),
          const SizedBox(height: 16),
              Text(
            _recommendationError ?? 'Unable to load recommendations',
            style: AppStyles.bodyRegular.copyWith(color: AppColors.alert),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 推荐列表组件 - 修正数据访问逻辑
  Widget _buildRecommendationsList() {
    // 检查推荐数据
    final recommendationData = _recommendationData?.data;
    if (recommendationData == null) {
      print('❌ Analysis: No recommendation data available');
      return _buildRecommendationFallback();
    }

    final recommendations = recommendationData.recommendations;
    if (recommendations.isEmpty) {
      print('⚠️ Analysis: Empty recommendations list');
      return _buildRecommendationFallback();
    }

    print('✅ Analysis: Displaying ${recommendations.length} recommendations');

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.recommend, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              Text('Smart Recommendations', style: AppStyles.h2),
              const Spacer(),
              // 推荐数量标识
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${recommendations.length} found',
                  style: AppStyles.bodyRegular.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendations.map((recommendation) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Rank badge
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                          child: Text(
                            '#${recommendation.rank}',
                            style: AppStyles.bodyBold.copyWith(
                              color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Product name and brand
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recommendation.productInfo.name,
                                style: AppStyles.bodyBold,
                              ),
                              if (recommendation.productInfo.brand != null &&
                                  recommendation.productInfo.brand!.isNotEmpty)
                                Text(
                                  recommendation.productInfo.brand!,
                                  style: AppStyles.bodyRegular.copyWith(
                                    color: AppColors.textLight,
                                  ),
                                ),
                              const SizedBox(height: 2),
                              // Barcode display
                              Row(
                                children: [
                                  Icon(Icons.qr_code, size: 14, color: AppColors.textLight),
                                  const SizedBox(width: 4),
                                  Text(
                                    recommendation.productInfo.barcode ?? 'No barcode',
                                    style: AppStyles.bodyRegular.copyWith(
                                      color: AppColors.textLight,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                                ),
                              const SizedBox(height: 4),
                              // Nutrition summary
                              Text(
                                recommendation.productInfo.getSummaryText(),
                                style: AppStyles.bodyRegular.copyWith(
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Score
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Score: ${(recommendation.score * 100).toStringAsFixed(0)}',
                            style: AppStyles.bodyBold.copyWith(
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 移除推荐理由显示 - 只在详情页显示推荐理由
                    // 注释掉原本的推荐理由显示代码
                    // Container(
                    //   padding: const EdgeInsets.all(8),
                    //   decoration: BoxDecoration(
                    //     color: Colors.green.withOpacity(0.1),
                    //     borderRadius: BorderRadius.circular(6),
                    //   ),
                    //   child: Row(
                    //     children: [
                    //       Icon(Icons.recommend, color: Colors.green, size: 16),
                    //       const SizedBox(width: 6),
                    //       Expanded(
                    //         child: Text(
                    //           recommendation.reason,
                    //           style: AppStyles.bodyRegular.copyWith(
                    //             color: Colors.green.shade800,
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              )).toList(),
        ],
      ),
    );
  }

  /// 推荐数据不可用时的后备显示
  Widget _buildRecommendationFallback() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 48),
          const SizedBox(height: 16),
                    Container(
            padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                Icon(Icons.shopping_cart, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                    'AI recommendations currently unavailable. The system needs more product data to provide personalized suggestions for this category.',
                    style: AppStyles.bodyRegular.copyWith(color: Colors.blue.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
        ],
      ),
    );
  }

  /// 结构化LLM分析结果显示 - 固定格式，显示所有字段状态
  Widget _buildLLMAnalysisCard() {
    // 总是显示AI Analysis卡片，不进行任何数据验证
    if (_currentAnalysis == null) {
      return const SizedBox.shrink();
    }

    // 获取原始数据，不做任何过滤或验证
    final summary = _currentAnalysis!.summary;
    final detailedAnalysis = _currentAnalysis!.detailedAnalysis;
    final actionSuggestions = _currentAnalysis!.actionSuggestions;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              Text('AI Analysis', style: AppStyles.h2),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Structured View',
                      style: AppStyles.bodyRegular.copyWith(
                    color: Colors.purple.shade700,
                        fontWeight: FontWeight.w600,
                  ),
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 16),

          // 扫描页面简化显示：只显示Summary
          _buildAnalysisField(
            icon: Icons.summarize,
            title: 'Summary',
            content: summary,
            color: Colors.orange,
            fieldKey: 'summary',
              ),
            ],
          ),
    );
  }

  /// 构建单个分析字段显示
  Widget _buildAnalysisField({
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
            padding: const EdgeInsets.all(12),
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
              const SizedBox(width: 6),
                Text(
                title,
                  style: AppStyles.bodyBold.copyWith(
                  color: isMeaningful ? color : Colors.grey.shade600,
                  ),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(isMeaningful, hasContent).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(isMeaningful, hasContent),
                      size: 12,
                      color: _getStatusColor(isMeaningful, hasContent),
                    ),
                    const SizedBox(width: 4),
                Text(
                      _getStatusText(isMeaningful, hasContent),
                  style: AppStyles.bodyRegular.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(isMeaningful, hasContent),
                  ),
                ),
              ],
            ),
          ),
            ],
            ),
            const SizedBox(height: 8),
          
          // 字段内容
          if (isMeaningful) ...[
            if (isList && listItems != null && listItems.isNotEmpty) ...[
              ...listItems.map((item) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.arrow_right, color: color, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item,
                          style: AppStyles.bodyRegular,
                        ),
                      ),
                    ],
                  ),
                ),
              ).toList(),
            ] else ...[
              Text(
                content,
                style: AppStyles.bodyRegular,
              ),
            ],
          ] else ...[
            Text(
              hasContent ? 'Placeholder content: "$content"' : 'No data available',
              style: AppStyles.bodyRegular.copyWith(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
          
        ],
      ),
    );
  }

  /// 获取状态颜色
  Color _getStatusColor(bool isMeaningful, bool hasContent) {
    if (isMeaningful) return Colors.green;
    if (hasContent) return Colors.orange;
    return Colors.grey;
  }

  /// 获取状态图标
  IconData _getStatusIcon(bool isMeaningful, bool hasContent) {
    if (isMeaningful) return Icons.check_circle;
    if (hasContent) return Icons.warning;
    return Icons.help_outline;
  }

  /// 获取状态文本
  String _getStatusText(bool isMeaningful, bool hasContent) {
    if (isMeaningful) return 'DATA';
    if (hasContent) return 'PLACEHOLDER';
    return 'EMPTY';
  }
}