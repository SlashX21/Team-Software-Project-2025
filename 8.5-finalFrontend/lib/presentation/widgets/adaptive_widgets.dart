import 'package:flutter/material.dart';
import '../theme/screen_adapter.dart';
import '../theme/responsive_layout.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

/// 增强的自适应对话框
/// 支持多设备类型的智能对话框适配
class AdaptiveDialog extends StatelessWidget {
  final Widget child;
  final bool barrierDismissible;
  final Color? backgroundColor;
  final double? elevation;
  final EdgeInsets? insetPadding;
  final bool useResponsiveConstraints;

  const AdaptiveDialog({
    Key? key,
    required this.child,
    this.barrierDismissible = true,
    this.backgroundColor,
    this.elevation,
    this.insetPadding,
    this.useResponsiveConstraints = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adapter = ScreenAdapter.instance;
    
    // 响应式内边距
    EdgeInsets effectiveInsetPadding;
    if (insetPadding != null) {
      effectiveInsetPadding = insetPadding!;
    } else {
      switch (adapter.deviceType) {
        case DeviceType.mobile:
          effectiveInsetPadding = EdgeInsets.all(16.r);
          break;
        case DeviceType.tablet:
          effectiveInsetPadding = EdgeInsets.all(32.r);
          break;
        case DeviceType.desktop:
          effectiveInsetPadding = EdgeInsets.all(48.r);
          break;
      }
    }
    
    return Dialog(
      backgroundColor: backgroundColor ?? AppColors.white,
      elevation: elevation ?? (adapter.isDesktop ? 16 : 8),
      shape: RoundedRectangleBorder(
        borderRadius: adapter.setBorderRadius(
          adapter.isDesktop ? 12 : 16
        ),
      ),
      insetPadding: effectiveInsetPadding,
      child: useResponsiveConstraints
          ? ConstrainedBox(
              constraints: adapter.getDialogConstraints(),
              child: ClipRRect(
                borderRadius: adapter.setBorderRadius(
                  adapter.isDesktop ? 12 : 16
                ),
                child: child,
              ),
            )
          : ClipRRect(
              borderRadius: adapter.setBorderRadius(
                adapter.isDesktop ? 12 : 16
              ),
              child: child,
            ),
    );
  }
}

/// 增强的自适应卡片容器
/// 支持多设备类型的智能卡片适配
class AdaptiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final double? elevation;
  final double? borderRadius;
  final Border? border;
  final bool useResponsiveSpacing;

  const AdaptiveCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.border,
    this.useResponsiveSpacing = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adapter = ScreenAdapter.instance;
    
    // 响应式边距
    EdgeInsets effectiveMargin;
    if (margin != null) {
      effectiveMargin = margin!;
    } else if (useResponsiveSpacing) {
      switch (adapter.deviceType) {
        case DeviceType.mobile:
          effectiveMargin = EdgeInsets.symmetric(
            horizontal: adapter.safeHorizontalPadding,
            vertical: 8.h,
          );
          break;
        case DeviceType.tablet:
          effectiveMargin = EdgeInsets.symmetric(
            horizontal: adapter.safeHorizontalPadding,
            vertical: 12.h,
          );
          break;
        case DeviceType.desktop:
          effectiveMargin = EdgeInsets.symmetric(
            horizontal: adapter.safeHorizontalPadding,
            vertical: 16.h,
          );
          break;
      }
    } else {
      effectiveMargin = EdgeInsets.zero;
    }
    
    // 响应式内边距
    EdgeInsets effectivePadding;
    if (padding != null) {
      effectivePadding = padding!;
    } else {
      switch (adapter.deviceType) {
        case DeviceType.mobile:
          effectivePadding = EdgeInsets.all(16.r);
          break;
        case DeviceType.tablet:
          effectivePadding = EdgeInsets.all(20.r);
          break;
        case DeviceType.desktop:
          effectivePadding = EdgeInsets.all(24.r);
          break;
      }
    }
    
    // 响应式阴影
    List<BoxShadow> boxShadow;
    if (elevation != null) {
      boxShadow = [
        BoxShadow(
          color: Colors.black.withOpacity(adapter.isDesktop ? 0.08 : 0.1),
          blurRadius: elevation! * (adapter.isDesktop ? 1.5 : 2),
          offset: Offset(0, elevation! * 0.5),
        ),
      ];
    } else {
      switch (adapter.deviceType) {
        case DeviceType.mobile:
          boxShadow = [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ];
          break;
        case DeviceType.tablet:
          boxShadow = [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ];
          break;
        case DeviceType.desktop:
          boxShadow = [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ];
          break;
      }
    }
    
    return Container(
      margin: effectiveMargin,
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: color ?? AppColors.white,
        borderRadius: adapter.setBorderRadius(borderRadius ?? 12),
        border: border,
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }
}

/// 自适应滚动视图
class AdaptiveScrollView extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final ScrollController? controller;

  const AdaptiveScrollView({
    Key? key,
    required this.children,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adapter = ScreenAdapter.instance;
    
    return ListView(
      controller: controller,
      physics: physics ?? const ClampingScrollPhysics(),
      shrinkWrap: shrinkWrap,
      padding: padding ?? EdgeInsets.symmetric(
        horizontal: adapter.safeHorizontalPadding,
        vertical: adapter.safeVerticalPadding,
      ),
      children: children,
    );
  }
}

/// 自适应单子滚动视图
class AdaptiveSingleChildScrollView extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final Axis scrollDirection;

  const AdaptiveSingleChildScrollView({
    Key? key,
    required this.child,
    this.padding,
    this.physics,
    this.controller,
    this.scrollDirection = Axis.vertical,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adapter = ScreenAdapter.instance;
    
    return SingleChildScrollView(
      controller: controller,
      physics: physics ?? const ClampingScrollPhysics(),
      scrollDirection: scrollDirection,
      padding: padding ?? EdgeInsets.symmetric(
        horizontal: adapter.safeHorizontalPadding,
        vertical: adapter.safeVerticalPadding,
      ),
      child: child,
    );
  }
}

/// 增强的自适应按钮
/// 支持多设备类型的智能按钮适配
class AdaptiveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsets? padding;
  final double? elevation;
  final double? borderRadius;
  final Size? minimumSize;
  final Size? maximumSize;
  final ButtonVariant variant;

  const AdaptiveButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.elevation,
    this.borderRadius,
    this.minimumSize,
    this.maximumSize,
    this.variant = ButtonVariant.elevated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adapter = ScreenAdapter.instance;
    
    // 响应式内边距
    EdgeInsets effectivePadding;
    if (padding != null) {
      effectivePadding = padding!;
    } else {
      switch (adapter.deviceType) {
        case DeviceType.mobile:
          effectivePadding = EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: 12.h,
          );
          break;
        case DeviceType.tablet:
          effectivePadding = EdgeInsets.symmetric(
            horizontal: 24.w,
            vertical: 14.h,
          );
          break;
        case DeviceType.desktop:
          effectivePadding = EdgeInsets.symmetric(
            horizontal: 28.w,
            vertical: 16.h,
          );
          break;
      }
    }
    
    // 响应式最小尺寸
    Size effectiveMinimumSize;
    if (minimumSize != null) {
      effectiveMinimumSize = minimumSize!;
    } else {
      switch (adapter.deviceType) {
        case DeviceType.mobile:
          effectiveMinimumSize = Size(48.w, 44.h);
          break;
        case DeviceType.tablet:
          effectiveMinimumSize = Size(52.w, 48.h);
          break;
        case DeviceType.desktop:
          effectiveMinimumSize = Size(56.w, 52.h);
          break;
      }
    }
    
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? AppColors.primary,
      foregroundColor: foregroundColor ?? AppColors.white,
      padding: effectivePadding,
      elevation: elevation ?? (adapter.isDesktop ? 1 : 2),
      shape: RoundedRectangleBorder(
        borderRadius: adapter.setBorderRadius(borderRadius ?? 8),
      ),
      minimumSize: effectiveMinimumSize,
      maximumSize: maximumSize,
    );
    
    switch (variant) {
      case ButtonVariant.elevated:
        return ElevatedButton(
          onPressed: onPressed,
          style: buttonStyle,
          child: child,
        );
      case ButtonVariant.outlined:
        return OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: backgroundColor ?? AppColors.primary,
            padding: effectivePadding,
            shape: RoundedRectangleBorder(
              borderRadius: adapter.setBorderRadius(borderRadius ?? 8),
            ),
            minimumSize: effectiveMinimumSize,
            maximumSize: maximumSize,
            side: BorderSide(
              color: backgroundColor ?? AppColors.primary,
              width: adapter.isDesktop ? 1.5 : 1,
            ),
          ),
          child: child,
        );
      case ButtonVariant.text:
        return TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: backgroundColor ?? AppColors.primary,
            padding: effectivePadding,
            shape: RoundedRectangleBorder(
              borderRadius: adapter.setBorderRadius(borderRadius ?? 8),
            ),
            minimumSize: effectiveMinimumSize,
            maximumSize: maximumSize,
          ),
          child: child,
        );
    }
  }
}

/// 按钮变体枚举
enum ButtonVariant {
  elevated,
  outlined,
  text,
}

/// 自适应文本输入框
class AdaptiveTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLines;
  final EdgeInsets? contentPadding;

  const AdaptiveTextField({
    Key? key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.contentPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      style: AppStyles.bodyRegular.copyWith(
        fontSize: 16.sp,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(
          prefixIcon,
          color: AppColors.primary,
          size: 20.r,
        ) : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: contentPadding ?? EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 16.h,
        ),
        labelStyle: AppStyles.bodyRegular.copyWith(
          color: AppColors.textLight,
          fontSize: 14.sp,
        ),
        hintStyle: AppStyles.bodyRegular.copyWith(
          color: AppColors.textLight.withOpacity(0.6),
          fontSize: 14.sp,
        ),
      ),
    );
  }
}

/// 自适应间距组件
class AdaptiveSpacing extends StatelessWidget {
  final double? width;
  final double? height;

  const AdaptiveSpacing({
    Key? key,
    this.width,
    this.height,
  }) : super(key: key);

  const AdaptiveSpacing.vertical(double height, {Key? key})
      : width = null,
        height = height,
        super(key: key);

  const AdaptiveSpacing.horizontal(double width, {Key? key})
      : width = width,
        height = null,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width?.w,
      height: height?.h,
    );
  }
}

/// 自适应图标
class AdaptiveIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;

  const AdaptiveIcon({
    Key? key,
    required this.icon,
    this.size,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: (size ?? 24).r,
      color: color,
    );
  }
}

/// 增强的自适应文本
/// 支持多设备类型的智能文本缩放
class AdaptiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool useResponsiveFontSize;
  final bool useDeviceOptimization;

  const AdaptiveText({
    Key? key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.useResponsiveFontSize = true,
    this.useDeviceOptimization = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adapter = ScreenAdapter.instance;
    TextStyle? adaptiveStyle = style;
    
    if (adaptiveStyle != null && useResponsiveFontSize) {
      double fontSize = adaptiveStyle.fontSize ?? 16;
      
      if (useDeviceOptimization) {
        // 设备优化的文本缩放
        final responsiveScale = adapter.getResponsiveFontScale();
        fontSize = (fontSize * adapter.scaleText * responsiveScale);
        
        // 设备特定的行高调整
        double? height = adaptiveStyle.height;
        if (height == null) {
          switch (adapter.deviceType) {
            case DeviceType.mobile:
              height = adapter.isNarrowScreen ? 1.3 : 1.4;
              break;
            case DeviceType.tablet:
              height = 1.4;
              break;
            case DeviceType.desktop:
              height = 1.5;
              break;
          }
        }
        
        adaptiveStyle = adaptiveStyle.copyWith(
          fontSize: fontSize,
          height: height,
        );
      } else {
        // 简单的sp缩放
        adaptiveStyle = adaptiveStyle.copyWith(
          fontSize: fontSize.sp,
        );
      }
    }

    // 设备特定的最大行数优化
    int? effectiveMaxLines = maxLines;
    if (effectiveMaxLines == null && useDeviceOptimization) {
      // 根据设备类型提供合理的默认最大行数
      if (adapter.isNarrowScreen) {
        effectiveMaxLines = text.length > 50 ? 3 : null;
      }
    }

    return Text(
      text,
      style: adaptiveStyle,
      maxLines: effectiveMaxLines,
      overflow: overflow ?? (effectiveMaxLines != null ? TextOverflow.ellipsis : null),
      textAlign: textAlign,
    );
  }
}

/// 显示自适应对话框的辅助方法
Future<T?> showAdaptiveDialog<T>({
  required BuildContext context,
  required Widget child,
  bool barrierDismissible = true,
  Color? barrierColor,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    builder: (context) => AdaptiveDialog(
      barrierDismissible: barrierDismissible,
      child: child,
    ),
  );
}

/// 显示自适应底部弹窗的辅助方法
Future<T?> showAdaptiveBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isScrollControlled = true,
  bool useRootNavigator = false,
}) {
  final adapter = ScreenAdapter.instance;
  
  // 根据设备类型调整弹窗行为
  if (adapter.isDesktop) {
    // 桌面端使用对话框而不是底部弹窗
    return showAdaptiveDialog<T>(
      context: context,
      child: builder(context),
    );
  }
  
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    constraints: BoxConstraints(
      maxHeight: adapter.screenHeight * (adapter.isTablet ? 0.8 : 0.9),
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular((adapter.isTablet ? 20 : 16).r),
      ),
    ),
    builder: builder,
  );
}

/// 自适应加载指示器
class AdaptiveLoadingIndicator extends StatelessWidget {
  final double? size;
  final Color? color;
  final double? strokeWidth;
  final String? message;

  const AdaptiveLoadingIndicator({
    Key? key,
    this.size,
    this.color,
    this.strokeWidth,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adapter = ScreenAdapter.instance;
    
    // 响应式尺寸
    double effectiveSize;
    if (size != null) {
      effectiveSize = size!.r;
    } else {
      switch (adapter.deviceType) {
        case DeviceType.mobile:
          effectiveSize = 24.r;
          break;
        case DeviceType.tablet:
          effectiveSize = 28.r;
          break;
        case DeviceType.desktop:
          effectiveSize = 32.r;
          break;
      }
    }
    
    Widget indicator = SizedBox(
      width: effectiveSize,
      height: effectiveSize,
      child: CircularProgressIndicator(
        color: color ?? AppColors.primary,
        strokeWidth: strokeWidth ?? (adapter.isDesktop ? 3 : 2),
      ),
    );
    
    if (message != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          SizedBox(height: 16.h),
          AdaptiveText(
            text: message!,
            style: AppStyles.bodyRegular.copyWith(
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    
    return indicator;
  }
}

/// 自适应分隔线
class AdaptiveDivider extends StatelessWidget {
  final double? height;
  final double? thickness;
  final Color? color;
  final double? indent;
  final double? endIndent;

  const AdaptiveDivider({
    Key? key,
    this.height,
    this.thickness,
    this.color,
    this.indent,
    this.endIndent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adapter = ScreenAdapter.instance;
    
    return Divider(
      height: height ?? (adapter.isDesktop ? 24.h : 20.h),
      thickness: thickness ?? (adapter.isDesktop ? 1.5 : 1),
      color: color ?? AppColors.textLight.withOpacity(0.2),
      indent: indent?.w ?? adapter.safeHorizontalPadding,
      endIndent: endIndent?.w ?? adapter.safeHorizontalPadding,
    );
  }
}

/// 自适应列表项
class AdaptiveListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;
  final EdgeInsets? contentPadding;

  const AdaptiveListTile({
    Key? key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.dense = false,
    this.contentPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adapter = ScreenAdapter.instance;
    
    // 响应式内边距
    EdgeInsets effectiveContentPadding;
    if (contentPadding != null) {
      effectiveContentPadding = contentPadding!;
    } else {
      switch (adapter.deviceType) {
        case DeviceType.mobile:
          effectiveContentPadding = EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: dense ? 4.h : 8.h,
          );
          break;
        case DeviceType.tablet:
          effectiveContentPadding = EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: dense ? 6.h : 12.h,
          );
          break;
        case DeviceType.desktop:
          effectiveContentPadding = EdgeInsets.symmetric(
            horizontal: 24.w,
            vertical: dense ? 8.h : 16.h,
          );
          break;
      }
    }
    
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      dense: dense && adapter.isMobile,
      contentPadding: effectiveContentPadding,
      visualDensity: adapter.isDesktop 
          ? VisualDensity.comfortable 
          : VisualDensity.standard,
    );
  }
}

/// 自适应页面容器
/// 提供统一的页面布局和边距
class AdaptivePageContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool addSafeArea;
  final bool centerContent;
  final Color? backgroundColor;

  const AdaptivePageContainer({
    Key? key,
    required this.child,
    this.padding,
    this.addSafeArea = true,
    this.centerContent = false,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adapter = ScreenAdapter.instance;
    
    // 响应式内边距
    EdgeInsets effectivePadding;
    if (padding != null) {
      effectivePadding = padding!;
    } else {
      effectivePadding = EdgeInsets.symmetric(
        horizontal: adapter.safeHorizontalPadding,
        vertical: adapter.safeVerticalPadding,
      );
    }
    
    Widget content = Container(
      color: backgroundColor,
      padding: effectivePadding,
      child: child,
    );
    
    // 桌面端居中内容
    if (centerContent && adapter.isDesktop) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: adapter.maxContentWidth,
          ),
          child: content,
        ),
      );
    }
    
    return addSafeArea 
        ? SafeArea(child: content)
        : content;
  }
}

/// 响应式间距值类
class ResponsiveSpacing {
  static const ResponsiveValue<double> xs = ResponsiveValue(
    mobile: 4,
    tablet: 6,
    desktop: 8,
  );
  
  static const ResponsiveValue<double> sm = ResponsiveValue(
    mobile: 8,
    tablet: 12,
    desktop: 16,
  );
  
  static const ResponsiveValue<double> md = ResponsiveValue(
    mobile: 16,
    tablet: 20,
    desktop: 24,
  );
  
  static const ResponsiveValue<double> lg = ResponsiveValue(
    mobile: 24,
    tablet: 32,
    desktop: 40,
  );
  
  static const ResponsiveValue<double> xl = ResponsiveValue(
    mobile: 32,
    tablet: 48,
    desktop: 64,
  );
}

/// 响应式字体大小类
class ResponsiveFontSizes {
  static const ResponsiveValue<double> xs = ResponsiveValue(
    mobile: 12,
    tablet: 13,
    desktop: 14,
  );
  
  static const ResponsiveValue<double> sm = ResponsiveValue(
    mobile: 14,
    tablet: 15,
    desktop: 16,
  );
  
  static const ResponsiveValue<double> base = ResponsiveValue(
    mobile: 16,
    tablet: 17,
    desktop: 18,
  );
  
  static const ResponsiveValue<double> lg = ResponsiveValue(
    mobile: 18,
    tablet: 20,
    desktop: 22,
  );
  
  static const ResponsiveValue<double> xl = ResponsiveValue(
    mobile: 20,
    tablet: 24,
    desktop: 28,
  );
  
  static const ResponsiveValue<double> xxl = ResponsiveValue(
    mobile: 24,
    tablet: 32,
    desktop: 40,
  );
}