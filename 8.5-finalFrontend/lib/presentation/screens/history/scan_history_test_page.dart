import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../../services/api.dart';
import '../../../services/user_service.dart';

class ScanHistoryTestPage extends StatefulWidget {
  const ScanHistoryTestPage({Key? key}) : super(key: key);

  @override
  _ScanHistoryTestPageState createState() => _ScanHistoryTestPageState();
}

class _ScanHistoryTestPageState extends State<ScanHistoryTestPage> {
  String _testResults = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Scan History API Test', style: AppStyles.h2.copyWith(color: AppColors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: BackButton(color: AppColors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test New Scan History APIs',
              style: AppStyles.h2,
            ),
            SizedBox(height: 16),
            
            // Test buttons
            _buildTestButton(
              'Test getScanHistoryList',
              _testGetScanHistoryList,
            ),
            SizedBox(height: 8),
            
            _buildTestButton(
              'Test getScanHistoryProductDetails',
              _testGetScanHistoryProductDetails,
            ),
            SizedBox(height: 8),
            
            _buildTestButton(
              'Test Raw APIs',
              _testRawAPIs,
            ),
            SizedBox(height: 16),
            
            // Loading indicator
            if (_isLoading) ...[
              Center(child: CircularProgressIndicator(color: AppColors.primary)),
              SizedBox(height: 16),
            ],
            
            // Results
            Text(
              'Test Results:',
              style: AppStyles.bodyBold,
            ),
            SizedBox(height: 8),
            
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResults.isEmpty ? 'No test results yet...' : _testResults,
                    style: AppStyles.bodyRegular.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String title, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(title),
      ),
    );
  }

  Future<void> _testGetScanHistoryList() async {
    setState(() {
      _isLoading = true;
      _testResults = '';
    });

    try {
      _addTestResult('🔍 Testing getScanHistoryList...');
      
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) {
        _addTestResult('❌ Error: User not logged in');
        return;
      }
      
      _addTestResult('👤 User ID: $userId');
      
      final response = await getScanHistoryList(
        userId: userId,
        page: 1,
        limit: 5,
      );
      
      if (response != null) {
        _addTestResult('✅ API call successful');
        _addTestResult('📊 Items received: ${response.items.length}');
        _addTestResult('📄 Pagination: ${response.pagination.currentPage}/${response.pagination.totalPages}');
        
        if (response.items.isNotEmpty) {
          _addTestResult('📋 First item:');
          final item = response.items.first;
          _addTestResult('   - Scan ID: ${item.scanId}');
          _addTestResult('   - Product: ${item.productName}');
          _addTestResult('   - Brand: ${item.brand ?? 'N/A'}');
          _addTestResult('   - Scanned: ${item.scannedAt}');
        }
      } else {
        _addTestResult('❌ API returned null');
      }
      
    } catch (e) {
      _addTestResult('❌ Exception: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetScanHistoryProductDetails() async {
    setState(() {
      _isLoading = true;
      _testResults = '';
    });

    try {
      _addTestResult('🔍 Testing getScanHistoryProductDetails...');
      
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) {
        _addTestResult('❌ Error: User not logged in');
        return;
      }
      
      _addTestResult('👤 User ID: $userId');
      
      // Test with a mock scan ID
      const testScanId = 12345;
      _addTestResult('🔍 Testing with Scan ID: $testScanId');
      
      final response = await getScanHistoryProductDetails(
        scanId: testScanId,
        userId: userId,
      );
      
      if (response != null) {
        _addTestResult('✅ API call successful');
        _addTestResult('📊 Product Details:');
        _addTestResult('   - Scan ID: ${response.scanId}');
        _addTestResult('   - Recommendation ID: ${response.recommendationId}');
        _addTestResult('   - Product Name: ${response.productInfo.name}');
        _addTestResult('   - Brand: ${response.productInfo.brand ?? 'N/A'}');
        _addTestResult('   - Barcode: ${response.productInfo.barcode}');
        _addTestResult('   - Allergens: ${response.productInfo.allergens.length}');
        _addTestResult('   - Recommendations: ${response.recommendations.length}');
      } else {
        _addTestResult('❌ API returned null (expected for test data)');
      }
      
    } catch (e) {
      _addTestResult('❌ Exception: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testRawAPIs() async {
    setState(() {
      _isLoading = true;
      _testResults = '';
    });

    try {
      _addTestResult('🔍 Testing Raw APIs...');
      
      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) {
        _addTestResult('❌ Error: User not logged in');
        return;
      }
      
      _addTestResult('👤 User ID: $userId');
      
      // Test raw scan history list
      _addTestResult('🔍 Testing getScanHistoryListRaw...');
      final rawList = await getScanHistoryListRaw(
        userId: userId,
        page: 1,
        limit: 3,
      );
      
      if (rawList != null) {
        _addTestResult('✅ Raw list API successful');
        _addTestResult('📊 Raw data keys: ${rawList.keys.toList()}');
      } else {
        _addTestResult('❌ Raw list API returned null');
      }
      
      // Test raw product details
      _addTestResult('🔍 Testing getScanHistoryProductDetailsRaw...');
      final rawDetails = await getScanHistoryProductDetailsRaw(
        scanId: 12345,
        userId: userId,
      );
      
      if (rawDetails != null) {
        _addTestResult('✅ Raw details API successful');
        _addTestResult('📊 Raw data keys: ${rawDetails.keys.toList()}');
      } else {
        _addTestResult('❌ Raw details API returned null (expected for test data)');
      }
      
    } catch (e) {
      _addTestResult('❌ Exception: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addTestResult(String message) {
    setState(() {
      _testResults += '$message\n';
    });
  }
}