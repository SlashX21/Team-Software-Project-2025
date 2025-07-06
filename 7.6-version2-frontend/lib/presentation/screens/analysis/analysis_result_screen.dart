import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../domain/entities/product_analysis.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
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
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 检查当前分析数据是否来自真实的LLM服务
  bool _isRealLLMData() {
    final llmAnalysis = _recommendationData?.data?.llmAnalysis;
    if (llmAnalysis == null) return false;
    
    // 检查是否包含fallback内容的特征文本
    final summary = llmAnalysis.summary.toLowerCase();
    final detailedAnalysis = llmAnalysis.detailedAnalysis.toLowerCase(); // This line is now correct
    
    final fallbackKeywords = [
      'temporarily unavailable',
      'basic analysis',
      'ai recommendations currently unavailable',
      'network issues',
      'service unavailable',
      'check your internet connection',
    ];
    
    // 如果包含fallback关键词，说明不是真实LLM数据
    for (final keyword in fallbackKeywords) {
      if (summary.contains(keyword) || detailedAnalysis.contains(keyword)) {
        return false;
      }
    }
    
    // 如果summary或detailedAnalysis为空或过短，可能也是fallback
    if (summary.isEmpty || detailedAnalysis.isEmpty || 
        summary.length < 20 || detailedAnalysis.length < 20) {
      return false;
    }
    
    return true;
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
    // 避免重复请求
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

      final recommendationData = await getBarcodeRecommendation(userId, barcode);

      setState(() {
        _recommendationData = recommendationData != null 
            ? RecommendationResponse.fromJson(recommendationData)
            : null;
        _isLoadingRecommendation = false;
      });
    } catch (e) {
      setState(() {
        _recommendationError = e.toString();
        _isLoadingRecommendation = false;
      });
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
              _receiptItems.isNotEmpty ? 'Receipt Scanner' : 'Product Scanner',
              style: AppStyles.h2.copyWith(color: AppColors.white),
            ),
            if (_currentAnalysis != null && !_showScanner)
              Text(
                _currentAnalysis!.name,
                style: AppStyles.bodyRegular.copyWith(
                  color: AppColors.white.withOpacity(0.8),
                  fontSize: 14,
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
                      margin: const EdgeInsets.all(40),
                      padding: const EdgeInsets.all(20),
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
                          const SizedBox(height: 12),
                          Text(
                            'Scanning...',
                            style: AppStyles.bodyBold,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Point camera at barcode',
                            style: AppStyles.bodyRegular,
                            textAlign: TextAlign.center,
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
            Container(
              margin: const EdgeInsets.all(20),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary),
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _receiptItems.isEmpty && _currentAnalysis == null
                        ? 'Processing...'
                        : 'Analyzing product...',
                    style: AppStyles.bodyRegular,
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
    return Container(
      margin: const EdgeInsets.all(16),
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
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
            const SizedBox(height: 16),
            Text(
              'Scan or upload receipt',
              style: AppStyles.bodyBold,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Analyze ingredients and get health insights',
              style: AppStyles.bodyRegular.copyWith(
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
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
                    Text('Purchase Summary', style: AppStyles.h2),
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
                  Icon(Icons.info_outline, color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  Expanded(child: Text("Product Information", style: AppStyles.h2)),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToProductDetail(),
                    icon: Icon(Icons.visibility, size: 16),
                    label: Text("详情", style: TextStyle(fontSize: 12)),
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
                        Text("Ingredients", style: AppStyles.bodyBold),
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
    if (_isLoadingRecommendation) {
      return _buildRecommendationLoading();
    } else if (_recommendationError != null) {
      return _buildRecommendationError();
    } else if (_recommendationData != null) {
      return Column(
        children: [
          _buildRecommendationsList(),
          _buildLLMAnalysisCard(),
        ],
      );
    }
    // 没有推荐数据时不显示任何内容
    return const SizedBox.shrink();
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
              fontSize: 12,
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
        border: Border.all(
          color: AppColors.alert.withOpacity(0.3),
          width: 1,
        ),
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
              Icon(Icons.error_outline, color: AppColors.alert, size: 24),
              const SizedBox(width: 8),
              Text(
                '推荐获取失败',
                style: AppStyles.bodyBold.copyWith(color: AppColors.alert),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.alert.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _recommendationError!,
              style: AppStyles.bodyRegular.copyWith(
                color: AppColors.alert,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 推荐商品列表组件
  /// 推荐商品列表组件
  Widget _buildRecommendationsList() {
    // Safely get the list of recommendations from the response data
    final recommendations = _recommendationData?.data?.recommendations ?? [];

    if (recommendations.isEmpty) {
      // Display a message if there are no recommendations
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
            Icon(Icons.lightbulb_outline, color: AppColors.textLight, size: 32),
            const SizedBox(height: 8),
            Text(
              'No suitable recommendations found', // Translated
              style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
            ),
          ],
        ),
      );
    }

    // Build the list if there are recommendations
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
              Icon(Icons.lightbulb, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              Text('💡 Recommended Alternatives', style: AppStyles.h2),
              // Translated
            ],
          ),
          const SizedBox(height: 16),
          // Map through the recommendations to create a card for each
          ...recommendations.map((recommendation) =>
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rank
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#${recommendation.rank}',
                            style: AppStyles.bodyBold.copyWith(
                              color: Colors.white,
                              fontSize: 12,
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
                                    fontSize: 12,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              // Nutrition summary
                              Text(
                                recommendation.productInfo.getSummaryText(),
                                style: AppStyles.bodyRegular.copyWith(
                                  color: Colors.green.shade700,
                                  fontSize: 12,
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
                            'Score: ${(recommendation.score * 100)
                                .toStringAsFixed(0)}', // Translated
                            style: AppStyles.bodyBold.copyWith(
                              color: Colors.green.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Recommendation reason
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.recommend, color: Colors.green, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              recommendation.reason,
                              style: AppStyles.bodyRegular.copyWith(
                                fontSize: 12,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )).toList(),
        ],
      ),
    );
  }

  /// LLM分析结果组件
  /// LLM分析结果组件
  Widget _buildLLMAnalysisCard() {
    // Safely get the LLM analysis from the response data
    final llmAnalysis = _recommendationData?.data?.llmAnalysis;

    // If there is no analysis data, show nothing
    if (llmAnalysis == null) {
      return const SizedBox.shrink();
    }

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
              Icon(Icons.psychology, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              Text('AI suggestions', style: AppStyles.h2),
              const Spacer(),
              // Data source indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isRealLLMData() ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isRealLLMData() ? Icons.cloud_done : Icons.cloud_off,
                      size: 12,
                      color: _isRealLLMData() ? Colors.green.shade700 : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isRealLLMData() ? 'AI Active' : 'Basic Mode',
                      style: AppStyles.bodyRegular.copyWith(
                        fontSize: 10,
                        color: _isRealLLMData() ? Colors.green.shade700 : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Analysis Summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis Summary', // Translated
                  style: AppStyles.bodyBold.copyWith(
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  llmAnalysis.summary,
                  style: AppStyles.bodyRegular.copyWith(
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),

          // Action Suggestions
          if (llmAnalysis.actionSuggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Action Suggestions', // Translated
              style: AppStyles.bodyBold.copyWith(
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 8),
            ...llmAnalysis.actionSuggestions.map((suggestion) =>
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: AppStyles.bodyRegular.copyWith(
                            fontSize: 12,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
          ],
        ],
      ),
    );
  }
}