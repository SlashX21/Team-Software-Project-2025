import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/progressive_loader.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

/// Animation queue controller for managing staged progress animations
class _AnimationQueueController {
  Timer? _stageTimer;
  int _currentVisualStage = 0;
  int _targetStage = 0;
  bool _isProcessing = false;
  
  final Function(int stage) onStageAdvanced;
  final Duration minStageDuration;
  
  _AnimationQueueController({
    required this.onStageAdvanced,
    this.minStageDuration = const Duration(milliseconds: 1200),
  });
  
  void advanceToStage(int targetStage) {
    if (targetStage <= _currentVisualStage || _isProcessing) {
      _targetStage = targetStage;
      return;
    }
    
    _targetStage = targetStage;
    _processNextStage();
  }
  
  void _processNextStage() {
    if (_isProcessing || _currentVisualStage >= _targetStage) return;
    
    _isProcessing = true;
    final nextStage = _currentVisualStage + 1;
    
    // Advance to next visual stage
    _currentVisualStage = nextStage;
    onStageAdvanced(nextStage);
    
    // Set minimum duration for this stage
    _stageTimer?.cancel();
    _stageTimer = Timer(minStageDuration, () {
      _isProcessing = false;
      // Continue to next stage if target is still ahead
      if (_currentVisualStage < _targetStage) {
        _processNextStage();
      }
    });
  }
  
  void jumpToStage(int stage) {
    _stageTimer?.cancel();
    _isProcessing = false;
    _currentVisualStage = stage;
    _targetStage = stage;
    onStageAdvanced(stage);
  }
  
  void reset() {
    _stageTimer?.cancel();
    _isProcessing = false;
    _currentVisualStage = 0;
    _targetStage = 0;
  }
  
  void dispose() {
    _stageTimer?.cancel();
  }
  
  int get currentVisualStage => _currentVisualStage;
}

class MultiStageProgressIndicator extends StatefulWidget {
  final LoadingStage currentStage;
  final double? progress;
  final String message;
  final String? secondaryMessage;
  final VoidCallback? onCancel;

  const MultiStageProgressIndicator({
    Key? key,
    required this.currentStage,
    this.progress,
    required this.message,
    this.secondaryMessage,
    this.onCancel,
  }) : super(key: key);

  @override
  State<MultiStageProgressIndicator> createState() => _MultiStageProgressIndicatorState();
}

class _MultiStageProgressIndicatorState extends State<MultiStageProgressIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _stageAnimations;
  late List<AnimationController> _lineAnimations;
  late AnimationController _pulseController;
  late _AnimationQueueController _queueController;
  
  int _currentVisualStage = 0;
  
  final List<StageInfo> _stages = [
    StageInfo(
      icon: Icons.qr_code_2,
      label: 'Barcode Detected',
      stage: LoadingStage.initializing,
    ),
    StageInfo(
      icon: Icons.inventory_2,
      label: 'Fetching Product',
      stage: LoadingStage.fetchingBasicInfo,
    ),
    StageInfo(
      icon: Icons.psychology,
      label: 'AI Analysis',
      stage: LoadingStage.fetchingRecommendations,
    ),
    StageInfo(
      icon: Icons.check_circle,
      label: 'Complete',
      stage: LoadingStage.completed,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeQueueController();
    _updateAnimations();
  }

  void _initializeAnimations() {
    // Initialize stage circle animations
    _stageAnimations = List.generate(
      _stages.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    // Initialize line animations
    _lineAnimations = List.generate(
      _stages.length - 1,
      (index) => AnimationController(
        duration: Duration(milliseconds: 500),
        vsync: this,
      ),
    );

    // Initialize pulse animation for current stage
    _pulseController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  void _initializeQueueController() {
    _queueController = _AnimationQueueController(
      onStageAdvanced: (stage) {
        if (mounted) {
          setState(() {
            _currentVisualStage = stage;
          });
          _animateToStage(stage);
        }
      },
      minStageDuration: Duration(milliseconds: 1200),
    );
  }

  @override
  void didUpdateWidget(MultiStageProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStage != widget.currentStage) {
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    final targetStageIndex = _getCurrentStageIndex();
    
    // Handle special cases
    if (widget.currentStage == LoadingStage.error) {
      _queueController.jumpToStage(targetStageIndex);
      return;
    }
    
    // For completion, immediately show final stage
    if (widget.currentStage == LoadingStage.completed) {
      _queueController.advanceToStage(3);
      return;
    }
    
    // Start from first stage if this is the initial call
    if (_currentVisualStage == 0 && targetStageIndex >= 0) {
      _queueController.advanceToStage(0);
      // If target is further ahead, let queue controller handle progression
      if (targetStageIndex > 0) {
        _queueController.advanceToStage(targetStageIndex);
      }
      return;
    }
    
    // For other stages, use queue system with minimum duration
    _queueController.advanceToStage(targetStageIndex);
  }

  void _animateToStage(int stageIndex) {
    // Animate all stages up to and including the current stage
    for (int i = 0; i <= stageIndex && i < _stages.length; i++) {
      _stageAnimations[i].forward();
      
      // Animate connecting line after stage completion
      if (i < _lineAnimations.length) {
        _lineAnimations[i].forward();
      }
    }
  }

  int _getCurrentStageIndex() {
    switch (widget.currentStage) {
      case LoadingStage.initializing:
      case LoadingStage.detecting:
        return 0;
      case LoadingStage.fetchingBasicInfo:
      case LoadingStage.basicInfoLoaded:
        return 1;
      case LoadingStage.fetchingRecommendations:
        return 2;
      case LoadingStage.completed:
        return 3;
      case LoadingStage.error:
        return _stages.indexWhere((s) => s.stage == widget.currentStage).clamp(0, _stages.length - 1);
    }
  }

  @override
  void dispose() {
    _queueController.dispose();
    for (var controller in _stageAnimations) {
      controller.dispose();
    }
    for (var controller in _lineAnimations) {
      controller.dispose();
    }
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Stage indicators
          Container(
            height: 80,
            child: Row(
              children: [
                for (int i = 0; i < _stages.length; i++) ...[
                  _buildStageIndicator(i),
                  if (i < _stages.length - 1) _buildConnectingLine(i),
                ],
              ],
            ),
          ),
          
          SizedBox(height: 32),
          
          // Current stage message
          Text(
            widget.message,
            style: AppStyles.h3.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (widget.secondaryMessage != null) ...[
            SizedBox(height: 8),
            Text(
              widget.secondaryMessage!,
              style: AppStyles.bodyRegular.copyWith(
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          
          SizedBox(height: 24),
          
          // Overall progress
          _buildOverallProgress(),
          
          if (widget.onCancel != null) ...[
            SizedBox(height: 24),
            TextButton(
              onPressed: widget.onCancel,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Cancel',
                style: AppStyles.bodyBold.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStageIndicator(int index) {
    final stage = _stages[index];
    // Use visual stage instead of actual stage for smoother animations
    final isCompleted = index < _currentVisualStage;
    final isCurrent = index == _currentVisualStage && widget.currentStage != LoadingStage.error;
    final isError = widget.currentStage == LoadingStage.error && index == _currentVisualStage;
    
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_stageAnimations[index], _pulseController]),
            builder: (context, child) {
              final scale = isCurrent
                  ? 1.0 + (_pulseController.value * 0.1)
                  : _stageAnimations[index].value;
              
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted || isCurrent
                        ? AppColors.primary
                        : isError
                            ? AppColors.alert
                            : Colors.grey[300],
                    border: Border.all(
                      color: isCompleted || isCurrent
                          ? AppColors.primary
                          : isError
                              ? AppColors.alert
                              : Colors.grey[400]!,
                      width: 2,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      isCompleted
                          ? Icons.check
                          : isError
                              ? Icons.error_outline
                              : stage.icon,
                      color: isCompleted || isCurrent || isError
                          ? Colors.white
                          : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 8),
          Text(
            stage.label,
            style: AppStyles.caption.copyWith(
              color: isCompleted || isCurrent
                  ? AppColors.textDark
                  : AppColors.textLight,
              fontWeight: isCompleted || isCurrent
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectingLine(int index) {
    return AnimatedBuilder(
      animation: _lineAnimations[index],
      builder: (context, child) {
        return Container(
          height: 2,
          width: 24,
          child: LinearProgressIndicator(
            value: _lineAnimations[index].value,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        );
      },
    );
  }

  Widget _buildOverallProgress() {
    // Use visual stage for smoother progress animation
    final progress = widget.progress ?? (_currentVisualStage / (_stages.length - 1));
    
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 8,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '${(progress * 100).round()}%',
          style: AppStyles.caption.copyWith(
            color: AppColors.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class StageInfo {
  final IconData icon;
  final String label;
  final LoadingStage stage;

  const StageInfo({
    required this.icon,
    required this.label,
    required this.stage,
  });
}