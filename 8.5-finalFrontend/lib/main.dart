import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'presentation/screens/auth_page.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/theme/app_colors.dart';
import 'presentation/theme/app_styles.dart';
import 'presentation/theme/screen_adapter.dart';
import 'presentation/theme/responsive_layout.dart';
import 'presentation/widgets/adaptive_widgets.dart';
import 'services/cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🔧 全局溢出处理 - 隐藏溢出警告条纹
  debugPaintSizeEnabled = false;
  
  // 🔧 初始化增强的屏幕适配器
  // 支持Mobile/Tablet/Desktop多断点智能适配
  ScreenAdapter.instance.init(
    designWidth: 375,  // 移动端基准宽度
    designHeight: 812, // 移动端基准高度
  );
  
  // 打印适配器信息用于调试
  ScreenAdapter.instance.printAdapterInfo();
  
  // 初始化缓存服务
  final cache = CacheService();
  await cache.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grocery Guardian',
      debugShowCheckedModeBanner: false,
      // 🔧 增强的全局适配处理器
      builder: (context, child) {
        // 从 context 初始化适配器（兜底方案）
        ScreenAdapter.instance.initFromContext(context);
        final adapter = ScreenAdapter.instance;
        
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // 智能字体缩放：根据设备类型和屏幕特性调整
            textScaleFactor: _calculateTextScaleFactor(context, adapter),
          ),
          child: child!,
        );
      },
      theme: _buildAdaptiveTheme(context),
      // 🔧 支持深色主题（未来扩展）
      // darkTheme: _buildAdaptiveDarkTheme(context),
      home: const SplashScreen(),
    );
  }

  /// 🔧 计算智能字体缩放因子
  static double _calculateTextScaleFactor(BuildContext context, ScreenAdapter adapter) {
    final mediaQuery = MediaQuery.of(context);
    final systemTextScale = mediaQuery.textScaleFactor;
    final responsiveScale = adapter.getResponsiveFontScale();
    
    // 组合系统字体缩放和响应式缩放
    double combinedScale = systemTextScale * responsiveScale;
    
    // 根据设备类型设置合理的缩放范围
    switch (adapter.deviceType) {
      case DeviceType.mobile:
        return combinedScale.clamp(0.8, 1.3);
      case DeviceType.tablet:
        return combinedScale.clamp(0.9, 1.2);
      case DeviceType.desktop:
        return combinedScale.clamp(1.0, 1.1);
    }
  }
  
  /// 🔧 构建自适应主题
  static ThemeData _buildAdaptiveTheme(BuildContext context) {
    final adapter = ScreenAdapter.instance;
    
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Poppins',
      
      // 🔧 设备特定的视觉密度
      visualDensity: _getAdaptiveVisualDensity(adapter),
      
      // 🔧 智能响应式文本主题
      textTheme: _buildSmartTextTheme(context, adapter),
      
      // 🔧 自适应AppBar主题
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: adapter.isDesktop ? 1 : 0,
        titleTextStyle: AppStyles.h2.copyWith(
          color: AppColors.white,
          fontSize: ResponsiveFontSizes.lg.getValue(context),
        ),
        toolbarHeight: adapter.isDesktop ? 64 : (adapter.isTablet ? 60 : 56),
      ),
      
      // 🔧 自适应按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          textStyle: AppStyles.buttonText.copyWith(
            fontSize: ResponsiveFontSizes.base.getValue(context),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveSpacing.md.getValue(context),
            vertical: ResponsiveSpacing.sm.getValue(context),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: adapter.setBorderRadius(12),
          ),
          elevation: adapter.isDesktop ? 1 : 2,
        ),
      ),
      
      // 🔧 自适应卡片主题
      cardTheme: CardThemeData(
        elevation: adapter.isDesktop ? 2 : (adapter.isTablet ? 4 : 6),
        shape: RoundedRectangleBorder(
          borderRadius: adapter.setBorderRadius(12),
        ),
        margin: EdgeInsets.symmetric(
          horizontal: adapter.safeHorizontalPadding,
          vertical: ResponsiveSpacing.xs.getValue(context),
        ),
      ),
      
      // 🔧 自适应对话框主题
      dialogTheme: DialogThemeData(
        elevation: adapter.isDesktop ? 8 : 16,
        shape: RoundedRectangleBorder(
          borderRadius: adapter.setBorderRadius(16),
        ),
        insetPadding: EdgeInsets.all(
          adapter.isDesktop ? 48 : (adapter.isTablet ? 32 : 16),
        ),
      ),
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        surface: AppColors.background,
      ),
      useMaterial3: true,
    );
  }
  
  /// 🔧 获取自适应视觉密度
  static VisualDensity _getAdaptiveVisualDensity(ScreenAdapter adapter) {
    switch (adapter.deviceType) {
      case DeviceType.mobile:
        return adapter.isNarrowScreen ? VisualDensity.compact : VisualDensity.standard;
      case DeviceType.tablet:
        return VisualDensity.comfortable;
      case DeviceType.desktop:
        return VisualDensity.comfortable;
    }
  }
  
  /// 🔧 构建智能响应式文本主题
  static TextTheme _buildSmartTextTheme(BuildContext context, ScreenAdapter adapter) {
    // 使用ResponsiveFontSizes类提供的预设尺寸
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: ResponsiveFontSizes.xxl.getValue(context) * 2.4,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.25,
        height: adapter.isDesktop ? 1.2 : 1.15,
      ),
      displayMedium: TextStyle(
        fontSize: ResponsiveFontSizes.xxl.getValue(context) * 1.9,
        fontWeight: FontWeight.w300,
        letterSpacing: 0,
        height: adapter.isDesktop ? 1.2 : 1.15,
      ),
      displaySmall: TextStyle(
        fontSize: ResponsiveFontSizes.xxl.getValue(context) * 1.5,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: adapter.isDesktop ? 1.2 : 1.15,
      ),
      headlineLarge: TextStyle(
        fontSize: ResponsiveFontSizes.xl.getValue(context) * 1.6,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: adapter.isDesktop ? 1.3 : 1.25,
      ),
      headlineMedium: TextStyle(
        fontSize: ResponsiveFontSizes.xl.getValue(context) * 1.4,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: adapter.isDesktop ? 1.3 : 1.25,
      ),
      headlineSmall: TextStyle(
        fontSize: ResponsiveFontSizes.xl.getValue(context),
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: adapter.isDesktop ? 1.3 : 1.25,
      ),
      titleLarge: TextStyle(
        fontSize: ResponsiveFontSizes.lg.getValue(context),
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: adapter.isNarrowScreen ? 1.3 : 1.4,
      ),
      titleMedium: TextStyle(
        fontSize: ResponsiveFontSizes.base.getValue(context),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: adapter.isNarrowScreen ? 1.3 : 1.4,
      ),
      titleSmall: TextStyle(
        fontSize: ResponsiveFontSizes.sm.getValue(context),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: adapter.isNarrowScreen ? 1.3 : 1.4,
      ),
      bodyLarge: TextStyle(
        fontSize: ResponsiveFontSizes.base.getValue(context),
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: adapter.isNarrowScreen ? 1.4 : 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: ResponsiveFontSizes.sm.getValue(context),
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: adapter.isNarrowScreen ? 1.4 : 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: ResponsiveFontSizes.xs.getValue(context),
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: adapter.isNarrowScreen ? 1.3 : 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: ResponsiveFontSizes.sm.getValue(context),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontSize: ResponsiveFontSizes.xs.getValue(context),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.3,
      ),
      labelSmall: TextStyle(
        fontSize: ResponsiveFontSizes.xs.getValue(context) * 0.9,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.3,
      ),
    );
  }
}