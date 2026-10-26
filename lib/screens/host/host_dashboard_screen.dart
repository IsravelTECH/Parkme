import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';
import 'add_space_screen.dart';

class HostDashboardScreen extends StatefulWidget {
  const HostDashboardScreen({super.key});

  @override
  State<HostDashboardScreen> createState() => _HostDashboardScreenState();
}

class _HostDashboardScreenState extends State<HostDashboardScreen> {
  bool _isLoading = true;
  int _totalParkings = 0;
  int _totalSlots = 0;
  int _activeBookings = 0;
  double _totalEarnings = 0;
  List<dynamic> _parkings = [];

  @override
  void initState() {
    super.initState();
    _fetchHostData();
  }

  Future<void> _fetchHostData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getHostDashboard();
      setState(() {
        _totalParkings = data['total_parkings'] ?? 0;
        _totalSlots = data['total_slots'] ?? 0;
        _activeBookings = data['active_bookings'] ?? 0;
        _totalEarnings = (data['total_earnings'] ?? 0).toDouble();
        _parkings = data['parkings'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSpace(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Parking Space?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('This will remove the listing from the ParkMe map.', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteParkingSpace(id);
        _fetchHostData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Host & Monetize'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchHostData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddSpaceScreen()),
          );
          if (added == true) _fetchHostData();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('List New Space', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _fetchHostData,
              color: AppTheme.primary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // KPI Grid
                  Row(
                    children: [
                      _buildKpiCard('Properties', '$_totalParkings', Icons.business_rounded),
                      const SizedBox(width: 8),
                      _buildKpiCard('Total Slots', '$_totalSlots', Icons.local_parking_rounded),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildKpiCard('Active Parked', '$_activeBookings', Icons.directions_car_rounded, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      _buildKpiCard('Total Revenue', '₹${_totalEarnings.toStringAsFixed(0)}', Icons.trending_up_rounded, color: AppTheme.accent),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'YOUR MANAGED PROPERTIES',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 12),

                  if (_parkings.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.add_business_rounded, size: 48, color: AppTheme.textMuted),
                          SizedBox(height: 12),
                          Text(
                            'No Properties Listed Yet',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Turn your unused driveway into monthly passive income',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._parkings.map((p) => _buildPropertyCard(p)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, {Color color = Colors.white}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                Icon(icon, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCard(dynamic p) {
    final id = p['id'] ?? p['parking_id'] ?? '';
    final name = p['name'] ?? 'Parking Facility';
    final address = p['address'] ?? p['city'] ?? 'Chennai';
    final price = p['price'] ?? 20;
    final totalSlots = p['total_slots'] ?? 10;
    final availableSlots = p['available_slots'] ?? 0;
    final earnings = p['earnings'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 20),
                onPressed: () => _deleteSpace(id),
              ),
            ],
          ),
          Text(address, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
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
                Text('$availableSlots / $totalSlots Slots Free', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.accent)),
                Text('₹$price/hr', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                Text('Earned: ₹$earnings', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
