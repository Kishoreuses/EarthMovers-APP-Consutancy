import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:earthmovers_app/core/theme/app_theme.dart';
import 'package:earthmovers_app/core/widgets/gradient_scaffold.dart';
import 'package:earthmovers_app/core/theme/page_transitions.dart';
import 'signin_screen.dart';

// ─── Data models for particles ────────────────────────────────────────────────

class _Brick {
  double x, y, width, height, speed, opacity, rotation;
  Color color;

  _Brick({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.speed,
    required this.opacity,
    required this.rotation,
    required this.color,
  });
}

class _Vehicle {
  double x, y, speed, bodyWidth, bodyHeight;
  double wheelRadius;
  Color color;

  _Vehicle({
    required this.x,
    required this.y,
    required this.speed,
    required this.bodyWidth,
    required this.bodyHeight,
    required this.wheelRadius,
    required this.color,
  });
}

class _DustParticle {
  double x, y, radius, opacity, speed;

  _DustParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.opacity,
    required this.speed,
  });
}

// ─── Custom Painter ───────────────────────────────────────────────────────────

class _ConstructionParticlePainter extends CustomPainter {
  final double animValue; // 0..1 looping
  final List<_Brick> bricks;
  final List<_Vehicle> vehicles;
  final List<_DustParticle> dustParticles;
  final Size canvasSize;

  _ConstructionParticlePainter({
    required this.animValue,
    required this.bricks,
    required this.vehicles,
    required this.dustParticles,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintBricks(canvas, size);
    _paintVehicles(canvas, size);
    _paintDust(canvas, size);
  }

  void _paintBricks(Canvas canvas, Size size) {
    for (final brick in bricks) {
      // Float upward cyclically
      final cycleY = (brick.y - animValue * brick.speed * size.height) % size.height;
      final fadeZone = cycleY / size.height;
      final alpha = (brick.opacity * (fadeZone < 0.2 ? fadeZone / 0.2 : (fadeZone > 0.8 ? (1.0 - fadeZone) / 0.2 : 1.0))).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = brick.color.withOpacity(alpha)
        ..style = PaintingStyle.fill;

      canvas.save();
      final cx = brick.x * size.width;
      canvas.translate(cx, cycleY);
      canvas.rotate(brick.rotation + animValue * 0.5);

      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: brick.width, height: brick.height),
        const Radius.circular(2),
      );
      canvas.drawRRect(rrect, paint);

      // Subtle border
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = brick.color.withOpacity(alpha * 0.6);
      canvas.drawRRect(rrect, paint);

      canvas.restore();
    }
  }

  void _paintVehicles(Canvas canvas, Size size) {
    for (final v in vehicles) {
      // Drive left-to-right cyclically
      final cycleX = ((v.x * size.width) + animValue * v.speed * size.width) % (size.width + v.bodyWidth * 2) - v.bodyWidth;
      final baseY = v.y * size.height;

      canvas.save();
      canvas.translate(cycleX, baseY);

      final bodyPaint = Paint()
        ..color = v.color
        ..style = PaintingStyle.fill;

      // Body rectangle
      final bodyRect = Rect.fromLTWH(0, -v.bodyHeight, v.bodyWidth, v.bodyHeight);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bodyRect, const Radius.circular(3)),
        bodyPaint,
      );

      // Cabin (smaller rectangle on top-left)
      final cabinRect = Rect.fromLTWH(0, -v.bodyHeight - v.bodyHeight * 0.5, v.bodyWidth * 0.4, v.bodyHeight * 0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(cabinRect, const Radius.circular(2)),
        Paint()..color = v.color.withOpacity(0.7),
      );

      // Cabin window
      final windowRect = Rect.fromLTWH(
        cabinRect.left + 2, cabinRect.top + 2,
        cabinRect.width - 4, cabinRect.height - 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(windowRect, const Radius.circular(1)),
        Paint()..color = AppTheme.blueLight.withOpacity(0.3),
      );

      // Excavator arm (line from right of body going up-right)
      final armPaint = Paint()
        ..color = v.color.withOpacity(0.8)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      
      final armStart = Offset(v.bodyWidth * 0.75, -v.bodyHeight);
      final armMid = Offset(v.bodyWidth * 1.1, -v.bodyHeight * 1.8);
      final armEnd = Offset(v.bodyWidth * 1.3, -v.bodyHeight * 1.2 + sin(animValue * pi * 2) * 3);
      canvas.drawLine(armStart, armMid, armPaint);
      canvas.drawLine(armMid, armEnd, armPaint);

      // Bucket at arm end
      canvas.drawRect(
        Rect.fromCenter(center: armEnd, width: 5, height: 4),
        Paint()..color = v.color.withOpacity(0.6),
      );

      // Wheels with rotation
      final wheelPaint = Paint()
        ..color = const Color(0xFF333355)
        ..style = PaintingStyle.fill;
      final wheelBorderPaint = Paint()
        ..color = AppTheme.textMuted.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      final hubPaint = Paint()
        ..color = AppTheme.glassBorder
        ..style = PaintingStyle.fill;

      // Left wheel
      final lwCenter = Offset(v.bodyWidth * 0.2, 0);
      canvas.drawCircle(lwCenter, v.wheelRadius, wheelPaint);
      canvas.drawCircle(lwCenter, v.wheelRadius, wheelBorderPaint);
      canvas.drawCircle(lwCenter, v.wheelRadius * 0.3, hubPaint);

      // Right wheel
      final rwCenter = Offset(v.bodyWidth * 0.75, 0);
      canvas.drawCircle(rwCenter, v.wheelRadius, wheelPaint);
      canvas.drawCircle(rwCenter, v.wheelRadius, wheelBorderPaint);
      canvas.drawCircle(rwCenter, v.wheelRadius * 0.3, hubPaint);

      // Wheel spokes (rotating)
      final spokeAngle = animValue * pi * 4;
      for (final center in [lwCenter, rwCenter]) {
        for (int i = 0; i < 4; i++) {
          final angle = spokeAngle + (pi / 2) * i;
          final dx = cos(angle) * v.wheelRadius * 0.7;
          final dy = sin(angle) * v.wheelRadius * 0.7;
          canvas.drawLine(
            center,
            center + Offset(dx, dy),
            Paint()
              ..color = AppTheme.glassBorder.withOpacity(0.4)
              ..strokeWidth = 0.5,
          );
        }
      }

      canvas.restore();
    }
  }

  void _paintDust(Canvas canvas, Size size) {
    for (final d in dustParticles) {
      final cycleX = (d.x * size.width + animValue * d.speed * size.width * 0.3) % size.width;
      final cycleY = d.y * size.height - animValue * d.speed * size.height * 0.05;
      final alpha = (d.opacity * (1.0 - (animValue * 0.7))).clamp(0.0, 1.0);

      canvas.drawCircle(
        Offset(cycleX, cycleY),
        d.radius,
        Paint()..color = AppTheme.amber.withOpacity(alpha * 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConstructionParticlePainter oldDelegate) {
    return oldDelegate.animValue != animValue;
  }
}

// ─── Logo Screen ──────────────────────────────────────────────────────────────

class Logo extends StatefulWidget {
  const Logo({super.key});

  @override
  State<Logo> createState() => _LogoState();
}

class _LogoState extends State<Logo> with TickerProviderStateMixin {
  // Logo animation
  late AnimationController _logoController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Background particles animation (looping)
  late AnimationController _particleController;

  // Data
  late List<_Brick> _bricks;
  late List<_Vehicle> _vehicles;
  late List<_DustParticle> _dustParticles;

  final _random = Random(42);

  @override
  void initState() {
    super.initState();

    // Generate particles
    _bricks = _generateBricks();
    _vehicles = _generateVehicles();
    _dustParticles = _generateDust();

    // Logo animation controller
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    _logoController.forward();

    // Particle animation controller (loops)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    // Navigate to login after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          FadeScalePageRoute(page: const Login()),
        );
      }
    });
  }

  List<_Brick> _generateBricks() {
    final colors = [
      AppTheme.amber.withOpacity(0.6),
      AppTheme.amberDark.withOpacity(0.5),
      AppTheme.amberLight.withOpacity(0.4),
      const Color(0xFFCC7722).withOpacity(0.5),
      const Color(0xFFB8860B).withOpacity(0.4),
    ];

    return List.generate(15, (i) {
      return _Brick(
        x: _random.nextDouble(),
        y: _random.nextDouble() * 1.2,
        width: 6 + _random.nextDouble() * 8,
        height: 4 + _random.nextDouble() * 4,
        speed: 0.3 + _random.nextDouble() * 0.6,
        opacity: 0.2 + _random.nextDouble() * 0.4,
        rotation: _random.nextDouble() * pi,
        color: colors[_random.nextInt(colors.length)],
      );
    });
  }

  List<_Vehicle> _generateVehicles() {
    final colors = [
      AppTheme.amber.withOpacity(0.35),
      AppTheme.amberDark.withOpacity(0.3),
      const Color(0xFFD4A017).withOpacity(0.25),
    ];

    return List.generate(3, (i) {
      return _Vehicle(
        x: i * 0.35,
        y: 0.82 + i * 0.05,
        speed: 0.5 + _random.nextDouble() * 0.4,
        bodyWidth: 28 + _random.nextDouble() * 12,
        bodyHeight: 10 + _random.nextDouble() * 5,
        wheelRadius: 4 + _random.nextDouble() * 2,
        color: colors[i % colors.length],
      );
    });
  }

  List<_DustParticle> _generateDust() {
    return List.generate(20, (i) {
      return _DustParticle(
        x: _random.nextDouble(),
        y: 0.75 + _random.nextDouble() * 0.2,
        radius: 1 + _random.nextDouble() * 2,
        opacity: 0.2 + _random.nextDouble() * 0.4,
        speed: 0.5 + _random.nextDouble() * 0.8,
      );
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GradientScaffold(
      showOrbs: true,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // Background animated particles layer
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _ConstructionParticlePainter(
                        animValue: _particleController.value,
                        bricks: _bricks,
                        vehicles: _vehicles,
                        dustParticles: _dustParticles,
                        canvasSize: size,
                      ),
                      size: size,
                    );
                  },
                ),
              ),

              // Foreground: logo + text + progress
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // Glowing logo with scale & fade
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppTheme.amber, AppTheme.amberDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.amber.withOpacity(0.35),
                                  blurRadius: 36,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.surface,
                              ),
                              child: const CircleAvatar(
                                backgroundImage: AssetImage('images/l2.jpg'),
                                radius: 95,
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Brand name with glow and styling
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Text(
                              'KADAVUL EARTHMOVERS',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.amber,
                                fontFamily: 'Timmana',
                                fontSize: size.width < 380 ? 24 : 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                shadows: [
                                  Shadow(
                                    color: AppTheme.amber.withOpacity(0.5),
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'HEAVY MACHINERY & SERVICES',
                              style: GoogleFonts.poppins(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(flex: 2),

                      // Glass progress indicator pill
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.glass,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: AppTheme.glassBorder),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: const LinearProgressIndicator(
                                minHeight: 4,
                                backgroundColor: Color(0xFF1F1F35),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.amber,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
