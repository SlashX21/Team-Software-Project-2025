import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'home/home_tab_screen.dart';
import 'scanner/barcode_scanner_screen.dart';
import 'profile/profile_screen.dart';

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
          _cachedPages[index] = BarcodeScannerScreen(
            userId: widget.userId,
            onBackToHome: () => _onTabTapped(0), // 添加回到首页的回调
          );
          break;
        case 2:
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
      bottomNavigationBar: SafeArea(
        child: BottomAppBar(
          shape: CircularNotchedRectangle(),
          notchMargin: 8.0,
          color: AppColors.white,
          elevation: 8,
          child: Container(
            padding: EdgeInsets.only(left: 20, right: 20, top: 4, bottom: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _buildNavItem(0, Icons.home_rounded, 'Home')),
                // 当扫描页面激活时，隐藏中间的空白区域，让导航栏更紧凑
                if (_currentIndex != 1) 
                  Expanded(child: SizedBox()) // 空白区域，为FAB留出空间
                else
                  SizedBox(width: 80), // 扫描页面时减少空白区域
                Expanded(child: _buildNavItem(2, Icons.person_rounded, 'Profile')),
              ],
            ),
          ),
        ),
      ),
      // 当扫描页面激活时隐藏FAB
      floatingActionButton: _currentIndex == 1 
          ? null 
          : AnimatedScale(
              scale: _currentIndex == 1 ? 1.3 : 1.0, // 选中时大幅放大
              duration: Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              child: FloatingActionButton.large(
                onPressed: () => _onTabTapped(1),
                backgroundColor: AppColors.primary,
                elevation: _currentIndex == 1 ? 15 : 10, // 选中时阴影更深
                child: AnimatedRotation(
                  turns: _currentIndex == 1 ? 0.15 : 0.0, // 选中时更多旋转
                  duration: Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0), // 垂直padding改成0
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: AnimatedScale(
                scale: isSelected ? 1.8 : 1.0,
                duration: Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                child: Icon(
                  icon,
                  size: 22,
                  color: isSelected ? AppColors.primary : AppColors.textLight,
                ),
              ),
            ),
            SizedBox(height: 2), // 进一步减少间距
            AnimatedDefaultTextStyle(
              duration: Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              style: TextStyle(
                fontSize: isSelected ? 13 : 10,
                color: isSelected ? AppColors.primary : AppColors.textLight,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}