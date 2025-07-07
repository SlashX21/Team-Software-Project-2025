import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

class EnhancedLoading extends StatefulWidget {
  final String message;
  final String? secondaryMessage;
  final bool showProgress;
  final double? progress;
  final Duration? estimatedTime;
  final VoidCallback? onCancel;
  final LoadingType type;

  const EnhancedLoading({
    Key? key,
    required this.message,
    this.secondaryMessage,
    this.showProgress = false,
    this.progress,
    this.estimatedTime,
    this.onCancel,
    this.type = LoadingType.scanning,
  }) : super(key: key);

  @override
  _EnhancedLoadingState createState() => _EnhancedLoadingState();
}

class _EnhancedLoadingState extends State<EnhancedLoading>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  Timer? _progressTimer;
  double _simulatedProgress = 0.0;
  String _currentStage = '';
  
  final List<String> _scanningStages = [
    'Identifying barcode...',
    'Querying product database...',
    'Analyzing product information...',
    'Getting nutrition advice...',
  ];
  
  final List<String> _profileStages = [
    'Loading personal information...',
    'Getting allergen data...',
    'Synchronizing user preferences...',
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startProgressSimulation();
  }

  void _setupAnimations() {
    _rotationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  void _startProgressSimulation() {
    if (widget.progress != null || !widget.showProgress) return;

    final stages = widget.type == LoadingType.scanning 
        ? _scanningStages 
        : _profileStages;
    
    int currentStageIndex = 0;
    final stageDuration = (widget.estimatedTime ?? Duration(seconds: 6)).inMilliseconds / stages.length;

    _progressTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (!mounted) return;

      setState(() {
        _simulatedProgress += 0.02;
        
        // 更新当前阶段
        final expectedStage = (_simulatedProgress * stages.length).floor();
        if (expectedStage < stages.length && expectedStage != currentStageIndex) {
          currentStageIndex = expectedStage;
          _currentStage = stages[currentStageIndex];
        }
        
        if (_simulatedProgress >= 1.0) {
          _simulatedProgress = 0.95; // 不要达到100%，等待真实完成
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 动画图标
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationController.value * 2 * 3.14159,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _getGradientColors(),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIcon(),
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          
          SizedBox(height: 20),
          
          // 主要消息
          Text(
            widget.message,
            style: AppStyles.h2.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 8),
          
          // 当前阶段信息
          if (_currentStage.isNotEmpty)
            Text(
              _currentStage,
              style: AppStyles.bodyRegular.copyWith(
                color: AppColors.primary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          
          // 次要消息
          if (widget.secondaryMessage != null) ...[
            SizedBox(height: 4),
            Text(
              widget.secondaryMessage!,
              style: AppStyles.bodyRegular.copyWith(
                color: AppColors.textLight,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          
          SizedBox(height: 20),
          
          // 进度条
          if (widget.showProgress) ...[
            _buildProgressBar(),
            SizedBox(height: 16),
          ],
          
          // 取消按钮
          if (widget.onCancel != null)
            TextButton(
              onPressed: widget.onCancel,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textLight,
              ),
              child: Text('Cancel'),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = widget.progress ?? _simulatedProgress;
    
    return Column(
      children: [
        // 进度条
        Container(
          width: double.infinity,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        
        SizedBox(height: 8),
        
        // 进度百分比和预估时间
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress * 100).toInt()}%',
              style: AppStyles.bodyRegular.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            if (widget.estimatedTime != null)
              Text(
                'Estimated remaining ${_formatRemainingTime(progress)}',
                style: AppStyles.bodyRegular.copyWith(
                  color: AppColors.textLight,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _formatRemainingTime(double progress) {
    if (widget.estimatedTime == null || progress >= 1.0) return 'Almost done';
    
    final remaining = widget.estimatedTime!.inSeconds * (1 - progress);
    if (remaining < 1) return 'Almost done';
    if (remaining < 60) return '${remaining.toInt()} seconds';
    
    final minutes = (remaining / 60).floor();
    final seconds = (remaining % 60).toInt();
    return '${minutes} minutes ${seconds} seconds';
  }

  IconData _getIcon() {
    switch (widget.type) {
      case LoadingType.scanning:
        return Icons.qr_code_scanner;
      case LoadingType.profile:
        return Icons.person;
      case LoadingType.api:
        return Icons.cloud_sync;
      case LoadingType.processing:
        return Icons.psychology;
      default:
        return Icons.hourglass_empty;
    }
  }

  List<Color> _getGradientColors() {
    switch (widget.type) {
      case LoadingType.scanning:
        return [AppColors.primary, Colors.blue.shade400];
      case LoadingType.profile:
        return [Colors.green.shade400, Colors.teal.shade400];
      case LoadingType.api:
        return [Colors.orange.shade400, Colors.deepOrange.shade400];
      case LoadingType.processing:
        return [Colors.purple.shade400, Colors.indigo.shade400];
      default:
        return [AppColors.primary, AppColors.primary.withOpacity(0.7)];
    }
  }
}

enum LoadingType {
  scanning,
  profile,
  api,
  processing,
  general,
}

/// 通用加载对话框
class LoadingDialog extends StatelessWidget {
  final String message;
  final String? secondaryMessage;
  final LoadingType type;
  final bool showProgress;
  final double? progress;
  final Duration? estimatedTime;
  final bool barrierDismissible;

  const LoadingDialog({
    Key? key,
    required this.message,
    this.secondaryMessage,
    this.type = LoadingType.general,
    this.showProgress = false,
    this.progress,
    this.estimatedTime,
    this.barrierDismissible = false,
  }) : super(key: key);

  static Future<T?> show<T>(
    BuildContext context, {
    required String message,
    String? secondaryMessage,
    LoadingType type = LoadingType.general,
    bool showProgress = false,
    double? progress,
    Duration? estimatedTime,
    bool barrierDismissible = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => LoadingDialog(
        message: message,
        secondaryMessage: secondaryMessage,
        type: type,
        showProgress: showProgress,
        progress: progress,
        estimatedTime: estimatedTime,
        barrierDismissible: barrierDismissible,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: EnhancedLoading(
        message: message,
        secondaryMessage: secondaryMessage,
        type: type,
        showProgress: showProgress,
        progress: progress,
        estimatedTime: estimatedTime,
        onCancel: barrierDismissible ? () => Navigator.of(context).pop() : null,
      ),
    );
  }
}