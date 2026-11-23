import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final Color? borderColor;
  final Color? fillColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = AppTheme.radiusLg,
    this.padding,
    this.margin,
    this.blur = 20,
    this.borderColor,
    this.fillColor,
    this.gradient,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppTheme.glassBorder,
          width: 1,
        ),
        gradient: gradient,
        color: gradient == null ? (fillColor ?? AppTheme.glass) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.02),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

/// A bent/curved glass card with a subtle tilt effect
class BentGlassCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color accentColor;
  final Color? borderColor;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const BentGlassCard({
    super.key,
    required this.child,
    this.borderRadius = AppTheme.radiusLg,
    this.padding,
    this.margin,
    this.accentColor = AppTheme.amber,
    this.borderColor,
    this.gradient,
    this.onTap,
  });

  @override
  State<BentGlassCard> createState() => _BentGlassCardState();
}

class _BentGlassCardState extends State<BentGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
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
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: _isPressed
                  ? widget.accentColor.withOpacity(0.5)
                  : (widget.borderColor ?? AppTheme.glassBorder),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withOpacity(_isPressed ? 0.15 : 0.05),
                blurRadius: _isPressed ? 30 : 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: widget.padding ?? const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  gradient: widget.gradient ??
                      LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.03),
                          widget.accentColor.withOpacity(0.03),
                        ],
                      ),
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
