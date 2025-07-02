import 'package:flutter/material.dart';

/// 应用主题配置
/// 符合DEVELOPMENT_STANDARDS.md中定义的UI设计规范
class AppTheme {
  // 颜色系统
  static const Color primaryGreen = Color(0xFF4CAF50);      // 主绿色
  static const Color primaryLight = Color(0xFFE8F5E8);      // 浅绿色
  static const Color primaryDark = Color(0xFF2E7D32);       // 深绿色
  static const Color backgroundWhite = Color(0xFFFFFFFF);   // 白色背景
  static const Color textSecondary = Color(0xFF757575);     // 次要文字
  static const Color accentOrange = Color(0xFFFF9800);      // 强调橙色
  static const Color successGreen = Color(0xFF4CAF50);      // 成功绿色
  static const Color errorRed = Color(0xFFF44336);          // 错误红色

  /// 主题数据
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // 颜色方案
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: primaryDark,
        surface: backgroundWhite,
        error: errorRed,
        brightness: Brightness.light,
      ),

      // AppBar主题
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: backgroundWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: backgroundWhite,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // 卡片主题
      cardTheme: CardThemeData(
        color: backgroundWhite,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),

      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: backgroundWhite,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(double.infinity, 48),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // 次要按钮主题
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: primaryDark,
          side: const BorderSide(color: primaryDark),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(double.infinity, 48),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: primaryLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorRed),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // 文本主题
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primaryDark,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: primaryDark,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primaryDark,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryDark,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: primaryDark,
        ),
        titleSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: primaryDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: primaryDark,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: primaryDark,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: primaryDark,
        ),
      ),

      // 浮动操作按钮主题
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: backgroundWhite,
        elevation: 4,
      ),

      // 底部导航栏主题
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundWhite,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // 进度指示器主题
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGreen,
        linearTrackColor: primaryLight,
        circularTrackColor: primaryLight,
      ),

      // 分割线主题
      dividerTheme: DividerThemeData(
        color: textSecondary.withOpacity(0.2),
        thickness: 1,
        space: 1,
      ),

      // Scaffold主题
      scaffoldBackgroundColor: backgroundWhite,
    );
  }

  /// 暗色主题（可选）
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.dark,
      ),
    );
  }

  /// 渐变装饰
  static BoxDecoration get primaryGradientDecoration {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryGreen, primaryDark],
      ),
    );
  }

  /// 卡片阴影
  static List<BoxShadow> get cardShadow {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// 按钮圆角
  static BorderRadius get buttonBorderRadius => BorderRadius.circular(8);

  /// 卡片圆角
  static BorderRadius get cardBorderRadius => BorderRadius.circular(12);

  /// 常用间距
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 32;

  /// 图标尺寸
  static const double iconSizeS = 16;
  static const double iconSizeM = 24;
  static const double iconSizeL = 32;
  static const double iconSizeXL = 48;
}