# 调试代码备份记录

## 文件: /mnt/d/g5/g5/lib/presentation/screens/analysis/analysis_result_screen.dart

### 原始 _onBarcodeScanned 函数 (第66-110行)

```dart
Future<void> _onBarcodeScanned(BarcodeCapture capture) async {
  if (capture.barcodes.isEmpty) return;

  final rawCode = capture.barcodes.first.rawValue?.trim();
  if (rawCode == null || rawCode.isEmpty || _isLoading) return;

  setState(() {
    _isLoading = true;
    _receiptItems = [];
    _scannedOnce = true;
  });

  try {
    final product = await fetchProductByBarcode(rawCode);
    setState(() {
      _currentAnalysis = product;
    });

    // 产品信息获取成功后，立即获取推荐
    _getRecommendations(rawCode);
  } catch (e) {
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
```

## 调试修改说明

### 第一阶段：调试代码
- 添加了详细的控制台日志输出
- 记录平台信息、扫描数据格式、条码内容等
- 用于对比Android端和Chrome端的差异

### 第二阶段：性能优化
- 添加了扫描控制器管理
- 实现了防重复扫描机制
- 针对Web端优化了检测速度设置
- 添加了资源清理和生命周期管理

## 回归步骤

调试完成后，将上述原始代码替换回文件中对应位置。