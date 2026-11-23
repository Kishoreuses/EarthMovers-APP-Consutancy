import 'package:flutter/material.dart';

class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final AxisDirection direction;

  SlidePageRoute({
    required this.page,
    this.direction = AxisDirection.right,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            Offset begin;
            switch (direction) {
              case AxisDirection.right:
                begin = const Offset(1.0, 0.0);
                break;
              case AxisDirection.left:
                begin = const Offset(-1.0, 0.0);
                break;
              case AxisDirection.up:
                begin = const Offset(0.0, 1.0);
                break;
              case AxisDirection.down:
                begin = const Offset(0.0, -1.0);
                break;
            }

            final tween = Tween(begin: begin, end: Offset.zero).chain(
              CurveTween(curve: Curves.easeOutCubic),
            );

            final fadeTween = Tween(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: Curves.easeIn),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
        );
}

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadePageRoute({
    required this.page,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fadeAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            );

            final scaleAnimation = Tween<double>(
              begin: 0.95,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));

            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: child,
              ),
            );
          },
        );
}

typedef FadeScalePageRoute<T> = FadePageRoute<T>;
