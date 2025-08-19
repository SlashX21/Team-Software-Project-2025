import 'package:flutter/material.dart';
import 'screen_adapter.dart';

/// 响应式布局构建器
/// 根据不同设备类型和屏幕尺寸自动选择最佳布局
class ResponsiveLayoutBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType)? mobile;
  final Widget Function(BuildContext context, DeviceType deviceType)? tablet;
  final Widget Function(BuildContext context, DeviceType deviceType)? desktop;
  final Widget Function(BuildContext context, DeviceType deviceType)? fallback;

  const ResponsiveLayoutBuilder({
    Key? key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adapter = ScreenAdapter.instance;
    final deviceType = adapter.deviceType;

    Widget? child;
    
    switch (deviceType) {
      case DeviceType.mobile:
        child = mobile?.call(context, deviceType);
        break;
      case DeviceType.tablet:
        child = tablet?.call(context, deviceType);
        break;
      case DeviceType.desktop:
        child = desktop?.call(context, deviceType);
        break;
    }

    // 如果当前设备类型没有对应的构建器，尝试降级
    child ??= _getFallbackWidget(context, deviceType);
    
    // 最终fallback
    child ??= fallback?.call(context, deviceType);
    
    if (child == null) {
      throw FlutterError(
        'ResponsiveLayoutBuilder must have at least one builder or a fallback builder',
      );
    }

    return child;
  }

  Widget? _getFallbackWidget(BuildContext context, DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.desktop:
        // Desktop没有builder时，尝试tablet，再尝试mobile
        return tablet?.call(context, deviceType) ?? 
               mobile?.call(context, deviceType);
      case DeviceType.tablet:
        // Tablet没有builder时，尝试mobile，再尝试desktop
        return mobile?.call(context, deviceType) ?? 
               desktop?.call(context, deviceType);
      case DeviceType.mobile:
        // Mobile没有builder时，尝试tablet，再尝试desktop
        return tablet?.call(context, deviceType) ?? 
               desktop?.call(context, deviceType);
    }
  }
}

/// 简化的响应式布局构建器
/// 只需要提供不同断点的Widget即可
class ResponsiveWidget extends StatelessWidget {
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? fallback;

  const ResponsiveWidget({
    Key? key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayoutBuilder(
      mobile: mobile != null ? (_, __) => mobile! : null,
      tablet: tablet != null ? (_, __) => tablet! : null,
      desktop: desktop != null ? (_, __) => desktop! : null,
      fallback: fallback != null ? (_, __) => fallback! : null,
    );
  }
}

/// 响应式值构建器
/// 根据设备类型返回不同的值
class ResponsiveValue<T> {
  final T? mobile;
  final T? tablet;
  final T? desktop;
  final T? fallback;

  const ResponsiveValue({
    this.mobile,
    this.tablet,
    this.desktop,
    this.fallback,
  });

  T getValue(BuildContext context) {
    final adapter = ScreenAdapter.instance;
    final deviceType = adapter.deviceType;

    T? value;
    
    switch (deviceType) {
      case DeviceType.mobile:
        value = mobile;
        break;
      case DeviceType.tablet:
        value = tablet;
        break;
      case DeviceType.desktop:
        value = desktop;
        break;
    }

    // 降级策略
    if (value == null) {
      switch (deviceType) {
        case DeviceType.desktop:
          value = tablet ?? mobile;
          break;
        case DeviceType.tablet:
          value = mobile ?? desktop;
          break;
        case DeviceType.mobile:
          value = tablet ?? desktop;
          break;
      }
    }

    // 最终fallback
    value ??= fallback;

    if (value == null) {
      throw FlutterError(
        'ResponsiveValue must have at least one value or a fallback value',
      );
    }

    return value;
  }

  /// 快捷方法：获取当前值
  T call(BuildContext context) => getValue(context);
}

/// 响应式网格系统
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final double? spacing;
  final double? runSpacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final double? childAspectRatio;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.padding,
    this.spacing,
    this.runSpacing,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.physics,
    this.shrinkWrap = false,
    this.childAspectRatio,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adapter = ScreenAdapter.instance;
    
    // 获取列数
    int columns;
    switch (adapter.deviceType) {
      case DeviceType.mobile:
        columns = mobileColumns ?? (adapter.isLandscape ? 2 : 1);
        break;
      case DeviceType.tablet:
        columns = tabletColumns ?? (adapter.isLandscape ? 3 : 2);
        break;
      case DeviceType.desktop:
        columns = desktopColumns ?? (adapter.isLandscape ? 4 : 3);
        break;
    }

    return GridView.count(
      crossAxisCount: columns,
      padding: padding ?? EdgeInsets.all(adapter.safeHorizontalPadding),
      crossAxisSpacing: spacing ?? 16.r,
      mainAxisSpacing: runSpacing ?? 16.r,
      physics: physics,
      shrinkWrap: shrinkWrap,
      childAspectRatio: childAspectRatio ?? 1.0,
      children: children,
    );
  }
}

/// 响应式容器
/// 自动调整最大宽度以适应不同设备
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final Decoration? decoration;
  final double? maxWidth;
  final bool centerContent;
  final MainAxisAlignment? alignment;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.decoration,
    this.maxWidth,
    this.centerContent = true,
    this.alignment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adapter = ScreenAdapter.instance;
    final effectiveMaxWidth = maxWidth ?? adapter.maxContentWidth;

    Widget content = Container(
      padding: padding,
      margin: margin,
      color: color,
      decoration: decoration,
      constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
      child: child,
    );

    if (centerContent && adapter.screenWidth > effectiveMaxWidth) {
      content = Center(
        child: content,
      );
    }

    return content;
  }
}

/// 响应式行布局
/// 在小屏幕上自动转换为列布局
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double? spacing;
  final bool forceColumn;

  const ResponsiveRow({
    Key? key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.spacing,
    this.forceColumn = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adapter = ScreenAdapter.instance;
    final shouldUseColumn = forceColumn || 
        (adapter.isMobile && adapter.isPortrait);

    List<Widget> spacedChildren = children;
    if (spacing != null && spacing! > 0) {
      spacedChildren = [];
      for (int i = 0; i < children.length; i++) {
        spacedChildren.add(children[i]);
        if (i < children.length - 1) {
          spacedChildren.add(
            shouldUseColumn 
                ? SizedBox(height: spacing!.h)
                : SizedBox(width: spacing!.w)
          );
        }
      }
    }

    return shouldUseColumn
        ? Column(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            mainAxisSize: mainAxisSize,
            children: spacedChildren,
          )
        : Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            mainAxisSize: mainAxisSize,
            children: spacedChildren,
          );
  }
}

/// 方向感知的Widget
/// 根据屏幕方向自动调整布局
class OrientationAwareWidget extends StatelessWidget {
  final Widget portrait;
  final Widget? landscape;

  const OrientationAwareWidget({
    Key? key,
    required this.portrait,
    this.landscape,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adapter = ScreenAdapter.instance;
    
    return adapter.isLandscape && landscape != null
        ? landscape!
        : portrait;
  }
}

/// 断点监听器
/// 当设备类型或方向改变时重建Widget
class BreakpointListener extends StatefulWidget {
  final Widget Function(BuildContext context, DeviceType deviceType, ScreenOrientation orientation) builder;

  const BreakpointListener({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  State<BreakpointListener> createState() => _BreakpointListenerState();
}

class _BreakpointListenerState extends State<BreakpointListener> with WidgetsBindingObserver {
  late DeviceType _currentDeviceType;
  late ScreenOrientation _currentOrientation;

  @override
  void initState() {
    super.initState();
    final adapter = ScreenAdapter.instance;
    _currentDeviceType = adapter.deviceType;
    _currentOrientation = adapter.orientation;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final adapter = ScreenAdapter.instance;
    adapter.initFromContext(context);
    
    if (_currentDeviceType != adapter.deviceType || 
        _currentOrientation != adapter.orientation) {
      setState(() {
        _currentDeviceType = adapter.deviceType;
        _currentOrientation = adapter.orientation;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _currentDeviceType, _currentOrientation);
  }
}

/// 旧版响应式布局工具类 (向后兼容)
/// 解决不同屏幕比例的适配问题，特别是窄屏设备（如19.5:9）
@deprecated
class ResponsiveLayout {
  static const double _baseWidth = 375.0; // iPhone 8 基准宽度
  static const double _baseHeight = 667.0; // iPhone 8 基准高度
  
  /// 获取当前屏幕信息
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }
  
  /// 获取屏幕宽度
  static double getWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
  
  /// 获取屏幕高度
  static double getHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
  
  /// 获取屏幕比例（宽高比）
  static double getAspectRatio(BuildContext context) {
    final size = getScreenSize(context);
    return size.height / size.width;
  }
  
  /// 判断是否为窄屏设备（比例 > 2.0，如19.5:9 ≈ 2.17）
  static bool isNarrowScreen(BuildContext context) {
    return getAspectRatio(context) > 2.0;
  }
  
  /// 判断是否为极窄屏设备（比例 > 2.1）
  static bool isExtremelyNarrowScreen(BuildContext context) {
    return getAspectRatio(context) > 2.1;
  }
  
  /// 根据屏幕宽度缩放尺寸
  static double scaleWidth(BuildContext context, double size) {
    final screenWidth = getWidth(context);
    return (size * screenWidth / _baseWidth).clamp(size * 0.8, size * 1.2);
  }
  
  /// 根据屏幕高度缩放尺寸
  static double scaleHeight(BuildContext context, double size) {
    final screenHeight = getHeight(context);
    return (size * screenHeight / _baseHeight).clamp(size * 0.8, size * 1.2);
  }
  
  /// 获取安全的水平边距
  static double getSafeHorizontalPadding(BuildContext context) {
    final screenWidth = getWidth(context);
    if (screenWidth < 360) return 12.0; // 小屏
    if (screenWidth < 400) return 16.0; // 中屏
    return 20.0; // 大屏
  }
  
  /// 获取安全的垂直边距
  static double getSafeVerticalPadding(BuildContext context) {
    if (isNarrowScreen(context)) return 12.0; // 窄屏减少垂直间距
    return 16.0;
  }
  
  /// 获取响应式间距
  static EdgeInsets getResponsivePadding(BuildContext context, {
    double? horizontal,
    double? vertical,
    double? all,
  }) {
    if (all != null) {
      return EdgeInsets.all(scaleWidth(context, all));
    }
    
    final h = horizontal ?? getSafeHorizontalPadding(context);
    final v = vertical ?? getSafeVerticalPadding(context);
    
    return EdgeInsets.symmetric(
      horizontal: scaleWidth(context, h),
      vertical: scaleHeight(context, v),
    );
  }
  
  /// 获取安全的对话框约束
  static BoxConstraints getDialogConstraints(BuildContext context) {
    final screenSize = getScreenSize(context);
    final isNarrow = isNarrowScreen(context);
    
    return BoxConstraints(
      maxWidth: screenSize.width * (isNarrow ? 0.95 : 0.9),
      maxHeight: screenSize.height * (isNarrow ? 0.9 : 0.8),
      minWidth: screenSize.width * 0.8,
    );
  }
  
  /// 获取安全的卡片边距
  static EdgeInsets getCardMargin(BuildContext context) {
    final padding = getSafeHorizontalPadding(context);
    return EdgeInsets.symmetric(
      horizontal: padding,
      vertical: getSafeVerticalPadding(context) * 0.5,
    );
  }
  
  /// 获取安全的卡片内边距
  static EdgeInsets getCardPadding(BuildContext context) {
    final basePadding = isNarrowScreen(context) ? 16.0 : 20.0;
    return EdgeInsets.all(scaleWidth(context, basePadding));
  }
  
  /// 获取响应式字体大小
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final screenWidth = getWidth(context);
    final scaleFactor = (screenWidth / _baseWidth).clamp(0.9, 1.1);
    return baseFontSize * scaleFactor;
  }
  
  /// 获取响应式图标大小
  static double getResponsiveIconSize(BuildContext context, double baseSize) {
    return scaleWidth(context, baseSize);
  }
  
  /// 创建响应式的SingleChildScrollView
  static Widget buildResponsiveScrollView({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
    ScrollPhysics? physics,
  }) {
    return SingleChildScrollView(
      physics: physics ?? const ClampingScrollPhysics(),
      padding: padding ?? getResponsivePadding(context),
      child: child,
    );
  }
  
  /// 创建响应式的ListView
  static Widget buildResponsiveListView({
    required BuildContext context,
    required List<Widget> children,
    EdgeInsets? padding,
    ScrollPhysics? physics,
  }) {
    return ListView(
      physics: physics ?? const ClampingScrollPhysics(),
      padding: padding ?? getResponsivePadding(context),
      children: children,
    );
  }
  
  /// 创建安全的弹窗包装器
  static Widget buildSafeDialog({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: getDialogConstraints(context),
        child: child,
      ),
    );
  }
  
  /// 显示安全的底部弹窗
  static Future<T?> showSafeBottomSheet<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      constraints: BoxConstraints(
        maxHeight: getHeight(context) * 0.9,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: builder,
    );
  }
  
  /// 获取安全的文本样式
  static TextStyle getResponsiveTextStyle(
    BuildContext context,
    TextStyle baseStyle,
  ) {
    return baseStyle.copyWith(
      fontSize: getResponsiveFontSize(context, baseStyle.fontSize ?? 16),
    );
  }
  
  /// 构建响应式间距组件
  static Widget buildResponsiveSpacing(
    BuildContext context, {
    double? height,
    double? width,
  }) {
    return SizedBox(
      height: height != null ? scaleHeight(context, height) : null,
      width: width != null ? scaleWidth(context, width) : null,
    );
  }
  
  /// 获取设备信息文本（用于调试）
  static String getDeviceInfo(BuildContext context) {
    final size = getScreenSize(context);
    final ratio = getAspectRatio(context);
    final isNarrow = isNarrowScreen(context);
    final isExtremely = isExtremelyNarrowScreen(context);
    
    return '''
Device Info:
Size: ${size.width.toStringAsFixed(1)} × ${size.height.toStringAsFixed(1)}
Aspect Ratio: ${ratio.toStringAsFixed(2)}:1
Narrow Screen: $isNarrow
Extremely Narrow: $isExtremely
Safe H Padding: ${getSafeHorizontalPadding(context)}
Safe V Padding: ${getSafeVerticalPadding(context)}
''';
  }
}

/// 响应式布局扩展 (向后兼容)
@deprecated
extension ResponsiveExtensions on BuildContext {
  /// 新的扩展方法请使用 ScreenAdapterContext
  
  /// 快速获取新适配器
  ScreenAdapter get newAdapter => ScreenAdapter.instance;
  DeviceType get deviceType => newAdapter.deviceType;
  ScreenOrientation get screenOrientation => newAdapter.orientation;
  bool get isMobile => newAdapter.isMobile;
  bool get isTablet => newAdapter.isTablet;
  bool get isDesktop => newAdapter.isDesktop;
  /// 快速获取响应式尺寸
  double get screenWidth => ResponsiveLayout.getWidth(this);
  double get screenHeight => ResponsiveLayout.getHeight(this);
  double get aspectRatio => ResponsiveLayout.getAspectRatio(this);
  bool get isNarrowScreen => ResponsiveLayout.isNarrowScreen(this);
  bool get isExtremelyNarrowScreen => ResponsiveLayout.isExtremelyNarrowScreen(this);
  
  /// 快速获取响应式间距
  EdgeInsets get safeCardMargin => ResponsiveLayout.getCardMargin(this);
  EdgeInsets get safeCardPadding => ResponsiveLayout.getCardPadding(this);
  double get safeHorizontalPadding => ResponsiveLayout.getSafeHorizontalPadding(this);
  double get safeVerticalPadding => ResponsiveLayout.getSafeVerticalPadding(this);
  
  /// 快速缩放尺寸
  double scaleWidth(double size) => ResponsiveLayout.scaleWidth(this, size);
  double scaleHeight(double size) => ResponsiveLayout.scaleHeight(this, size);
  double responsiveFontSize(double size) => ResponsiveLayout.getResponsiveFontSize(this, size);
  double responsiveIconSize(double size) => ResponsiveLayout.getResponsiveIconSize(this, size);
}