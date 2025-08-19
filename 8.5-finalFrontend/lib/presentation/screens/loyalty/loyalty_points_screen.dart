import 'package:flutter/material.dart';
import '../../../services/api.dart';
import '../../../services/user_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import 'barcode_display_screen.dart';
import '../main_navigation_screen.dart';

class LoyaltyPointsScreen extends StatefulWidget {
  final int userId;

  const LoyaltyPointsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _LoyaltyPointsScreenState createState() => _LoyaltyPointsScreenState();
}

class _LoyaltyPointsScreenState extends State<LoyaltyPointsScreen> {
  int _userPoints = 0;
  bool _isLoading = false;
  bool _userExists = false;
  String _errorMessage = '';
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _checkUserPoints();
  }

  Future<void> _loadUserName() async {
    final name = await UserService.instance.getUserName();
    setState(() {
      _userName = name;
    });
  }

  Future<void> _checkUserPoints() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Convert user ID to string for loyalty API
      final userIdString = widget.userId.toString();
      
      // Check if user exists
      final exists = await checkLoyaltyUserExists(userIdString);
      
      // Get points
      final points = await getLoyaltyUserPoints(userIdString);

      setState(() {
        _userExists = exists;
        _userPoints = points;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _redeemPoints() async {
    if (_userPoints <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No points to redeem'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Show loading dialog with blockchain info
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Processing Redemption'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text(
                  'Redeeming points on blockchain...',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'This may take up to 60 seconds',
                  style: AppStyles.caption.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Current points: $_userPoints',
                  style: AppStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      );

      final userIdString = widget.userId.toString();
      final result = await redeemLoyaltyPoints(userIdString);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result != null) {
        // Navigate to barcode page
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BarcodeDisplayScreen(
                barcode: result['barcode'] ?? '',
                pointsRedeemed: result['points_redeemed'] ?? 0,
                userId: userIdString,
              ),
            ),
          ).then((_) {
            // Refresh points after returning from barcode page
            _checkUserPoints();
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to redeem points'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      String errorMessage = 'Error: $e';
      
      // Handle timeout specifically
      if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Transaction is taking longer than expected. Please try again in a few minutes.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Loyalty Points',
          style: AppStyles.h2.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // User Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey[200]!,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.person_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _userName != null && _userName!.isNotEmpty
                        ? _userName!
                        : 'User ID: ${widget.userId}',
                    style: AppStyles.h3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Loyalty Points Account',
                    style: AppStyles.bodySmall.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

                        // Points Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey[200]!,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48), // Spacer to balance the layout
                      Icon(
                        Icons.stars,
                        size: 48,
                        color: AppColors.primary,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        onPressed: _isLoading ? null : _checkUserPoints,
                        tooltip: 'Refresh Points',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your Loyalty Points',
                    style: AppStyles.h3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    Text(
                      '$_userPoints',
                      style: AppStyles.h1.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 48,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'points available',
                    style: AppStyles.bodySmall.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'equivalent to ${(_userPoints / 10).toStringAsFixed(2)} €',
                    style: AppStyles.caption.copyWith(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Redemption Instructions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'How to Redeem Points',
                        style: AppStyles.h3.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInstructionStep(
                    1,
                    'Earn 1 point for every sustainable product you purchase',
                    Icons.eco,
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionStep(
                    2,
                    'Tap the "Redeem Points" button below',
                    Icons.touch_app,
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionStep(
                    3,
                    'Wait for the barcode to generate (may take up to 60 seconds)',
                    Icons.qr_code,
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionStep(
                    4,
                    'Show the generated barcode to the cashier at any participating store',
                    Icons.store,
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionStep(
                    5,
                    'The cashier will scan your barcode and apply your points discount',
                    Icons.discount,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Redeem Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading || _userPoints <= 0 ? null : _redeemPoints,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.redeem),
                          const SizedBox(width: 8),
                          Text(
                            'Redeem Points',
                            style: AppStyles.buttonText.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Error Message
            if (_errorMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: AppStyles.bodySmall.copyWith(
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(int step, String text, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue[700],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '$step',
              style: AppStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Colors.blue[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: AppStyles.bodySmall.copyWith(
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 