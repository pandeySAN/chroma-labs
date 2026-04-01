import 'package:flutter/material.dart';

/// Slide up + fade — used for most forward navigations
class FadeSlideRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeSlideRoute({required this.page})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 340),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          transitionsBuilder: (ctx, animation, secondary, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curve,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(curve),
                child: child,
              ),
            );
          },
        );
}

/// Scale + fade — used for dialogs / modals / confirmation screens
class ScaleFadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ScaleFadeRoute({required this.page})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (ctx, animation, secondary, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: CurvedAnimation(
                  parent: animation, curve: Curves.easeOut),
              child: ScaleTransition(
                scale:
                    Tween<double>(begin: 0.93, end: 1.0).animate(curve),
                child: child,
              ),
            );
          },
        );
}

/// Horizontal slide — iOS-style, used for step-by-step flows
class SlideRightRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideRightRoute({required this.page})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          transitionsBuilder: (ctx, animation, secondary, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0),
                end: Offset.zero,
              ).animate(curve),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset.zero,
                  end: const Offset(-0.25, 0),
                ).animate(CurvedAnimation(
                  parent: secondary,
                  curve: Curves.easeInCubic,
                )),
                child: child,
              ),
            );
          },
        );
}

/// Bottom sheet-style rise — used for payment / success screens
class BottomRiseRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  BottomRiseRoute({required this.page})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 320),
          transitionsBuilder: (ctx, animation, secondary, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuart,
              reverseCurve: Curves.easeInQuart,
            );
            return FadeTransition(
              opacity: CurvedAnimation(
                  parent: animation, curve: const Interval(0, 0.5)),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(curve),
                child: child,
              ),
            );
          },
        );
}

extension NavigatorX on BuildContext {
  Future<T?> pushFadeSlide<T>(Widget page) =>
      Navigator.of(this).push<T>(FadeSlideRoute(page: page));

  Future<T?> pushScaleFade<T>(Widget page) =>
      Navigator.of(this).push<T>(ScaleFadeRoute(page: page));

  Future<T?> pushSlideRight<T>(Widget page) =>
      Navigator.of(this).push<T>(SlideRightRoute(page: page));

  Future<T?> pushBottomRise<T>(Widget page) =>
      Navigator.of(this).push<T>(BottomRiseRoute(page: page));

  Future<T?> pushReplaceFadeSlide<T>(Widget page) =>
      Navigator.of(this)
          .pushReplacement<T, dynamic>(FadeSlideRoute(page: page));
}
