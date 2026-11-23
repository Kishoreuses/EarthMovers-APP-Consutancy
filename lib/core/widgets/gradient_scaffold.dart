import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GradientScaffold extends StatefulWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool showOrbs;

  const GradientScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.drawer,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.showOrbs = true,
  });

  @override
  State<GradientScaffold> createState() => _GradientScaffoldState();
}

class _GradientScaffoldState extends State<GradientScaffold>
    with SingleTickerProviderStateMixin {
  late AnimationController _orbController;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      appBar: widget.appBar,
      drawer: widget.drawer,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: widget.bottomNavigationBar,
      body: Stack(
        children: [
          // Dark gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
          ),
          // Animated floating orbs
          if (widget.showOrbs)
            AnimatedBuilder(
              animation: _orbController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _OrbPainter(_orbController.value),
                  size: Size.infinite,
                );
              },
            ),
          // Main content
          widget.body,
        ],
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double progress;
  _OrbPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // Amber orb (top-right area)
    final amberPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.amber.withOpacity(0.12),
          AppTheme.amber.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(
          size.width * 0.8 + sin(progress * pi * 2) * 30,
          size.height * 0.15 + cos(progress * pi * 2) * 20,
        ),
        radius: 120,
      ));
    canvas.drawCircle(
      Offset(
        size.width * 0.8 + sin(progress * pi * 2) * 30,
        size.height * 0.15 + cos(progress * pi * 2) * 20,
      ),
      120,
      amberPaint,
    );

    // Blue orb (bottom-left area)
    final bluePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.blue.withOpacity(0.08),
          AppTheme.blue.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(
          size.width * 0.2 + cos(progress * pi * 2) * 25,
          size.height * 0.75 + sin(progress * pi * 2) * 30,
        ),
        radius: 140,
      ));
    canvas.drawCircle(
      Offset(
        size.width * 0.2 + cos(progress * pi * 2) * 25,
        size.height * 0.75 + sin(progress * pi * 2) * 30,
      ),
      140,
      bluePaint,
    );

    // Subtle purple orb (center)
    final purplePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.purple.withOpacity(0.05),
          AppTheme.purple.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(
          size.width * 0.5 + sin(progress * pi) * 40,
          size.height * 0.45 + cos(progress * pi) * 35,
        ),
        radius: 100,
      ));
    canvas.drawCircle(
      Offset(
        size.width * 0.5 + sin(progress * pi) * 40,
        size.height * 0.45 + cos(progress * pi) * 35,
      ),
      100,
      purplePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// A wave-shaped clip for section headers / dashboard panels
class WaveClipper extends CustomClipper<Path> {
  final double waveHeight;
  WaveClipper({this.waveHeight = 40});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - waveHeight);

    final firstControlPoint = Offset(size.width * 0.25, size.height);
    final firstEndPoint = Offset(size.width * 0.5, size.height - waveHeight / 2);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    final secondControlPoint = Offset(size.width * 0.75, size.height - waveHeight * 1.5);
    final secondEndPoint = Offset(size.width, size.height - waveHeight);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(WaveClipper oldClipper) => false;
}

/// A header widget with wave-shaped bottom edge
class WaveHeader extends StatelessWidget {
  final double height;
  final Gradient gradient;
  final Widget? child;

  const WaveHeader({
    super.key,
    this.height = 220,
    this.gradient = AppTheme.amberGradient,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: WaveClipper(),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(gradient: gradient),
        child: child,
      ),
    );
  }
}
