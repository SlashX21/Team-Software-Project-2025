import 'package:flutter/material.dart';
import 'auth_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bgAnim;
  late Animation<double> _logoScaleAnim;
  late Animation<double> _logoFadeAnim;
  late Animation<double> _logoGlowAnim;
  late Animation<double> _textFadeAnim;
  late Animation<Offset> _textSlideAnim;
  late Animation<Offset> _finalSlideAnim;
  late Animation<double> _finalScaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    // ★ Background gradient: Extend duration to 0.28, curve changed to easeInOutCubic for smoother transition
    _bgAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.28, curve: Curves.easeInOutCubic),
    );
    // ★ Logo bounce: First 0.6 → 1.08 (light bounce) then back to 1.0
    _logoScaleAnim =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween(
              begin: 0.6,
              end: 1.08,
            ).chain(CurveTween(curve: Curves.easeOutBack)),
            weight: 60,
          ),
          TweenSequenceItem(
            tween: Tween(
              begin: 1.08,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeIn)),
            weight: 40,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.28, 0.56),
          ),
        );
    _logoFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.28, 0.56, curve: Curves.easeIn),
      ),
    );
    // ★ Glow: Quickly rise to 40, then slowly drop to 10, for a "breathing" effect
    _logoGlowAnim =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween(
              begin: 0.0,
              end: 40.0,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 40,
          ),
          TweenSequenceItem(
            tween: Tween(
              begin: 40.0,
              end: 10.0,
            ).chain(CurveTween(curve: Curves.easeIn)),
            weight: 60,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.28, 0.7),
          ),
        );
    // Text fade-in starts slightly earlier, displacement halved
    _textFadeAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.56, 0.75, curve: Curves.easeIn),
      ),
    );
    _textSlideAnim = Tween(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.56, 0.75, curve: Curves.easeOut),
          ),
        );
    // ★ Final gather: Displacement reduced to (-0.12, -0.10), scale to 0.9, softer
    _finalSlideAnim = Tween(begin: Offset.zero, end: const Offset(-0.12, -0.10))
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.75, 0.88, curve: Curves.decelerate),
          ),
        );
    _finalScaleAnim = Tween(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 0.88, curve: Curves.easeInOut),
      ),
    );
    _controller.forward();
    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthPage()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // 响应式尺寸计算
    final isSmallScreen = size.width < 400;
    final logoSize = isSmallScreen ? 100.0 : 140.0;
    final fontSize = isSmallScreen ? 36.0 : 48.0;
    final leftPadding = isSmallScreen ? 16.0 : 32.0;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: size.width,
            height: size.height,
            color: Colors.white,
            child: Center(
              child: Transform.scale(
                scale: _finalScaleAnim.value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // 检查是否需要垂直布局
                      final needVerticalLayout = constraints.maxWidth < 350;

                      if (needVerticalLayout) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // logo 动画
                            Opacity(
                              opacity: _logoFadeAnim.value,
                              child: Transform.scale(
                                scale: _logoScaleAnim.value,
                                child: SizedBox(
                                  width: logoSize,
                                  height: logoSize,
                                  child: Image.asset(
                                    'assets/images/logo_icon.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // 文字动画
                            FadeTransition(
                              opacity: _textFadeAnim,
                              child: SlideTransition(
                                position: _textSlideAnim,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Grocery',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        fontSize: fontSize,
                                        color: const Color(0xFF22C55E),
                                        letterSpacing: 1.2,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      'Guardian',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        fontSize: fontSize,
                                        color: const Color(0xFF22C55E),
                                        letterSpacing: 1.2,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // logo 动画
                            Opacity(
                              opacity: _logoFadeAnim.value,
                              child: Transform.scale(
                                scale: _logoScaleAnim.value,
                                child: SizedBox(
                                  width: logoSize,
                                  height: logoSize,
                                  child: Image.asset(
                                    'assets/images/logo_icon.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            // 文字动画
                            Flexible(
                              child: FadeTransition(
                                opacity: _textFadeAnim,
                                child: SlideTransition(
                                  position: _textSlideAnim,
                                  child: Padding(
                                    padding: EdgeInsets.only(left: leftPadding),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'Grocery',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w600,
                                              fontSize: fontSize,
                                              color: const Color(0xFF22C55E),
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'Guardian',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w600,
                                              fontSize: fontSize,
                                              color: const Color(0xFF22C55E),
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
