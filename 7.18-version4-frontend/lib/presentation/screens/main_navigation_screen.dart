import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import 'home/home_tab_screen.dart';
import 'scanner/barcode_scanner_screen.dart';
import 'profile/profile_screen.dart';
import 'sugar_tracking/sugar_tracking_page.dart';

class MainNavigationScreen extends StatefulWidget {
  final int userId;

  const MainNavigationScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final Map<int, Widget> _cachedPages = {};

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _getPage(int index) {
    if (!_cachedPages.containsKey(index)) {
      switch (index) {
        case 0:
          _cachedPages[index] = HomeTabScreen(userId: widget.userId);
          break;
        case 1:
          _cachedPages[index] = BarcodeScannerScreen(userId: widget.userId);
          break;
        case 2:
          _cachedPages[index] = SugarTrackingPage();
          break;
        case 3:
          _cachedPages[index] = ProfileScreen();
          break;
        default:
          _cachedPages[index] = HomeTabScreen(userId: widget.userId);
      }
    }
    return _cachedPages[index]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getPage(_currentIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _buildNavItem(0, Icons.home_rounded, 'Home')),
                Expanded(child: _buildNavItem(1, Icons.qr_code_scanner_rounded, 'Scan')),
                Expanded(child: _buildNavItem(2, Icons.monitor_heart_rounded, 'Sugar')),
                Expanded(child: _buildNavItem(3, Icons.person_rounded, 'Profile')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(4),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? AppColors.primary : AppColors.textLight,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: AppStyles.bodyRegular.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textLight,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}