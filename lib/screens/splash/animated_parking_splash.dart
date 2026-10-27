import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/storage.dart';
import '../../core/theme.dart';
import '../../models/user.dart';
import '../../widgets/brand_logo.dart';
import '../auth/login_screen.dart';
import '../home_nav.dart';

class AnimatedParkingSplash extends StatefulWidget {
  final UserSession? initialUser;

  const AnimatedParkingSplash({
    super.key,
    this.initialUser,
  });

  @override
  State<AnimatedParkingSplash> createState() => _AnimatedParkingSplashState();
}

class _AnimatedParkingSplashState extends State<AnimatedParkingSplash>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  UserSession? _currentUser;
  bool _hasNavigated = false;
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.initialUser;
    _checkStoredSession();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6500),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToDestination();
      }
    });
  }

  Future<void> _checkStoredSession() async {
    if (_currentUser == null) {
      final user = await StorageService.getUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    }
  }

  void _navigateToDestination() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    final Widget targetScreen =
        _currentUser != null ? const HomeNav() : const LoginScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value; // 0.0 to 1.0

            // Dynamic phase telemetry & titles
            String phaseTitle;
            String phaseDesc;
            Color phaseColor;

            if (t < 0.28) {
              phaseTitle = 'GATE 01: VEHICLE RECOGNITION';
              phaseDesc = 'License plate auto-detected. Access barrier opening...';
              phaseColor = AppTheme.primary;
            } else if (t < 0.58) {
              phaseTitle = 'ACCESS GRANTED • PATH GUIDANCE';
              phaseDesc = 'Turn-by-turn guidance navigating to reserved Bay 01.';
              phaseColor = AppTheme.accent;
            } else if (t < 0.85) {
              final dist = ((1.0 - ((t - 0.58) / 0.27)) * 1.8).clamp(0.2, 1.8);
              phaseTitle = 'AUTOPARK: PRECISION DOCKING';
              phaseDesc = 'Ultrasonic LiDAR active: ${dist.toStringAsFixed(1)}m • Docking accuracy 99.8%';
              phaseColor = AppTheme.accent;
            } else {
              phaseTitle = 'BAY 01 SECURED • PASS READY';
              phaseDesc = 'Vehicle safely parked. Touchless digital pass activated.';
              phaseColor = AppTheme.primary;
            }

            return Stack(
              children: [
                // 1. Top Bar: High-contrast Brand & Skip Button
                Positioned(
                  top: 14,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Brand Pill
                      Row(
                        children: [
                          const ParkMeLogoBadge(size: 34),
                          const SizedBox(width: 10),
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Park',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Me',
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Skip Intro Pill
                      InkWell(
                        onTap: _navigateToDestination,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  value: 1.0 - t,
                                  strokeWidth: 2,
                                  color: AppTheme.primary,
                                  backgroundColor: AppTheme.border,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Skip Intro',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Central 3D Isometric Simulation Viewport
                Positioned.fill(
                  top: 70,
                  bottom: 155,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _tiltX = (_tiltX + details.delta.dy * 0.003).clamp(-0.15, 0.15);
                          _tiltY = (_tiltY - details.delta.dx * 0.003).clamp(-0.25, 0.25);
                        });
                      },
                      onPanEnd: (_) {
                        setState(() {
                          _tiltX = 0.0;
                          _tiltY = 0.0;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF070B14),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              blurRadius: 32,
                              spreadRadius: -4,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Stack(
                            children: [
                              // 3D Canvas
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _IsometricSimulationPainter(
                                    progress: t,
                                    tiltX: _tiltX,
                                    tiltY: _tiltY,
                                  ),
                                ),
                              ),

                              // Live Floating Telemetry Badge on Top
                              Positioned(
                                top: 12,
                                left: 14,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: phaseColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        '3D SMART FACILITY • CHENNAI MLCP',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Interactive Tilt Hint Badge
                              Positioned(
                                top: 12,
                                right: 14,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.touch_app_rounded, size: 11, color: Colors.white70),
                                      SizedBox(width: 4),
                                      Text(
                                        'Touch to Tilt',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Final Brand Splash Zoom (Phase 4: 0.86 to 1.0)
                if (t >= 0.86)
                  Positioned.fill(
                    child: FadeTransition(
                      opacity: AlwaysStoppedAnimation(
                        ((t - 0.86) / 0.14).clamp(0.0, 1.0),
                      ),
                      child: Container(
                        color: AppTheme.background.withValues(alpha: 0.98),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const ParkMeLogoBadge(size: 84),
                              const SizedBox(height: 20),
                              RichText(
                                text: const TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Park',
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 32,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Me',
                                      style: TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 32,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Never Circle The Block Again.',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // 4. Bottom Story Telemetry HUD Card
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: phaseColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              phaseTitle,
                              style: TextStyle(
                                color: phaseColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          phaseDesc,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: t,
                            minHeight: 4,
                            backgroundColor: AppTheme.surfaceLight,
                            valueColor: AlwaysStoppedAnimation<Color>(phaseColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// High-End 3D Isometric Parking Simulator Painter
class _IsometricSimulationPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final double tiltX;
  final double tiltY;

  _IsometricSimulationPainter({
    required this.progress,
    required this.tiltX,
    required this.tiltY,
  });

  // Isometric Projection Transform (30 deg pitch, 45 deg yaw)
  Offset _iso(double x, double y, double z, Offset origin) {
    // True isometric projection formula
    final double isoX = (x - y) * math.cos(math.pi / 6);
    final double isoY = (x + y) * math.sin(math.pi / 6) - z;

    // Apply interactive drag tilts
    final double rotX = isoX * math.cos(tiltY) - isoY * math.sin(tiltX) * 0.3;
    final double rotY = isoY * math.cos(tiltX) + isoX * math.sin(tiltY) * 0.3;

    return Offset(origin.dx + rotX, origin.dy + rotY);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width * 0.5, size.height * 0.44);

    // 1. Draw Ambient Radial Stage Lighting
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [
          const Color(0xFF1E293B).withValues(alpha: 0.6),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);

    // 2. Draw 3D Isometric Ground Grid
    final gridPaint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.25)
      ..strokeWidth = 1.0;

    for (double i = -140; i <= 140; i += 35) {
      final p1 = _iso(i, -140, 0, origin);
      final p2 = _iso(i, 140, 0, origin);
      canvas.drawLine(p1, p2, gridPaint);

      final p3 = _iso(-140, i, 0, origin);
      final p4 = _iso(140, i, 0, origin);
      canvas.drawLine(p3, p4, gridPaint);
    }

    // 3. Draw Parking Facility Bays
    // Bay 02 (Occupied): x from 20 to 110, y from -110 to -30
    _drawParkingBay(
      canvas: canvas,
      origin: origin,
      x1: 25,
      y1: -110,
      x2: 105,
      y2: -35,
      label: 'BAY 02',
      isOccupied: true,
    );

    // Bay 01 (Target Available Bay): x from 25 to 105, y from 10 to 85
    _drawParkingBay(
      canvas: canvas,
      origin: origin,
      x1: 25,
      y1: 15,
      x2: 105,
      y2: 90,
      label: 'BAY 01',
      isOccupied: false,
    );

    // 4. Draw Parked Static Vehicle in Bay 02
    _drawStaticParkedVehicle(canvas, origin, x: 65, y: -72);

    // 5. Draw Electronic Gate & Access Barrier (at x = -50, y = 15)
    _drawAccessBarrier(canvas, origin, gateX: -50, gateY: 15, progress: progress);

    // 6. Calculate Moving Vehicle Path (Approaches gate -> passes -> reverses into Bay 01)
    double carX;
    double carY;
    double carHeading; // in radians
    bool isDocked = false;

    if (progress < 0.28) {
      // Approach Phase: drives from (-130, -50) to (-65, 10)
      final subT = progress / 0.28;
      carX = -130 + (65 * subT);
      carY = -50 + (60 * subT);
      carHeading = 0.75;
    } else if (progress < 0.58) {
      // Gate Passage Phase: drives through barrier to aisle (40, 45)
      final subT = (progress - 0.28) / 0.30;
      carX = -65 + (105 * subT);
      carY = 10 + (35 * subT);
      carHeading = 0.50 - (0.35 * subT);
    } else if (progress < 0.85) {
      // Reversing / Docking Phase into Bay 01: moves from (40, 45) into (65, 52)
      final subT = (progress - 0.58) / 0.27;
      carX = 40 + (25 * subT);
      carY = 45 + (7 * subT);
      carHeading = 0.15;
    } else {
      // Locked Docked Position
      carX = 65;
      carY = 52;
      carHeading = 0.15;
      isDocked = true;
    }

    // 7. Draw Trajectory Line from entrance to Bay 01
    _drawTrajectoryGuide(canvas, origin, progress: progress);

    // 8. Draw Moving Luxury Vehicle with Glowing Headlights and Shadows
    _drawLuxuryVehicle(
      canvas: canvas,
      origin: origin,
      x: carX,
      y: carY,
      heading: carHeading,
      isDocked: isDocked,
      progress: progress,
    );

    // 9. Draw Ultrasonic LiDAR Sonar Waves during Docking (0.58 to 0.85)
    if (progress >= 0.58 && progress < 0.86) {
      _drawLiDARWaves(canvas, origin, carX: carX, carY: carY, progress: progress);
    }

    // 10. Draw Docked Success Checkmark Badge (Phase 4)
    if (isDocked) {
      _drawDockedBadge(canvas, origin, x: 65, y: 52, progress: progress);
    }
  }

  // Draw Parking Bay Lines & Luminous Grounds
  void _drawParkingBay({
    required Canvas canvas,
    required Offset origin,
    required double x1,
    required double y1,
    required double x2,
    required double y2,
    required String label,
    required bool isOccupied,
  }) {
    final c1 = _iso(x1, y1, 0, origin);
    final c2 = _iso(x2, y1, 0, origin);
    final c3 = _iso(x2, y2, 0, origin);
    final c4 = _iso(x1, y2, 0, origin);

    final bayPath = Path()
      ..moveTo(c1.dx, c1.dy)
      ..lineTo(c2.dx, c2.dy)
      ..lineTo(c3.dx, c3.dy)
      ..lineTo(c4.dx, c4.dy)
      ..close();

    // Ground fill
    final fillPaint = Paint()
      ..color = isOccupied
          ? const Color(0xFF1E293B).withValues(alpha: 0.35)
          : const Color(0xFF10B981).withValues(alpha: 0.10);
    canvas.drawPath(bayPath, fillPaint);

    // Bay border
    final borderPaint = Paint()
      ..color = isOccupied
          ? const Color(0xFF475569).withValues(alpha: 0.5)
          : const Color(0xFF10B981)
      ..strokeWidth = isOccupied ? 1.5 : 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(bayPath, borderPaint);

    // Bay curb bumper at back (x2)
    final b1 = _iso(x2 - 5, y1 + 5, 0, origin);
    final b2 = _iso(x2 - 5, y2 - 5, 0, origin);
    final curbPaint = Paint()
      ..color = isOccupied ? const Color(0xFF64748B) : const Color(0xFF10B981)
      ..strokeWidth = 3.0;
    canvas.drawLine(b1, b2, curbPaint);

    // Status Indicator Dot at entry of bay
    final statusPos = _iso(x1 + 8, (y1 + y2) * 0.5, 0, origin);
    final statusGlow = Paint()
      ..color = isOccupied
          ? const Color(0xFFEF4444).withValues(alpha: 0.4)
          : const Color(0xFF10B981).withValues(alpha: 0.4);
    canvas.drawCircle(statusPos, 6, statusGlow);

    final statusDot = Paint()
      ..color = isOccupied ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    canvas.drawCircle(statusPos, 3, statusDot);
  }

  // Draw Static Already Parked Car in Bay 02
  void _drawStaticParkedVehicle(Canvas canvas, Offset origin, {required double x, required double y}) {
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.5);
    final s1 = _iso(x - 22, y - 12, 0, origin);
    final s2 = _iso(x + 22, y - 12, 0, origin);
    final s3 = _iso(x + 22, y + 12, 0, origin);
    final s4 = _iso(x - 22, y + 12, 0, origin);
    final shadowPath = Path()..moveTo(s1.dx, s1.dy)..lineTo(s2.dx, s2.dy)..lineTo(s3.dx, s3.dy)..lineTo(s4.dx, s4.dy)..close();
    canvas.drawPath(shadowPath, shadowPaint);

    // Chassis (3D extrusion)
    final chassisPaint = Paint()..color = const Color(0xFF334155);
    final c1 = _iso(x - 20, y - 10, 4, origin);
    final c2 = _iso(x + 20, y - 10, 4, origin);
    final c3 = _iso(x + 20, y + 10, 4, origin);
    final c4 = _iso(x - 20, y + 10, 4, origin);
    final bodyPath = Path()..moveTo(c1.dx, c1.dy)..lineTo(c2.dx, c2.dy)..lineTo(c3.dx, c3.dy)..lineTo(c4.dx, c4.dy)..close();
    canvas.drawPath(bodyPath, chassisPaint);

    // Roof
    final roofPaint = Paint()..color = const Color(0xFF1E293B);
    final r1 = _iso(x - 10, y - 7, 10, origin);
    final r2 = _iso(x + 10, y - 7, 10, origin);
    final r3 = _iso(x + 10, y + 7, 10, origin);
    final r4 = _iso(x - 10, y + 7, 10, origin);
    final roofPath = Path()..moveTo(r1.dx, r1.dy)..lineTo(r2.dx, r2.dy)..lineTo(r3.dx, r3.dy)..lineTo(r4.dx, r4.dy)..close();
    canvas.drawPath(roofPath, roofPaint);
  }

  // Draw Smart Barrier Gate
  void _drawAccessBarrier(Canvas canvas, Offset origin, {required double gateX, required double gateY, required double progress}) {
    // Gate post
    final postBase = _iso(gateX, gateY, 0, origin);
    final postTop = _iso(gateX, gateY, 18, origin);
    final postPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(postBase, postTop, postPaint);

    // Barrier angle: 0 (closed) to -60 deg (open) after progress >= 0.25
    double barrierAngle = 0.0;
    if (progress >= 0.22 && progress < 0.70) {
      final t = ((progress - 0.22) / 0.12).clamp(0.0, 1.0);
      barrierAngle = -0.9 * t; // opens upward
    } else if (progress >= 0.70) {
      final t = ((progress - 0.70) / 0.12).clamp(0.0, 1.0);
      barrierAngle = -0.9 * (1.0 - t); // slowly closes behind
    }

    final isOpen = progress >= 0.28 && progress < 0.75;
    final armEnd = Offset(
      postTop.dx + 28 * math.cos(barrierAngle + 0.3),
      postTop.dy + 28 * math.sin(barrierAngle + 0.3),
    );

    final armPaint = Paint()
      ..color = isOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(postTop, armEnd, armPaint);

    // LED status light on top of post
    final ledPaint = Paint()
      ..color = isOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    canvas.drawCircle(postTop, 3.5, ledPaint);
  }

  // Draw Animated Dashed Trajectory Curve
  void _drawTrajectoryGuide(Canvas canvas, Offset origin, {required double progress}) {
    if (progress > 0.85) return;
    final trajPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final waypoints = [
      _iso(-110, -35, 0, origin),
      _iso(-50, 15, 0, origin),
      _iso(20, 35, 0, origin),
      _iso(65, 52, 0, origin),
    ];

    final path = Path()..moveTo(waypoints[0].dx, waypoints[0].dy);
    for (int i = 1; i < waypoints.length; i++) {
      path.lineTo(waypoints[i].dx, waypoints[i].dy);
    }
    canvas.drawPath(path, trajPaint);
  }

  // Draw Sleek Moving Luxury Sports Sedan
  void _drawLuxuryVehicle({
    required Canvas canvas,
    required Offset origin,
    required double x,
    required double y,
    required double heading,
    required bool isDocked,
    required double progress,
  }) {
    // 1. Shadow Under Vehicle
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final s1 = _iso(x - 24, y - 13, 0, origin);
    final s2 = _iso(x + 24, y - 13, 0, origin);
    final s3 = _iso(x + 24, y + 13, 0, origin);
    final s4 = _iso(x - 24, y + 13, 0, origin);
    final sPath = Path()..moveTo(s1.dx, s1.dy)..lineTo(s2.dx, s2.dy)..lineTo(s3.dx, s3.dy)..lineTo(s4.dx, s4.dy)..close();
    canvas.drawPath(sPath, shadowPaint);

    // 2. Metallic Blue Chassis Base (Height 4)
    final chassisColor = isDocked ? const Color(0xFF2563EB) : const Color(0xFF0284C7);
    final chassisPaint = Paint()..color = chassisColor;
    final c1 = _iso(x - 22, y - 11, 4, origin);
    final c2 = _iso(x + 22, y - 11, 4, origin);
    final c3 = _iso(x + 22, y + 11, 4, origin);
    final c4 = _iso(x - 22, y + 11, 4, origin);
    final cPath = Path()..moveTo(c1.dx, c1.dy)..lineTo(c2.dx, c2.dy)..lineTo(c3.dx, c3.dy)..lineTo(c4.dx, c4.dy)..close();
    canvas.drawPath(cPath, chassisPaint);

    // 3. Cabin & Tinted Glass Roof (Height 11)
    final roofPaint = Paint()..color = const Color(0xFF0B1120);
    final r1 = _iso(x - 11, y - 8, 11, origin);
    final r2 = _iso(x + 11, y - 8, 11, origin);
    final r3 = _iso(x + 11, y + 8, 11, origin);
    final r4 = _iso(x - 11, y + 8, 11, origin);
    final rPath = Path()..moveTo(r1.dx, r1.dy)..lineTo(r2.dx, r2.dy)..lineTo(r3.dx, r3.dy)..lineTo(r4.dx, r4.dy)..close();
    canvas.drawPath(rPath, roofPaint);

    // Tinted Glass Highlight
    final glassHighlight = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(rPath, glassHighlight);

    // 4. Front LED Headlight Beam Cones
    final h1 = _iso(x + 22, y - 7, 4, origin);
    final h2 = _iso(x + 22, y + 7, 4, origin);

    final beamEnd1 = _iso(x + 65, y - 22, 0, origin);
    final beamEnd2 = _iso(x + 65, y + 22, 0, origin);

    final beamPath = Path()
      ..moveTo(h1.dx, h1.dy)
      ..lineTo(beamEnd1.dx, beamEnd1.dy)
      ..lineTo(beamEnd2.dx, beamEnd2.dy)
      ..lineTo(h2.dx, h2.dy)
      ..close();

    final beamPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFE0F2FE).withValues(alpha: 0.5),
          Colors.transparent,
        ],
      ).createShader(Rect.fromPoints(h1, beamEnd1));
    canvas.drawPath(beamPath, beamPaint);

    // Headlight bulbs
    final bulbPaint = Paint()..color = Colors.white;
    canvas.drawCircle(h1, 2.5, bulbPaint);
    canvas.drawCircle(h2, 2.5, bulbPaint);

    // 5. Tail Lights (Glowing Crimson)
    final t1 = _iso(x - 22, y - 7, 4, origin);
    final t2 = _iso(x - 22, y + 7, 4, origin);
    final tailPaint = Paint()
      ..color = isDocked ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    canvas.drawCircle(t1, 2.2, tailPaint);
    canvas.drawCircle(t2, 2.2, tailPaint);
  }

  // Draw Ultrasonic LiDAR Waves when reversing into bay
  void _drawLiDARWaves(Canvas canvas, Offset origin, {required double carX, required double carY, required double progress}) {
    final waveCenter = _iso(carX + 22, carY, 3, origin);
    final pulse = (progress * 14) % 1.0;

    for (int i = 1; i <= 3; i++) {
      final radius = (i * 12.0) + (pulse * 8.0);
      final alpha = (1.0 - (radius / 40.0)).clamp(0.0, 1.0);
      final wavePaint = Paint()
        ..color = const Color(0xFF10B981).withValues(alpha: alpha * 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(waveCenter, radius, wavePaint);
    }
  }

  // Draw Confirmed Checkmark Badge when Docked
  void _drawDockedBadge(Canvas canvas, Offset origin, {required double x, required double y, required double progress}) {
    final badgePos = _iso(x, y, 24, origin);
    final badgeGlow = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.35);
    canvas.drawCircle(badgePos, 14, badgeGlow);

    final badgeBg = Paint()..color = const Color(0xFF10B981);
    canvas.drawCircle(badgePos, 10, badgeBg);

    // Checkmark icon path
    final checkPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final checkPath = Path()
      ..moveTo(badgePos.dx - 4, badgePos.dy)
      ..lineTo(badgePos.dx - 1, badgePos.dy + 3)
      ..lineTo(badgePos.dx + 4, badgePos.dy - 3);
    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _IsometricSimulationPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.tiltX != tiltX ||
        oldDelegate.tiltY != tiltY;
  }
}
