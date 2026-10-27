import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class Parking3DViewport extends StatefulWidget {
  final VoidCallback? onReserveTap;

  const Parking3DViewport({
    super.key,
    this.onReserveTap,
  });

  @override
  State<Parking3DViewport> createState() => _Parking3DViewportState();
}

class _Parking3DViewportState extends State<Parking3DViewport>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      height: 290,
      decoration: BoxDecoration(
        color: const Color(0xFF0B1120),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _tiltX = (_tiltX + details.delta.dy * 0.005).clamp(-0.25, 0.25);
              _tiltY = (_tiltY - details.delta.dx * 0.005).clamp(-0.35, 0.35);
            });
          },
          onPanEnd: (_) {
            setState(() {
              _tiltX = 0.0;
              _tiltY = 0.0;
            });
          },
          child: Stack(
            children: [
              // 1. Ambient Background Grid
              Positioned.fill(
                child: CustomPaint(
                  painter: _GridBackgroundPainter(),
                ),
              ),

              // 2. 3D Isometric Animated Parking Stage
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0012) // Perspective
                        ..rotateX(0.72 + _tiltX) // Isometric tilt
                        ..rotateZ(-0.48 + _tiltY), // Isometric rotation
                      child: CustomPaint(
                        painter: _ParkingScenePainter(
                          progress: _animController.value,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 3. Top Floating HUD Bar
              Positioned(
                top: 14,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '3D SMART RADAR',
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const Text(
                            ' • BAY 02',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app_rounded, size: 12, color: AppTheme.primary),
                          SizedBox(width: 4),
                          Text(
                            'Touch to Tilt 3D',
                            style: TextStyle(fontSize: 9, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Bottom Action & Telemetry HUD Card
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text(
                                    'AUTOPARK DOCKED',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'LiDAR: 0.2m • Precision: 99.8%',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: widget.onReserveTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Reserve Bay',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                            ),
                            SizedBox(width: 3),
                            Icon(Icons.arrow_forward_rounded, size: 11),
                          ],
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
    );
  }
}

// Background subtle grid lines
class _GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    const step = 22.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 3D Isometric Parking Scene Painter
class _ParkingScenePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  _ParkingScenePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);

    // 1. Draw Asphalt Parking Lot Base
    final floorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 280, height: 210),
      const Radius.circular(16),
    );
    final floorPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRRect(floorRect, floorPaint);

    final floorBorderPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(floorRect, floorBorderPaint);

    // 2. Draw 4 Parking Bays (Bay 01, 02, 03, 04)
    const bayWidth = 52.0;
    const bayHeight = 84.0;
    const startX = -115.0;
    const bayY = -35.0;

    for (int i = 0; i < 4; i++) {
      final x = center.dx + startX + (i * 60.0);
      final y = center.dy + bayY;
      final bayRect = Rect.fromLTWH(x, y, bayWidth, bayHeight);

      final isTargetBay = (i == 1); // Bay 02 is open target
      final isOccupied = (i == 0 || i == 2);

      // Bay Floor
      final bayBgPaint = Paint()
        ..color = isTargetBay
            ? const Color(0xFF10B981).withValues(alpha: 0.12)
            : const Color(0xFF1E293B).withValues(alpha: 0.5);
      canvas.drawRRect(RRect.fromRectAndRadius(bayRect, const Radius.circular(8)), bayBgPaint);

      // Bay Lines (Neon)
      final linePaint = Paint()
        ..color = isTargetBay ? const Color(0xFF10B981) : const Color(0xFF64748B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isTargetBay ? 2.5 : 1.5;
      canvas.drawRRect(RRect.fromRectAndRadius(bayRect, const Radius.circular(8)), linePaint);

      // Overhead Sensor Indicator LED
      final ledColor = isTargetBay ? const Color(0xFF10B981) : const Color(0xFFEF4444);
      final ledPaint = Paint()..color = ledColor;
      canvas.drawCircle(Offset(x + bayWidth * 0.5, y + 8), 3.5, ledPaint);

      // Draw Occupied Cars in bays 01 and 03
      if (isOccupied) {
        _drawStaticCar(canvas, Offset(x + bayWidth * 0.5, y + bayHeight * 0.52), i == 0 ? Colors.blueGrey : Colors.blueGrey.shade800);
      }

      // Draw Pulsing Target Radar in Bay 02
      if (isTargetBay && progress < 0.85) {
        final pulseRadius = 12.0 + (progress % 0.3) * 35.0;
        final pulsePaint = Paint()
          ..color = const Color(0xFF10B981).withValues(alpha: (1.0 - (progress % 0.3) / 0.3) * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(Offset(x + bayWidth * 0.5, y + bayHeight * 0.5), pulseRadius, pulsePaint);
      }
    }

    // 3. Draw Access Lane Markings
    final laneY = center.dy + 65.0;
    final dashPaint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 2.0;
    for (double dx = center.dx - 120; dx < center.dx + 120; dx += 20) {
      canvas.drawLine(Offset(dx, laneY), Offset(dx + 10, laneY), dashPaint);
    }

    // 4. Compute Animated EV Vehicle Trajectory
    // Phase 1 (0.0 to 0.45): Driving along lane (X: -120 to -55, Y: laneY)
    // Phase 2 (0.45 to 0.70): Turning towards Bay 02
    // Phase 3 (0.70 to 1.0): Reversing into Bay 02 (X: -55, Y: bayY + 45)
    final targetX = center.dx + startX + 60.0 + bayWidth * 0.5; // X of Bay 02
    final targetY = center.dy + bayY + bayHeight * 0.52; // Y inside Bay 02

    double carX;
    double carY;
    double carAngle = 0.0;

    if (progress < 0.45) {
      final t = progress / 0.45;
      carX = (center.dx - 130) + t * (targetX - (center.dx - 130));
      carY = laneY;
      carAngle = 0.0;
    } else if (progress < 0.70) {
      final t = (progress - 0.45) / 0.25;
      carX = targetX + math.sin(t * math.pi * 0.5) * 12.0;
      carY = laneY - t * (laneY - targetY) * 0.4;
      carAngle = -t * (math.pi * 0.5); // rotate to -90 deg
    } else {
      final t = (progress - 0.70) / 0.30;
      carX = targetX;
      final startReverseY = laneY - (laneY - targetY) * 0.4;
      carY = startReverseY - t * (startReverseY - targetY);
      carAngle = -math.pi * 0.5;
    }

    _drawAutonomousCar(canvas, Offset(carX, carY), carAngle, progress >= 0.9);
  }

  void _drawStaticCar(Canvas canvas, Offset pos, Color color) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);

    final carRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 34, height: 60),
      const Radius.circular(8),
    );
    canvas.drawRRect(carRect, Paint()..color = color);

    // Windshield
    final glassRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, -6), width: 24, height: 18),
      const Radius.circular(4),
    );
    canvas.drawRRect(glassRect, Paint()..color = const Color(0xFF090D16));

    // Tail lights (red)
    final lightPaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawCircle(const Offset(-10, -26), 2, lightPaint);
    canvas.drawCircle(const Offset(10, -26), 2, lightPaint);

    canvas.restore();
  }

  void _drawAutonomousCar(Canvas canvas, Offset pos, double angle, bool isDocked) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);

    // Dynamic Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(3, 4), width: 36, height: 64),
        const Radius.circular(10),
      ),
      shadowPaint,
    );

    // Main Cobalt Car Body
    final bodyPaint = Paint()..color = AppTheme.primary;
    final carRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 34, height: 62),
      const Radius.circular(10),
    );
    canvas.drawRRect(carRect, bodyPaint);

    final bodyBorder = Paint()
      ..color = const Color(0xFF93C5FD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(carRect, bodyBorder);

    // Panoramic Windshield
    final glassPaint = Paint()..color = const Color(0xFF090D16);
    final glassRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, -6), width: 26, height: 20),
      const Radius.circular(6),
    );
    canvas.drawRRect(glassRect, glassPaint);

    // Headlight Beams (Front)
    final headLightPaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(-10, 26), 2.5, headLightPaint);
    canvas.drawCircle(const Offset(10, 26), 2.5, headLightPaint);

    // Rear Taillights (Red LED)
    final tailPaint = Paint()..color = isDocked ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    canvas.drawCircle(const Offset(-10, -28), 2.5, tailPaint);
    canvas.drawCircle(const Offset(10, -28), 2.5, tailPaint);

    // Roof LiDAR Sensor Node
    final lidarPaint = Paint()..color = isDocked ? const Color(0xFF10B981) : AppTheme.accent;
    canvas.drawCircle(const Offset(0, -5), 3.5, lidarPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ParkingScenePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
