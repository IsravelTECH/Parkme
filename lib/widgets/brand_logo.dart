import 'package:flutter/material.dart';

/// Luxury brand Parking 'P' badge with smart telemetry beacon
class ParkMeLogoBadge extends StatelessWidget {
  final double size;

  const ParkMeLogoBadge({
    super.key,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    final double radius = size * 0.28;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2563EB), // Cobalt Blue
            Color(0xFF1D4ED8), // Deep Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.32),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Crisp Rounded Parking 'P' Emblem
          Icon(
            Icons.local_parking_rounded,
            color: Colors.white,
            size: size * 0.62,
          ),

          // Smart Telemetry Beacon (Emerald Dot in top-right)
          Positioned(
            top: size * 0.10,
            right: size * 0.10,
            child: Container(
              width: size * 0.22,
              height: size * 0.22,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.8),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
