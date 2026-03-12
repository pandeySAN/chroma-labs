import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/app_logo.dart';

/// Premium animated splash screen with modern micro-interactions
/// Inspired by Zomato/Swiggy app opening experience
class AnimatedSplashScreen extends StatefulWidget {
  final VoidCallback? onAnimationComplete;
  final bool showLoadingIndicator;

  const AnimatedSplashScreen({
    super.key,
    this.onAnimationComplete,
    this.showLoadingIndicator = true,
  });

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _gradientController;

  // Logo animations
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoRotation;

  // Text animations
  late Animation<double> _cerebroOpacity;
  late Animation<Offset> _cerebroSlide;
  late Animation<double> _partnerOpacity;
  late Animation<Offset> _partnerSlide;
  late Animation<double> _taglineOpacity;

  // Shimmer animation
  late Animation<double> _shimmerAnimation;

  // Pulse animation for logo glow
  late Animation<double> _pulseAnimation;

  // Gradient animation
  late Animation<double> _gradientAnimation;

  // Loading indicator
  late Animation<double> _loadingOpacity;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();

    // Set system UI for immersive splash
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0A2533),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _initializeAnimations() {
    // Logo animation controller (1.2 seconds with bounce effect)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Text animation controller (staggered, 800ms)
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Shimmer effect controller (continuous)
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Pulse controller for logo glow
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Gradient animation controller
    _gradientController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Logo scale with elastic/bounce effect
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 0.95)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
    ]).animate(_logoController);

    // Logo opacity (quick fade in)
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Subtle logo rotation
    _logoRotation = Tween<double>(begin: -0.05, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // CEREBRO text - fade + slide from bottom
    _cerebroOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _cerebroSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    // Clinic Partner text - staggered fade + slide
    _partnerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );
    _partnerSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Tagline opacity
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
      ),
    );

    // Loading indicator opacity
    _loadingOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    // Shimmer effect
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve: Curves.easeInOut,
      ),
    );

    // Pulse effect for logo glow
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Gradient animation
    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _gradientController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startAnimationSequence() async {
    // Start gradient animation immediately (loops)
    _gradientController.repeat(reverse: true);

    // Small delay before starting main animations
    await Future.delayed(const Duration(milliseconds: 100));

    // Start logo animation
    _logoController.forward();

    // Start text animations after logo begins
    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();

    // Start shimmer effect
    await Future.delayed(const Duration(milliseconds: 600));
    _shimmerController.repeat();

    // Start pulse effect
    _pulseController.repeat(reverse: true);

    // Notify when complete (for navigation)
    _textController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _logoController,
          _textController,
          _shimmerController,
          _pulseController,
          _gradientController,
        ]),
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: _buildAnimatedGradient(),
            ),
            child: Stack(
              children: [
                // Subtle background pattern
                _buildBackgroundPattern(),

                // Main content
                SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // Animated Logo
                      _buildAnimatedLogo(),

                      const SizedBox(height: 40),

                      // Animated Text Stack
                      _buildAnimatedText(),

                      const Spacer(flex: 2),

                      // Loading indicator
                      if (widget.showLoadingIndicator)
                        _buildLoadingIndicator(),

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  LinearGradient _buildAnimatedGradient() {
    // Cerebro brand gradient - dark navy matching the logo
    final gradientValue = _gradientAnimation.value;

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(
          const Color(0xFF153A4D),
          const Color(0xFF1A4A5D),
          gradientValue,
        )!,
        Color.lerp(
          const Color(0xFF0F2A3D),
          const Color(0xFF123542),
          gradientValue,
        )!,
        Color.lerp(
          const Color(0xFF0A2533),
          const Color(0xFF0F2A3D),
          gradientValue,
        )!,
      ],
      stops: [
        0.0 + (gradientValue * 0.1),
        0.5,
        1.0 - (gradientValue * 0.1),
      ],
    );
  }

  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.03,
        child: CustomPaint(
          painter: _GridPatternPainter(),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return Transform.rotate(
      angle: _logoRotation.value * math.pi,
      child: Transform.scale(
        scale: _logoScale.value,
        child: Opacity(
          opacity: _logoOpacity.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow pulse with teal/green gradient
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 180 + (_pulseAnimation.value * 20),
                    height: 180 + (_pulseAnimation.value * 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00B8A9)
                              .withOpacity(0.15 + (_pulseAnimation.value * 0.1)),
                          blurRadius: 30 + (_pulseAnimation.value * 20),
                          spreadRadius: 5 + (_pulseAnimation.value * 10),
                        ),
                        BoxShadow(
                          color: const Color(0xFF6FCF4E)
                              .withOpacity(0.1 + (_pulseAnimation.value * 0.05)),
                          blurRadius: 40 + (_pulseAnimation.value * 15),
                          spreadRadius: 2 + (_pulseAnimation.value * 5),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Main logo container with actual image
              Hero(
                tag: 'app_logo',
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                      BoxShadow(
                        color: const Color(0xFF00B8A9).withOpacity(0.3),
                        blurRadius: 25,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Cerebro logo image
                      const AppLogo(size: 160, borderRadius: 36),

                      // Shimmer overlay
                      AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, child) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(36),
                            child: ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0),
                                    Colors.white.withOpacity(0.2),
                                    Colors.white.withOpacity(0),
                                  ],
                                  stops: [
                                    _shimmerAnimation.value - 0.3,
                                    _shimmerAnimation.value,
                                    _shimmerAnimation.value + 0.3,
                                  ].map((s) => s.clamp(0.0, 1.0)).toList(),
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.srcATop,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedText() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Clinic Partner subtitle with gradient
        SlideTransition(
          position: _partnerSlide,
          child: FadeTransition(
            opacity: _partnerOpacity,
            child: ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  colors: [
                    Color(0xFF00B8A9),
                    Color(0xFF6FCF4E),
                  ],
                ).createShader(bounds);
              },
              child: const Text(
                'Clinic Partner',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 3.0,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Tagline
        FadeTransition(
          opacity: _taglineOpacity,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00B8A9).withOpacity(0.2),
                  const Color(0xFF6FCF4E).withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00B8A9).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Text(
              'Mind Re-Wired',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return FadeTransition(
      opacity: _loadingOpacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withOpacity(0.9),
              ),
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Initializing...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.8),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for subtle grid pattern background
class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 30.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom page route with fade and slide transition
class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeSlidePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );

            return FadeTransition(
              opacity: curvedAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
}

/// Scale fade page route for more dramatic transitions
class ScaleFadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ScaleFadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );

            return FadeTransition(
              opacity: curvedAnimation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
}
