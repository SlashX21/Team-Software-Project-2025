import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../../services/user_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';

class BarcodeDisplayScreen extends StatefulWidget {
  final String barcode;
  final int pointsRedeemed;
  final String userId;

  const BarcodeDisplayScreen({
    Key? key,
    required this.barcode,
    required this.pointsRedeemed,
    required this.userId,
  }) : super(key: key);

  @override
  _BarcodeDisplayScreenState createState() => _BarcodeDisplayScreenState();
}

class _BarcodeDisplayScreenState extends State<BarcodeDisplayScreen> {
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final name = await UserService.instance.getUserName();
    setState(() {
      _userName = name;
    });
  }

  void _copyBarcodeToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.barcode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Barcode copied to clipboard'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Redeem Successful',
          style: AppStyles.h2.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // Success Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Colors.green[600],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Success Message
              Text(
                'Points Redeemed Successfully!',
                style: AppStyles.h2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Points Redeemed
              Text(
                '${widget.pointsRedeemed} points redeemed',
                style: AppStyles.bodyRegular.copyWith(
                  color: Colors.grey[600],
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Scannable Barcode
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    BarcodeWidget(
                      barcode: Barcode.code128(),
                      data: widget.barcode,
                      width: 280,
                      height: 80,
                      color: Colors.black,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _copyBarcodeToClipboard,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: SelectableText(
                                widget.barcode,
                                style: AppStyles.bodySmall.copyWith(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.copy,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // User Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_rounded,
                      size: 32,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _userName != null && _userName!.isNotEmpty
                          ? _userName!
                          : 'User ID: ${widget.userId}',
                      style: AppStyles.bodyBold.copyWith(
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Loyalty Points Account',
                      style: AppStyles.caption.copyWith(
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Back Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_back),
                      const SizedBox(width: 8),
                      Text(
                        'Back to Loyalty Points',
                        style: AppStyles.buttonText.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
} 