import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final IconData? icon;
  final double height;
  final bool isLoading;
  final bool fullWidth;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.gradient = AppTheme.amberGradient,
    this.icon,
    this.height = 54,
    this.isLoading = false,
    this.fullWidth = true,
  });

  // Named constructors for common variants
  const GradientButton.amber({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 54,
    this.isLoading = false,
    this.fullWidth = true,
  }) : gradient = AppTheme.amberGradient;

  const GradientButton.blue({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 54,
    this.isLoading = false,
    this.fullWidth = true,
  }) : gradient = AppTheme.blueGradient;

  const GradientButton.emerald({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 54,
    this.isLoading = false,
    this.fullWidth = true,
  }) : gradient = AppTheme.emeraldGradient;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null && !widget.isLoading;

    return GestureDetector(
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.fullWidth ? double.infinity : null,
        height: widget.height,
        decoration: BoxDecoration(
          gradient: isDisabled
              ? LinearGradient(
                  colors: [
                    AppTheme.textMuted.withOpacity(0.3),
                    AppTheme.textMuted.withOpacity(0.2),
                  ],
                )
              : widget.gradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: isDisabled
              ? []
              : [
                  BoxShadow(
                    color: (widget.gradient as LinearGradient)
                        .colors
                        .first
                        .withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.textPrimary),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize:
                      widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// An outlined glass-style button
class GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color borderColor;
  final Color textColor;

  const GlassButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.borderColor = AppTheme.glassBorder,
    this.textColor = AppTheme.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
