import 'dart:async';
import 'package:flutter/material.dart';
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

class _EnhancedLoadingState extends State<EnhancedLoading> {
  Timer? _progressTimer;
  double _simulatedProgress = 0.0;
  String _currentStage = '';
  
  final List<String> _scanningStages = [
    'Detecting barcode...',
    'Querying product database...',
    'Analyzing your nutrition needs...',
    'Generating personalized suggestions...',
  ];
  
  final List<String> _profileStages = [
    'Loading personal information...',
    'Getting allergen data...',
    'Synchronizing user preferences...',
  ];

  @override
  void initState() {
    super.initState();
    _startProgressSimulation();
  }

  void _startProgressSimulation() {
    if (widget.progress != null || !widget.showProgress) return;

    final stages = widget.type == LoadingType.scanning 
        ? _scanningStages 
        : _profileStages;
    
    int currentStageIndex = 0;

    _progressTimer = Timer.periodic(Duration(milliseconds: 150), (timer) {
      if (!mounted) return;

      setState(() {
        _simulatedProgress += 0.015;
        
        // 更新当前阶段
        final expectedStage = (_simulatedProgress * stages.length).floor();
        if (expectedStage < stages.length && expectedStage != currentStageIndex) {
          currentStageIndex = expectedStage;
          _currentStage = stages[currentStageIndex];
        }
        
        if (_simulatedProgress >= 0.95) {
          _simulatedProgress = 0.95;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 静态的Material 3风格加载指示器 - 无缩放动画
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        ),
          ),
          
          SizedBox(height: 24),
          
          // 主要消息
          Text(
            widget.message,
            style: AppStyles.h3.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 12),
          
          // 当前阶段信息
          if (_currentStage.isNotEmpty)
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: Text(
              _currentStage,
                key: ValueKey(_currentStage),
              style: AppStyles.bodyRegular.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              ),
            ),
          
          // 次要消息
          if (widget.secondaryMessage != null) ...[
            SizedBox(height: 8),
            Text(
              widget.secondaryMessage!,
              style: AppStyles.bodyRegular.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            FilledButton.tonal(
              onPressed: widget.onCancel,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
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
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
          minHeight: 6,
                borderRadius: BorderRadius.circular(3),
        ),
        SizedBox(height: 8),
            Text(
          '${(progress * 100).round()}%',
          style: AppStyles.caption.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

// 加载类型枚举
enum LoadingType {
  scanning,
  profile,
  recommendations,
  processing,
}

// 简化版加载对话框
class SimpleLoadingDialog extends StatelessWidget {
  final String message;
  final String? subMessage;

  const SimpleLoadingDialog({
    Key? key,
    required this.message,
    this.subMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              message,
              style: AppStyles.bodyBold,
              textAlign: TextAlign.center,
            ),
            if (subMessage != null) ...[
              SizedBox(height: 8),
              Text(
                subMessage!,
                style: AppStyles.bodyRegular.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}