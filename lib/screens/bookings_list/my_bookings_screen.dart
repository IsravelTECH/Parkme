import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/booking.dart';
import '../../services/api_service.dart';
import '../booking/digital_pass_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  bool _isLoading = true;
  List<Booking> _activeBookings = [];
  List<Booking> _history = [];
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getUserDashboard();
      final activeList = (data['active_booking'] as List<dynamic>?)
              ?.map((item) => Booking.fromDashboardJson(item))
              .toList() ??
          [];
      final historyList = (data['history'] as List<dynamic>?)
              ?.map((item) => Booking.fromDashboardJson(item))
              .toList() ??
          [];

      setState(() {
        _summary = data['summary'] ?? {};
        _activeBookings = activeList;
        _history = historyList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Cancel Reservation?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('The slot will be released back to the parking lot.', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Booking', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Slot'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.cancelBooking(bookingId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation cancelled successfully')),
        );
        _fetchDashboard();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Reservations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchDashboard,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _fetchDashboard,
              color: AppTheme.primary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // KPI Metric Strip
                  Row(
                    children: [
                      _buildKpiCard('Total Bookings', '${_summary['total_bookings'] ?? 0}'),
                      const SizedBox(width: 8),
                      _buildKpiCard('Active Passes', '${_activeBookings.length}', color: AppTheme.primary),
                      const SizedBox(width: 8),
                      _buildKpiCard('Total Spent', '₹${_summary['total_spent'] ?? 0}', color: AppTheme.accent),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Active Passes Header
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ACTIVE PASSES',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_activeBookings.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.confirmation_number_outlined, size: 40, color: AppTheme.textMuted),
                          SizedBox(height: 8),
                          Text(
                            'No Active Parking Passes',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Search the map to reserve guaranteed spots',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._activeBookings.map((b) => _buildActivePassCard(b)),

                  const SizedBox(height: 28),

                  // History Header
                  const Text(
                    'PAST RESERVATIONS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.textSecondary, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 12),

                  if (_history.isEmpty)
                    const Text('No previous reservations found.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13))
                  else
                    ..._history.map((h) => _buildHistoryCard(h)),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiCard(String title, String value, {Color color = Colors.white}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePassCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.5)),
                ),
                child: const Text('ACTIVE PASS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.accent)),
              ),
              IconButton(
                icon: const Icon(Icons.cancel_outlined, color: AppTheme.danger, size: 20),
                onPressed: () => _cancelBooking(booking.id),
                tooltip: 'Cancel Reservation',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(booking.parkingName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 2),
          Text(booking.address, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PLATE NUMBER', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
                    Text(booking.vehicleNumber, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'monospace')),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('WINDOW', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
                    Text(booking.timeRange, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DigitalPassScreen(booking: booking)),
              );
            },
            icon: const Icon(Icons.qr_code_rounded, size: 18),
            label: const Text('View Boarding Pass & QR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Booking h) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.parkingName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white)),
                const SizedBox(height: 2),
                Text('${h.vehicleNumber} • ${h.timeRange}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${h.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: h.isCancelled ? AppTheme.danger.withOpacity(0.2) : AppTheme.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  h.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: h.isCancelled ? AppTheme.danger : AppTheme.accent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
