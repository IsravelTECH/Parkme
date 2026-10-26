import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/parking_space.dart';
import '../../services/api_service.dart';
import '../booking/booking_bottom_sheet.dart';

class SpaceDetailsSheet extends StatelessWidget {
  final ParkingSpace space;

  const SpaceDetailsSheet({super.key, required this.space});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Space Image & Status
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  ApiService.formatImageUrl(space.image),
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 140,
                    color: AppTheme.surfaceLight,
                    child: const Icon(Icons.local_parking_rounded, size: 48, color: AppTheme.textMuted),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: space.isAvailable ? AppTheme.accent : AppTheme.danger,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6),
                    ],
                  ),
                  child: Text(
                    space.isAvailable ? '🟢 ${space.availableSlots} SLOTS FREE' : '🔴 FULLY OCCUPIED',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.background.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '₹${space.pricePerHour.toStringAsFixed(0)}/hr',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Title & Landmark
          Text(
            space.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  space.landmark.isNotEmpty ? '${space.landmark}, ${space.city}' : space.address,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Feature Amenities
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (space.features.isNotEmpty ? space.features : ['Verified Parking', 'CCTV Guarded'])
                .map((f) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        f,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 18),

          // Reserve Spot Button
          ElevatedButton.icon(
            onPressed: space.isAvailable
                ? () {
                    Navigator.pop(context); // close details sheet
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => BookingBottomSheet(space: space),
                    );
                  }
                : null,
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            label: Text(
              space.isAvailable ? 'Reserve Bay Now (₹${space.pricePerHour.toStringAsFixed(0)}/hr)' : 'Fully Booked',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
