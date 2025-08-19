import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

/// 设备类型枚举
enum DeviceType {
  mobile,    // 手机 (< 600dp)
  tablet,    // 平板 (600-1200dp)
  desktop,   // 桌面 (> 1200dp)
}

/// 屏幕方向枚举
enum ScreenOrientation {
  portrait,   // 竖屏
  landscape,  // 横屏
}

/// 断点配置类
class Breakpoints {
  static const double mobile = 600;    // 手机断点
  static const double tablet = 1200;   // 平板断点
  
  // 响应式字体大小断点
  static const double smallText = 480;
  static const double largeText = 900;
}

/// 全局屏幕适配器
/// 支持多设备类型的智能自适应布局系统
class ScreenAdapter {
  static ScreenAdapter? _instance;
  static ScreenAdapter get instance => _instance ??= ScreenAdapter._();
  
  ScreenAdapter._();
  
  late double _designWidth;
  late double _designHeight;
  late double _pixelRatio;
  late double _screenWidth;
  late double _screenHeight;
  late double _scaleWidth;
  late double _scaleHeight;
  late double _scaleText;
  late DeviceType _deviceType;
  late ScreenOrientation _orientation;
  late double _statusBarHeight;
  late double _bottomBarHeight;
  late EdgeInsets _safeAreaInsets;
  
  /// 初始化屏幕适配
  /// [designWidth] 设计稿宽度，默认375 (移动端)
  /// [designHeight] 设计稿高度，默认812 (移动端)
  void init({
    double designWidth = 375,
    double designHeight = 812,
  }) {
    _designWidth = designWidth;
    _designHeight = designHeight;
    
    final window = ui.PlatformDispatcher.instance.views.first;
    _pixelRatio = window.devicePixelRatio;
    _screenWidth = window.physicalSize.width / _pixelRatio;
    _screenHeight = window.physicalSize.height / _pixelRatio;
    
    // 计算设备类型和方向
    _calculateDeviceTypeAndOrientation();
    
    // 计算安全区域
    _calculateSafeAreaInsets(window);
    
    // 智能缩放策略
    _calculateScaleFactors();
  }
  
  /// 从Context初始化（兜底方案）
  void initFromContext(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _screenWidth = mediaQuery.size.width;
    _screenHeight = mediaQuery.size.height;
    _pixelRatio = mediaQuery.devicePixelRatio;
    
    _designWidth = 375;
    _designHeight = 812;
    
    // 计算设备类型和方向
    _calculateDeviceTypeAndOrientation();
    
    // 从MediaQuery获取安全区域
    _safeAreaInsets = mediaQuery.padding;
    _statusBarHeight = _safeAreaInsets.top;
    _bottomBarHeight = _safeAreaInsets.bottom;
    
    // 智能缩放策略
    _calculateScaleFactors();
  }
  
  /// 计算设备类型和屏幕方向
  void _calculateDeviceTypeAndOrientation() {
    // 判断方向
    _orientation = _screenWidth > _screenHeight 
        ? ScreenOrientation.landscape 
        : ScreenOrientation.portrait;
    
    // 判断设备类型（使用较短边作为判断标准，避免方向影响）
    final shortestSide = math.min(_screenWidth, _screenHeight);
    
    if (shortestSide < Breakpoints.mobile) {
      _deviceType = DeviceType.mobile;
    } else if (shortestSide < Breakpoints.tablet) {
      _deviceType = DeviceType.tablet;
    } else {
      _deviceType = DeviceType.desktop;
    }
  }
  
  /// 计算安全区域信息
  void _calculateSafeAreaInsets(ui.FlutterView window) {
    final padding = window.padding;
    _safeAreaInsets = EdgeInsets.fromViewPadding(padding, _pixelRatio);
    _statusBarHeight = _safeAreaInsets.top;
    _bottomBarHeight = _safeAreaInsets.bottom;
  }
  
  /// 智能缩放策略计算
  void _calculateScaleFactors() {
    switch (_deviceType) {
      case DeviceType.mobile:
        // 移动端：线性缩放
        _scaleWidth = _screenWidth / _designWidth;
        _scaleHeight = _screenHeight / _designHeight;
        _scaleText = _scaleWidth.clamp(0.8, 1.3);
        break;
        
      case DeviceType.tablet:
        // 平板：适度缩放，避免元素过大
        final baseScale = _screenWidth / _designWidth;
        _scaleWidth = 1.0 + (baseScale - 1.0) * 0.6; // 60%的缩放幅度
        _scaleHeight = 1.0 + (_screenHeight / _designHeight - 1.0) * 0.6;
        _scaleText = (baseScale * 0.8).clamp(1.0, 1.4);
        break;
        
      case DeviceType.desktop:
        // 桌面端：保持合理尺寸，主要通过布局而非缩放适配
        final baseScale = _screenWidth / _designWidth;
        _scaleWidth = 1.0 + (baseScale - 1.0) * 0.4; // 更保守的缩放
        _scaleHeight = 1.0 + (_screenHeight / _designHeight - 1.0) * 0.4;
        _scaleText = math.sqrt(baseScale).clamp(1.0, 1.5); // 开方缩放，更平缓
        break;
    }
  }
  
  /// 屏幕宽度
  double get screenWidth => _screenWidth;
  
  /// 屏幕高度  
  double get screenHeight => _screenHeight;
  
  /// 设备像素比
  double get pixelRatio => _pixelRatio;
  
  /// 宽度缩放比例
  double get scaleWidth => _scaleWidth;
  
  /// 高度缩放比例
  double get scaleHeight => _scaleHeight;
  
  /// 文字缩放比例
  double get scaleText => _scaleText;
  
  /// 屏幕宽高比
  double get aspectRatio => _screenHeight / _screenWidth;
  
  /// 设备类型
  DeviceType get deviceType => _deviceType;
  
  /// 屏幕方向
  ScreenOrientation get orientation => _orientation;
  
  /// 是否为移动设备
  bool get isMobile => _deviceType == DeviceType.mobile;
  
  /// 是否为平板设备
  bool get isTablet => _deviceType == DeviceType.tablet;
  
  /// 是否为桌面设备
  bool get isDesktop => _deviceType == DeviceType.desktop;
  
  /// 是否为横屏
  bool get isLandscape => _orientation == ScreenOrientation.landscape;
  
  /// 是否为竖屏
  bool get isPortrait => _orientation == ScreenOrientation.portrait;
  
  /// 是否为窄屏（比例 > 2.0）
  bool get isNarrowScreen => aspectRatio > 2.0;
  
  /// 是否为极窄屏（比例 > 2.1）
  bool get isExtremelyNarrowScreen => aspectRatio > 2.1;
  
  /// 是否为小屏设备（宽度 < 360）
  bool get isSmallScreen => _screenWidth < 360;
  
  /// 是否为大屏设备（最短边 > 600）
  bool get isLargeScreen => math.min(_screenWidth, _screenHeight) > Breakpoints.mobile;
  
  /// 根据设计稿宽度适配
  double setWidth(num width) => width * _scaleWidth;
  
  /// 根据设计稿高度适配
  double setHeight(num height) => height * _scaleHeight;
  
  /// 根据较小的缩放比例适配（避免变形）
  double setSize(num size) => size * (_scaleWidth < _scaleHeight ? _scaleWidth : _scaleHeight);
  
  /// 字体大小适配
  double setSp(num fontSize) => fontSize * _scaleText;
  
  /// 安全的水平边距
  double get safeHorizontalPadding {
    switch (_deviceType) {
      case DeviceType.mobile:
        if (isSmallScreen) return setWidth(12);
        if (isNarrowScreen) return setWidth(16);
        return setWidth(20);
      case DeviceType.tablet:
        return setWidth(24);
      case DeviceType.desktop:
        return setWidth(32);
    }
  }
  
  /// 安全的垂直边距
  double get safeVerticalPadding {
    switch (_deviceType) {
      case DeviceType.mobile:
        if (isNarrowScreen) return setHeight(12);
        return setHeight(16);
      case DeviceType.tablet:
        return setHeight(20);
      case DeviceType.desktop:
        return setHeight(24);
    }
  }
  
  /// 获取安全的EdgeInsets
  EdgeInsets getSafePadding({
    double? horizontal,
    double? vertical,
    double? all,
  }) {
    if (all != null) {
      return EdgeInsets.all(setSize(all));
    }
    return EdgeInsets.symmetric(
      horizontal: setWidth(horizontal ?? safeHorizontalPadding),
      vertical: setHeight(vertical ?? safeVerticalPadding),
    );
  }
  
  /// 获取安全的对话框约束
  BoxConstraints getDialogConstraints() {
    switch (_deviceType) {
      case DeviceType.mobile:
        return BoxConstraints(
          maxWidth: _screenWidth * (isNarrowScreen ? 0.95 : 0.9),
          maxHeight: _screenHeight * (isNarrowScreen ? 0.85 : 0.8),
          minWidth: _screenWidth * 0.8,
        );
      case DeviceType.tablet:
        return BoxConstraints(
          maxWidth: math.min(_screenWidth * 0.7, 600),
          maxHeight: _screenHeight * 0.8,
          minWidth: 400,
        );
      case DeviceType.desktop:
        return BoxConstraints(
          maxWidth: math.min(_screenWidth * 0.5, 800),
          maxHeight: _screenHeight * 0.8,
          minWidth: 500,
        );
    }
  }
  
  /// 获取状态栏高度
  double get statusBarHeight => _statusBarHeight;
  
  /// 获取底部安全区域高度
  double get bottomBarHeight => _bottomBarHeight;
  
  /// 获取安全区域边距
  EdgeInsets get safeAreaInsets => _safeAreaInsets;
  
  /// 获取适配后的BorderRadius
  BorderRadius setBorderRadius(double radius) {
    return BorderRadius.circular(setSize(radius));
  }
  
  /// 获取网格列数（响应式）
  int get gridColumns {
    switch (_deviceType) {
      case DeviceType.mobile:
        return isLandscape ? 2 : 1;
      case DeviceType.tablet:
        return isLandscape ? 3 : 2;
      case DeviceType.desktop:
        return isLandscape ? 4 : 3;
    }
  }
  
  /// 获取最大内容宽度
  double get maxContentWidth {
    switch (_deviceType) {
      case DeviceType.mobile:
        return _screenWidth;
      case DeviceType.tablet:
        return math.min(_screenWidth, 768);
      case DeviceType.desktop:
        return math.min(_screenWidth, 1200);
    }
  }
  
  /// 获取响应式字体缩放因子
  double getResponsiveFontScale() {
    final shortestSide = math.min(_screenWidth, _screenHeight);
    if (shortestSide < Breakpoints.smallText) {
      // 小屏幕：稍微缩小字体
      return 0.9;
    } else if (shortestSide > Breakpoints.largeText) {
      // 大屏幕：稍微放大字体
      return 1.1;
    }
    return 1.0; // 中等屏幕：保持原始大小
  }
  
  /// 打印适配信息（调试用）
  void printAdapterInfo() {
    print('''
=== Enhanced Screen Adapter Info ===
Design Size: ${_designWidth}x${_designHeight}
Screen Size: ${_screenWidth.toStringAsFixed(1)}x${_screenHeight.toStringAsFixed(1)}
Device Type: $_deviceType
Orientation: $_orientation
Scale: W=${_scaleWidth.toStringAsFixed(2)}, H=${_scaleHeight.toStringAsFixed(2)}, T=${_scaleText.toStringAsFixed(2)}
Aspect Ratio: ${aspectRatio.toStringAsFixed(2)}
Grid Columns: $gridColumns
Max Content Width: ${maxContentWidth.toStringAsFixed(1)}
Safe Area: T=${statusBarHeight.toStringAsFixed(1)}, B=${bottomBarHeight.toStringAsFixed(1)}
Horizontal Padding: ${safeHorizontalPadding.toStringAsFixed(1)}
Vertical Padding: ${safeVerticalPadding.toStringAsFixed(1)}
===================================
''');
  }
}

/// 全局扩展方法
extension ScreenAdapterExtension on num {
  /// 根据屏幕宽度适配
  double get w => ScreenAdapter.instance.setWidth(this);
  
  /// 根据屏幕高度适配
  double get h => ScreenAdapter.instance.setHeight(this);
  
  /// 根据较小缩放比例适配
  double get r => ScreenAdapter.instance.setSize(this);
  
  /// 字体大小适配
  double get sp => ScreenAdapter.instance.setSp(this);
}

/// 全局上下文扩展
extension ScreenAdapterContext on BuildContext {
  /// 快速获取适配器
  ScreenAdapter get adapter => ScreenAdapter.instance;
  
  /// 屏幕宽度
  double get screenWidth => adapter.screenWidth;
  
  /// 屏幕高度
  double get screenHeight => adapter.screenHeight;
  
  /// 设备类型
  DeviceType get deviceType => adapter.deviceType;
  
  /// 屏幕方向
  ScreenOrientation get screenOrientation => adapter.orientation;
  
  /// 是否移动设备
  bool get isMobile => adapter.isMobile;
  
  /// 是否平板设备
  bool get isTablet => adapter.isTablet;
  
  /// 是否桌面设备
  bool get isDesktop => adapter.isDesktop;
  
  /// 是否横屏
  bool get isLandscape => adapter.isLandscape;
  
  /// 是否竖屏
  bool get isPortrait => adapter.isPortrait;
  
  /// 是否窄屏
  bool get isNarrowScreen => adapter.isNarrowScreen;
  
  /// 是否小屏
  bool get isSmallScreen => adapter.isSmallScreen;
  
  /// 是否大屏
  bool get isLargeScreen => adapter.isLargeScreen;
  
  /// 安全水平边距
  double get safeHorizontalPadding => adapter.safeHorizontalPadding;
  
  /// 安全垂直边距
  double get safeVerticalPadding => adapter.safeVerticalPadding;
  
  /// 网格列数
  int get gridColumns => adapter.gridColumns;
  
  /// 最大内容宽度
  double get maxContentWidth => adapter.maxContentWidth;
  
  /// 响应式字体缩放
  double get responsiveFontScale => adapter.getResponsiveFontScale();
}