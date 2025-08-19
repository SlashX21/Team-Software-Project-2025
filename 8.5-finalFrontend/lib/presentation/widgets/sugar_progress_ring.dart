import 'package:flutter/material.dart';
import 'dart:math' as math;

class SugarProgressRing extends StatelessWidget {
  final double progressPercentage;
  final String status;
  final double size;
  final double strokeWidth;
  final bool showPercentage;
  
  const SugarProgressRing({
    Key? key,
    required this.progressPercentage,
    required this.status,
    this.size = 40.0,
    this.strokeWidth = 9.0,
    this.showPercentage = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景环
          CustomPaint(
            size: Size(size, size),
            painter: _ProgressRingPainter(
              progress: 1.0,
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: strokeWidth,
            ),
          ),
          // 进度环
          CustomPaint(
            size: Size(size, size),
            painter: _ProgressRingPainter(
              progress: math.min(progressPercentage / 100, 1.0),
              color: _getProgressColor(),
              strokeWidth: strokeWidth,
            ),
          ),
          // 中心显示内容
          if (showPercentage)
            Text(
              '${progressPercentage.toInt()}%',
              style: TextStyle(
                fontSize: size * 0.2,
                fontWeight: FontWeight.bold,
                color: _getProgressColor(),
              ),
            ),
        ],
      ),
    );
  }
  
  Color _getProgressColor() {
    // 优先基于progressPercentage计算颜色，因为后端status可能不准确
    if (progressPercentage > 100) {
      return Colors.red[600]!;    // 超过100%为红色
    } else if (progressPercentage > 70) {
      return Colors.orange[600]!; // 70%-100%为橙色
    } else {
      return Colors.green[600]!;  // 70%以下为绿色
    }
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  
  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // 绘制进度环
    const startAngle = -math.pi / 2; // 从顶部开始
    final sweepAngle = 2 * math.pi * progress;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}