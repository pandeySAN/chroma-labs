import 'package:flutter/material.dart';

/// Shimmer animation wrapper for skeleton loaders
/// Creates a subtle shimmer effect similar to Facebook/LinkedIn loading states
class ShimmerLoader extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const ShimmerLoader({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE8E8E8),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
              transform: const GradientRotation(0.5),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

/// Skeleton box with customizable dimensions and border radius
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsets? margin;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton circle for avatars
class SkeletonCircle extends StatelessWidget {
  final double size;
  final EdgeInsets? margin;

  const SkeletonCircle({
    super.key,
    required this.size,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: margin,
      decoration: const BoxDecoration(
        color: Color(0xFFE8E8E8),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Skeleton for appointment card - matches the real card layout
class AppointmentCardSkeleton extends StatelessWidget {
  const AppointmentCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with avatar, name, and status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar skeleton
              const SkeletonCircle(size: 60),
              const SizedBox(width: 16),

              // Name and email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(
                      width: 140,
                      height: 20,
                      borderRadius: 6,
                    ),
                    const SizedBox(height: 8),
                    SkeletonBox(
                      width: 180,
                      height: 14,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),

              // Status badge skeleton
              SkeletonBox(
                width: 90,
                height: 32,
                borderRadius: 12,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Divider
          Container(
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),

          const SizedBox(height: 20),

          // Date and time row
          Row(
            children: [
              // Date chip skeleton
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const SkeletonCircle(size: 18),
                      const SizedBox(width: 10),
                      SkeletonBox(width: 70, height: 14, borderRadius: 4),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Time chip skeleton
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const SkeletonCircle(size: 18),
                      const SizedBox(width: 10),
                      SkeletonBox(width: 60, height: 14, borderRadius: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Video call button skeleton
          SkeletonBox(
            width: double.infinity,
            height: 52,
            borderRadius: 14,
          ),
        ],
      ),
    );
  }
}

/// Skeleton list for appointments loading state
class AppointmentListSkeleton extends StatelessWidget {
  final int itemCount;

  const AppointmentListSkeleton({
    super.key,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return const AppointmentCardSkeleton();
        },
      ),
    );
  }
}

/// Skeleton for date header
class DateHeaderSkeleton extends StatelessWidget {
  const DateHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: SkeletonBox(
        width: 120,
        height: 36,
        borderRadius: 12,
      ),
    );
  }
}

/// Login form skeleton
class LoginFormSkeleton extends StatelessWidget {
  const LoginFormSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 80, height: 28, borderRadius: 6),
            const SizedBox(height: 24),
            SkeletonBox(width: double.infinity, height: 56, borderRadius: 12),
            const SizedBox(height: 16),
            SkeletonBox(width: double.infinity, height: 56, borderRadius: 12),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: SkeletonBox(width: 120, height: 20, borderRadius: 4),
            ),
            const SizedBox(height: 24),
            SkeletonBox(width: double.infinity, height: 56, borderRadius: 12),
          ],
        ),
      ),
    );
  }
}

/// Animated content appearance - fades in content smoothly
class FadeInContent extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final bool slideUp;

  const FadeInContent({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.slideUp = true,
  });

  @override
  State<FadeInContent> createState() => _FadeInContentState();
}

class _FadeInContentState extends State<FadeInContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.slideUp ? const Offset(0, 0.05) : Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Skeleton to content transition - shows skeleton then fades to real content
class SkeletonToContent extends StatelessWidget {
  final bool isLoading;
  final Widget skeleton;
  final Widget content;
  final Duration transitionDuration;

  const SkeletonToContent({
    super.key,
    required this.isLoading,
    required this.skeleton,
    required this.content,
    this.transitionDuration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: transitionDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: isLoading
          ? KeyedSubtree(key: const ValueKey('skeleton'), child: skeleton)
          : KeyedSubtree(key: const ValueKey('content'), child: content),
    );
  }
}

/// Staggered fade in for list items
class StaggeredFadeInList extends StatelessWidget {
  final List<Widget> children;
  final Duration itemDelay;
  final Duration itemDuration;
  final EdgeInsets? padding;

  const StaggeredFadeInList({
    super.key,
    required this.children,
    this.itemDelay = const Duration(milliseconds: 50),
    this.itemDuration = const Duration(milliseconds: 300),
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: children.length,
      itemBuilder: (context, index) {
        return FadeInContent(
          delay: itemDelay * index,
          duration: itemDuration,
          child: children[index],
        );
      },
    );
  }
}

/// Pulse animation for loading states
class PulseLoader extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const PulseLoader({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  State<PulseLoader> createState() => _PulseLoaderState();
}

class _PulseLoaderState extends State<PulseLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}
