import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppStyles {
  AppStyles._();

  // ============================================================================
  // 5级字体层级系统 - 优化移动端可读性
  // ============================================================================

  /// H1 - 页面主标题 (32px, Extra Bold)
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    fontFamily: 'Poppins',
    color: AppColors.textDark,
    height: 1.2,
  );

  /// H2 - Section标题 (24px, Bold) 
  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    fontFamily: 'Poppins',
    color: AppColors.textDark,
    height: 1.3,
  );

  /// H3 - 卡片标题 (18px, Semi Bold) - 新增
  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontFamily: 'Poppins',
    color: AppColors.textDark,
    height: 1.3,
  );

  /// Body Bold - 强调正文 (16px, Semi Bold)
  static const TextStyle bodyBold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: 'Poppins',
    color: AppColors.textDark,
    height: 1.4,
  );

  /// Body Regular - 标准正文 (16px, Regular)
  static const TextStyle bodyRegular = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: 'Poppins',
    color: AppColors.textLight,
    height: 1.4,
  );

  /// Body Small - 次要正文 (14px, Regular) - 新增
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFamily: 'Poppins',
    color: AppColors.textLight,
    height: 1.4,
  );

  /// Caption - 辅助信息 (12px, Regular) - 新增，最小可读尺寸
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamily: 'Poppins',
    color: AppColors.textLight,
    height: 1.3,
  );

  /// Caption Bold - 强调辅助信息 (12px, Semi Bold) - 新增
  static const TextStyle captionBold = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    fontFamily: 'Poppins',
    color: AppColors.textDark,
    height: 1.3,
  );

  // ============================================================================
  // 专用样式
  // ============================================================================

  /// Button Text - 按钮文字 (16px, Semi Bold)
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: 'Poppins',
    color: AppColors.white,
    letterSpacing: 0.5,
  );

  /// Logo - 品牌标识
  static const TextStyle logo = TextStyle(
    fontFamily: 'Pacifico',
    fontSize: 30,
    color: AppColors.textDark,
    letterSpacing: 2,
  );

  // ============================================================================
  // 卡片标题专用样式 - 统一卡片标题的图标和文字样式
  // ============================================================================

  /// Card Title - 卡片标题样式（图标20px + 文字16px）
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: 'Poppins',
    color: AppColors.primary,
    height: 1.3,
  );

  /// Status Label - 状态标签样式（10px，最小建议尺寸）
  static const TextStyle statusLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    fontFamily: 'Poppins',
    color: AppColors.white,
    height: 1.2,
  );
}