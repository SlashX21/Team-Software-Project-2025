import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../theme/screen_adapter.dart';
import '../theme/responsive_layout.dart';
import 'adaptive_widgets.dart';
import '../../services/receipt_loading_states.dart';

/// Animation queue controller for managing staged progress animations
class _AnimationQueueController {
  Timer? _stageTimer;
  int _currentVisualStage = -1; // Start from -1 so first stage (0) can be animated
  int _targetStage = 0;
  bool _isProcessing = false;
  
  final Function(int stage) onStageAdvanced;
  final Duration minStageDuration;
  
  _AnimationQueueController({
    required this.onStageAdvanced,
    this.minStageDuration = const Duration(milliseconds: 1200),
  });
  
  void advanceToStage(int targetStage) {
    _targetStage = targetStage;
    
    // If we're already at or past the target, no need to process
    if (targetStage <= _currentVisualStage) {
      return;
    }
    
    // If already processing, let it continue to the new target
    if (_isProcessing) {
      return;
    }
    
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
    _currentVisualStage = -1;
    _targetStage = 0;
  }
  
  void dispose() {
    _stageTimer?.cancel();
  }
  
  int get currentVisualStage => _currentVisualStage;
}

/// Receipt-specific multi-stage progress indicator
class ReceiptProgressIndicator extends StatefulWidget {
  final ReceiptLoadingStage currentStage;
  final double? progress;
  final String message;
  final String? secondaryMessage;
  final VoidCallback? onCancel;
  final Widget? receiptImage; // 小票图片预览

  const ReceiptProgressIndicator({
    Key? key,
    required this.currentStage,
    this.progress,
    required this.message,
    this.secondaryMessage,
    this.onCancel,
    this.receiptImage,
  }) : super(key: key);

  @override
  State<ReceiptProgressIndicator> createState() => _ReceiptProgressIndicatorState();
}

class _ReceiptProgressIndicatorState extends State<ReceiptProgressIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _stageAnimations;
  late List<AnimationController> _lineAnimations;
  late AnimationController _fadeController;
  late _AnimationQueueController _queueController;
  
  int _currentVisualStage = -1;
  
  final List<StageInfo> _stages = [
    StageInfo(
      icon: Icons.upload_file,
      label: 'Receipt Uploaded',
      stage: ReceiptLoadingStage.uploaded,
    ),
    StageInfo(
      icon: Icons.document_scanner,
      label: 'OCR Processing',
      stage: ReceiptLoadingStage.ocrProcessing,
    ),
    StageInfo(
      icon: Icons.analytics,
      label: 'Analyzing Items',
      stage: ReceiptLoadingStage.analyzingItems,
    ),
    StageInfo(
      icon: Icons.check_circle,
      label: 'Complete',
      stage: ReceiptLoadingStage.completed,
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

    // Initialize fade animation for stage appearance
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
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
  void didUpdateWidget(ReceiptProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStage != widget.currentStage) {
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    final targetStageIndex = _getCurrentStageIndex();
    
    // Handle error state - jump immediately
    if (widget.currentStage == ReceiptLoadingStage.error) {
      _queueController.jumpToStage(targetStageIndex);
      return;
    }
    
    // Handle completion - advance to final stage
    if (widget.currentStage == ReceiptLoadingStage.completed) {
      _queueController.advanceToStage(3);
      return;
    }
    
    // For all other cases, use the queue system to advance smoothly
    _queueController.advanceToStage(targetStageIndex);
  }

  void _animateToStage(int stageIndex) {
    // Animate all stages up to and including the current stage
    for (int i = 0; i <= stageIndex && i < _stages.length; i++) {
      // Add staggered delay for smooth appearance
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _stageAnimations[i].forward();
        }
      });
      
      // Animate connecting line after stage completion
      if (i < _lineAnimations.length) {
        Future.delayed(Duration(milliseconds: i * 100 + 200), () {
          if (mounted) {
            _lineAnimations[i].forward();
          }
        });
      }
    }
  }

  int _getCurrentStageIndex() {
    switch (widget.currentStage) {
      case ReceiptLoadingStage.uploaded:
        return 0;
      case ReceiptLoadingStage.ocrProcessing:
        return 1;
      case ReceiptLoadingStage.analyzingItems:
        return 2;
      case ReceiptLoadingStage.completed:
        return 3;
      case ReceiptLoadingStage.error:
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
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = ResponsiveLayout.isNarrowScreen(context);
    final padding = isNarrowScreen ? 12.0 : 20.0;
    
    // Calculate available height more conservatively for narrow screens
    final aspectRatio = screenHeight / screenWidth;
    final isVeryTallScreen = aspectRatio > 2.0; // 19.5:9 and similar
    final maxHeightRatio = isVeryTallScreen ? 0.65 : 0.8;
    
    return SingleChildScrollView(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * maxHeightRatio,
          maxWidth: screenWidth * 0.9,
        ),
        padding: EdgeInsets.all(padding),
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
            // Receipt image preview (if provided) - with size constraints
            if (widget.receiptImage != null) ...[
              Container(
                constraints: BoxConstraints(
                  maxHeight: isVeryTallScreen ? screenHeight * 0.18 : screenHeight * 0.25,
                  maxWidth: double.infinity,
                ),
                child: widget.receiptImage!,
              ),
              SizedBox(height: isNarrowScreen ? 12 : 20),
            ],
            
            // Current stage message - with flexible text wrapping
            Text(
              widget.message,
              style: AppStyles.h3.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
                fontSize: isVeryTallScreen ? 15 : (isNarrowScreen ? 16 : 18),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            if (widget.secondaryMessage != null) ...[
              SizedBox(height: 6),
              Text(
                widget.secondaryMessage!,
                style: AppStyles.bodyRegular.copyWith(
                  color: AppColors.textLight,
                  fontSize: isVeryTallScreen ? 12 : (isNarrowScreen ? 13 : 14),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            SizedBox(height: isVeryTallScreen ? 12 : (isNarrowScreen ? 16 : 24)),
            
            // Stage indicators - with constrained height
            Container(
              height: isVeryTallScreen ? 60 : (isNarrowScreen ? 70 : 80),
              child: Row(
                children: [
                  for (int i = 0; i < _stages.length; i++) ...[
                    _buildStageIndicator(i),
                    if (i < _stages.length - 1) _buildConnectingLine(i),
                  ],
                ],
              ),
            ),
            
            // Cancel button - only show if space allows
            if (widget.onCancel != null) ...[
              SizedBox(height: isVeryTallScreen ? 8 : (isNarrowScreen ? 12 : 16)),
              TextButton(
                onPressed: widget.onCancel,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20, 
                    vertical: isVeryTallScreen ? 6 : (isNarrowScreen ? 8 : 12)
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: AppStyles.bodyBold.copyWith(
                    color: AppColors.textLight,
                    fontSize: isVeryTallScreen ? 12 : (isNarrowScreen ? 13 : 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStageIndicator(int index) {
    final stage = _stages[index];
    // Use visual stage from queue controller instead of manually tracked one
    final isCompleted = _currentVisualStage >= 0 && index < _currentVisualStage;
    final isCurrent = _currentVisualStage >= 0 && index == _currentVisualStage && widget.currentStage != ReceiptLoadingStage.error;
    final isError = widget.currentStage == ReceiptLoadingStage.error && index == _currentVisualStage;
    
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final aspectRatio = screenHeight / screenWidth;
    final isVeryTallScreen = aspectRatio > 2.0;
    
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _stageAnimations[index],
            builder: (context, child) {
              return FadeTransition(
                opacity: _stageAnimations[index],
                child: Container(
                  width: isVeryTallScreen ? 32 : 40,
                  height: isVeryTallScreen ? 32 : 40,
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
                      size: isVeryTallScreen ? 16 : 20,
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: isVeryTallScreen ? 4 : 8),
          Text(
            stage.label,
            style: AppStyles.caption.copyWith(
              color: isCompleted || isCurrent
                  ? AppColors.textDark
                  : AppColors.textLight,
              fontWeight: isCompleted || isCurrent
                  ? FontWeight.w600
                  : FontWeight.normal,
              fontSize: isVeryTallScreen ? 10 : 12,
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
}

class StageInfo {
  final IconData icon;
  final String label;
  final ReceiptLoadingStage stage;

  const StageInfo({
    required this.icon,
    required this.label,
    required this.stage,
  });
}