import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';
import '../host/add_space_screen.dart';

class AdminConsoleScreen extends StatefulWidget {
  const AdminConsoleScreen({super.key});

  @override
  State<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends State<AdminConsoleScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _stats;
  List<dynamic> _spaces = [];
  List<dynamic> _bookings = [];
  List<dynamic> _users = [];

  String _activeTab = 'spaces';

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getAdminDashboardStats().catchError((_) => <String, dynamic>{}),
        ApiService.getAdminSpaces().catchError((_) => <dynamic>[]),
        ApiService.getAdminBookings().catchError((_) => <dynamic>[]),
        ApiService.getAdminUsers().catchError((_) => <dynamic>[]),
      ]);

      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _spaces = results[1] as List<dynamic>;
        _bookings = results[2] as List<dynamic>;
        _users = results[3] as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // =========================================================================
  // 🔍 GLOBAL SEARCH DIALOG / SHEET
  // =========================================================================
  void _openGlobalSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GlobalSearchSheet(
        spaces: _spaces,
        bookings: _bookings,
        users: _users,
        onSelectSpace: (s) {
          Navigator.pop(ctx);
          _showSpacePreview(s);
        },
        onSelectBooking: (b) {
          Navigator.pop(ctx);
          _showBookingPreview(b);
        },
        onSelectUser: (u) {
          Navigator.pop(ctx);
          _showUserPreview(u);
        },
      ),
    );
  }

  // =========================================================================
  // 🏢 FACILITY PREVIEW BOTTOM SHEET
  // =========================================================================
  void _showSpacePreview(Map<String, dynamic> s) {
    final name = s['name'] ?? 'Parking Hub';
    final address = s['address'] ?? s['landmark'] ?? 'Chennai';
    final tariff = s['price_per_hour'] ?? s['price'] ?? 40;
    final available = s['available_slots'] ?? 0;
    final total = s['total_slots'] ?? 10;
    final imageUrl = ApiService.formatImageUrl(s['image']?.toString());
    final features = (s['features'] as List?)?.map((e) => e.toString()).toList() ?? ['CCTV', 'Covered Parking', '24/7 Guard'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 140,
                  color: AppTheme.surfaceLight,
                  child: const Icon(Icons.local_parking_rounded, size: 48, color: AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '₹$tariff/hr',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Slot Metrics
            Row(
              children: [
                _buildMetricBox('Total Slots', '$total', Colors.blue),
                const SizedBox(width: 8),
                _buildMetricBox('Available', '$available', Colors.green),
                const SizedBox(width: 8),
                _buildMetricBox('Occupied', '${total - available}', Colors.orange),
              ],
            ),
            const SizedBox(height: 16),

            // Amenities
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: features.map((f) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  f,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => AddSpaceScreen(spaceToEdit: s)),
                );
                if (updated == true) _fetchAdminData();
              },
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Edit Facility Specifications', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 🧾 DIGITAL BILL / INVOICE PREVIEW BOTTOM SHEET
  // =========================================================================
  void _showBookingPreview(Map<String, dynamic> b) {
    final id = b['_id']?.toString().substring(0, 6).toUpperCase() ?? 'PASS';
    final facility = b['parking_name'] ?? 'Chennai Parking Hub';
    final vehicle = b['vehicle_number'] ?? 'TN 09 AB 1234';
    final price = b['total_price'] ?? 40;
    final status = b['status'] ?? 'active';
    final date = b['booking_date'] ?? 'Today';
    final start = b['start_time'] ?? '09:00';
    final end = b['end_time'] ?? '12:00';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.receipt_long_rounded, size: 36, color: AppTheme.primary),
                  const SizedBox(height: 6),
                  const Text('DIGITAL PARKING INVOICE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                  Text('BILL #$id', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildInvoiceRow('Parking Facility', facility),
            _buildInvoiceRow('Vehicle Plate', vehicle, isMono: true),
            _buildInvoiceRow('Slot Date', date),
            _buildInvoiceRow('Time Interval', '$start — $end'),
            _buildInvoiceRow('Payment Verification', 'UPI / Card Verified'),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Settlement', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                Text('₹$price', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.accent)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: status == 'active' ? AppTheme.accent.withValues(alpha: 0.12) : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.qr_code_2_rounded, size: 24, color: status == 'active' ? AppTheme.accent : AppTheme.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Digital Gate Pass (${status.toUpperCase()})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                        const Text('Valid for automated barrier check-in & check-out.', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close Invoice View'),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 👥 USER DOSSIER PREVIEW BOTTOM SHEET
  // =========================================================================
  void _showUserPreview(Map<String, dynamic> u) {
    final name = u['name'] ?? 'Driver';
    final email = u['email'] ?? 'driver@parkme.in';
    final phone = u['phone'] ?? '+91 98400 12345';
    final role = (u['role'] ?? 'seeker').toString().toUpperCase();
    final enrolled = u['created_at'] ?? 'Oct 24, 2026';
    final totalBookings = u['total_bookings'] ?? 1;
    final totalSpent = u['total_spent'] ?? 120;
    final vehicle = u['recent_vehicle'] ?? u['vehicle_number'] ?? 'TN 09 AB 1234';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.primary,
                  child: Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: role == 'OWNER' || role == 'ADMIN' ? AppTheme.warning.withValues(alpha: 0.15) : AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(role, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                          ),
                        ],
                      ),
                      Text(email, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInvoiceRow('Contact Phone', phone),
            _buildInvoiceRow('Enrolled Date', enrolled),
            _buildInvoiceRow('Primary Vehicle', vehicle, isMono: true),
            _buildInvoiceRow('Completed Trips', '$totalBookings Reservations'),
            _buildInvoiceRow('Total Spend', '₹$totalSpent'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close Dossier'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(String title, String val, {bool isMono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Text(
            val,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: isMono ? 'monospace' : null,
              color: isMono ? AppTheme.primary : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final revenue = (_stats?['total_earnings'] ?? _stats?['total_revenue'] ?? 0).toDouble();
    final activeBookings = _stats?['active_bookings'] ?? _bookings.where((b) => b['status'] == 'active').length;
    final totalSpaces = _spaces.isNotEmpty ? _spaces.length : (_stats?['total_spaces'] ?? 30);
    final totalUsers = _users.isNotEmpty ? _users.length : (_stats?['total_users'] ?? 0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                'Admin Console',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.verified_user_rounded, color: AppTheme.primary, size: 18),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search System',
            onPressed: _openGlobalSearch,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Telemetry',
            onPressed: _fetchAdminData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _fetchAdminData,
              color: AppTheme.primary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppTheme.danger, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),

                  // Header Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.wifi_tethering_rounded, color: AppTheme.primary, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'CHENNAI METRO RADAR & SETTLEMENT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // KPI Grid
                  Row(
                    children: [
                      _buildKpiCard('Total Revenue', '₹${revenue.toStringAsFixed(0)}', Icons.payments_rounded, AppTheme.accent),
                      const SizedBox(width: 10),
                      _buildKpiCard('Active Parked', '$activeBookings', Icons.directions_car_rounded, AppTheme.primary),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildKpiCard('Parking Hubs', '$totalSpaces', Icons.business_rounded, AppTheme.warning),
                      const SizedBox(width: 10),
                      _buildKpiCard('Registered Users', '$totalUsers', Icons.people_alt_rounded, const Color(0xFF8B5CF6)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Segmented Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTabChip('spaces', 'Facilities ($totalSpaces)', Icons.local_parking_rounded),
                        _buildTabChip('bookings', 'Bookings Ledger (${_bookings.length})', Icons.receipt_long_rounded),
                        _buildTabChip('users', 'User Directory ($totalUsers)', Icons.group_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tab Content
                  if (_activeTab == 'spaces') _buildSpacesTab(),
                  if (_activeTab == 'bookings') _buildBookingsTab(),
                  if (_activeTab == 'users') _buildUsersTab(),
                ],
              ),
            ),
    );
  }

  Widget _buildTabChip(String id, String title, IconData icon) {
    final isSelected = _activeTab == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.white : AppTheme.textSecondary,
        ),
        label: Text(title),
        selected: isSelected,
        onSelected: (_) => setState(() => _activeTab = id),
        backgroundColor: Colors.white,
        selectedColor: AppTheme.primary,
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.border,
          width: isSelected ? 1.5 : 1.0,
        ),
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isSelected ? Colors.white : AppTheme.textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpacesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () async {
            final added = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const AddSpaceScreen()),
            );
            if (added == true) _fetchAdminData();
          },
          icon: const Icon(Icons.add_business_rounded),
          label: const Text('List New Facility to Network', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 14),
        if (_spaces.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No spaces available')))
        else
          ..._spaces.map((s) {
            final name = s['name'] ?? 'Facility';
            final address = s['landmark'] ?? s['address'] ?? 'Chennai';
            final tariff = s['price_per_hour'] ?? s['price'] ?? 40;
            final available = s['available_slots'] ?? 0;
            final total = s['total_slots'] ?? 10;
            final imageUrl = ApiService.formatImageUrl(s['image']?.toString());

            return InkWell(
              onTap: () => _showSpacePreview(s),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 56,
                          height: 56,
                          color: AppTheme.surfaceLight,
                          child: const Icon(Icons.local_parking_rounded, color: AppTheme.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textPrimary)),
                          const SizedBox(height: 2),
                          Text(address, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text('$available / $total Free • ₹$tariff/hr', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 20),
                      tooltip: 'Edit Facility',
                      onPressed: () async {
                        final updated = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(builder: (_) => AddSpaceScreen(spaceToEdit: s)),
                        );
                        if (updated == true) _fetchAdminData();
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildBookingsTab() {
    if (_bookings.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No bookings recorded yet')));
    }

    return Column(
      children: _bookings.map((b) {
        final id = b['_id']?.toString().substring(0, 6).toUpperCase() ?? '';
        final facility = b['parking_name'] ?? 'Parking Spot';
        final vehicle = b['vehicle_number'] ?? 'TN 09 AB 1234';
        final price = b['total_price'] ?? 40;
        final status = b['status'] ?? 'active';

        return InkWell(
          onTap: () => _showBookingPreview(b),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
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
                      Row(
                        children: [
                          Text('#$id', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primary)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              vehicle,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppTheme.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        facility,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹$price', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.textPrimary)),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: status == 'active' ? AppTheme.accent.withValues(alpha: 0.12) : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: status == 'active' ? AppTheme.accent : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUsersTab() {
    if (_users.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No users recorded')));
    }

    return Column(
      children: _users.map((u) {
        final name = u['name'] ?? 'Driver';
        final email = u['email'] ?? 'driver@parkme.in';
        final phone = u['phone'] ?? '+91 98400 12345';
        final role = (u['role'] ?? 'seeker').toString().toUpperCase();
        final enrolled = u['created_at'] ?? 'Oct 24, 2026';
        final bookingsCount = u['total_bookings'] ?? 1;
        final totalSpend = u['total_spent'] ?? 120;

        return InkWell(
          onTap: () => _showUserPreview(u),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                      child: Text(name[0].toUpperCase(), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textPrimary)),
                          Text(email, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: role == 'OWNER' || role == 'ADMIN'
                            ? AppTheme.warning.withValues(alpha: 0.15)
                            : AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        role,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: role == 'OWNER' || role == 'ADMIN' ? AppTheme.warning : AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: AppTheme.border),
                const SizedBox(height: 8),
                // Enrolled Details Footer Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(enrolled, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.phone_rounded, size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(phone, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                      ],
                    ),
                    Text(
                      '$bookingsCount trips • ₹$totalSpend',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.accent),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// =========================================================================
// 🔍 GLOBAL SEARCH BOTTOM SHEET COMPONENT
// =========================================================================
class _GlobalSearchSheet extends StatefulWidget {
  final List<dynamic> spaces;
  final List<dynamic> bookings;
  final List<dynamic> users;
  final Function(Map<String, dynamic>) onSelectSpace;
  final Function(Map<String, dynamic>) onSelectBooking;
  final Function(Map<String, dynamic>) onSelectUser;

  const _GlobalSearchSheet({
    required this.spaces,
    required this.bookings,
    required this.users,
    required this.onSelectSpace,
    required this.onSelectBooking,
    required this.onSelectUser,
  });

  @override
  State<_GlobalSearchSheet> createState() => _GlobalSearchSheetState();
}

class _GlobalSearchSheetState extends State<_GlobalSearchSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase().trim();

    final matchedSpaces = q.isEmpty
        ? []
        : widget.spaces.where((s) {
            final name = (s['name'] ?? '').toString().toLowerCase();
            final address = (s['address'] ?? s['landmark'] ?? '').toString().toLowerCase();
            return name.contains(q) || address.contains(q);
          }).toList();

    final matchedBookings = q.isEmpty
        ? []
        : widget.bookings.where((b) {
            final id = (b['_id'] ?? '').toString().toLowerCase();
            final vehicle = (b['vehicle_number'] ?? '').toString().toLowerCase();
            final facility = (b['parking_name'] ?? '').toString().toLowerCase();
            final status = (b['status'] ?? '').toString().toLowerCase();
            return id.contains(q) || vehicle.contains(q) || facility.contains(q) || status.contains(q);
          }).toList();

    final matchedUsers = q.isEmpty
        ? []
        : widget.users.where((u) {
            final name = (u['name'] ?? '').toString().toLowerCase();
            final email = (u['email'] ?? '').toString().toLowerCase();
            final phone = (u['phone'] ?? '').toString().toLowerCase();
            return name.contains(q) || email.contains(q) || phone.contains(q);
          }).toList();

    final totalMatches = matchedSpaces.length + matchedBookings.length + matchedUsers.length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // Search Bar
          TextField(
            controller: _searchCtrl,
            autofocus: true,
            onChanged: (val) => setState(() => _query = val),
            decoration: InputDecoration(
              hintText: 'Search place, address, name, email, phone, bill #...',
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: AppTheme.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Results Scroll
          Expanded(
            child: _query.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.manage_search_rounded, size: 48, color: AppTheme.textSecondary),
                        SizedBox(height: 10),
                        Text(
                          'Omnipresent Search Engine',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Type any address, name, phone, or bill ID to filter instantly.',
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : totalMatches == 0
                    ? const Center(
                        child: Text(
                          'No matching records found.',
                          style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                        ),
                      )
                    : ListView(
                        children: [
                          if (matchedSpaces.isNotEmpty) ...[
                            _buildSectionHeader('Facilities Matched (${matchedSpaces.length})', Icons.business_rounded),
                            ...matchedSpaces.map((s) => ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.local_parking_rounded, color: AppTheme.primary),
                                  title: Text(s['name'] ?? 'Facility', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(s['address'] ?? 'Chennai', style: const TextStyle(fontSize: 11)),
                                  trailing: Text('₹${s['price_per_hour'] ?? 40}/hr', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                  onTap: () => widget.onSelectSpace(Map<String, dynamic>.from(s)),
                                )),
                            const SizedBox(height: 10),
                          ],
                          if (matchedBookings.isNotEmpty) ...[
                            _buildSectionHeader('Bills & Bookings (${matchedBookings.length})', Icons.receipt_long_rounded),
                            ...matchedBookings.map((b) => ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.receipt_rounded, color: AppTheme.accent),
                                  title: Text('#${(b['_id'] ?? '').toString().substring(0, 6).toUpperCase()} • ${b['vehicle_number'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(b['parking_name'] ?? 'Parking Hub', style: const TextStyle(fontSize: 11)),
                                  trailing: Text('₹${b['total_price'] ?? 40}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent)),
                                  onTap: () => widget.onSelectBooking(Map<String, dynamic>.from(b)),
                                )),
                            const SizedBox(height: 10),
                          ],
                          if (matchedUsers.isNotEmpty) ...[
                            _buildSectionHeader('Users & Drivers (${matchedUsers.length})', Icons.people_rounded),
                            ...matchedUsers.map((u) => ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                                    child: Text((u['name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                  ),
                                  title: Text(u['name'] ?? 'Driver', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${u['email'] ?? ''} • ${u['phone'] ?? '+91 98400 12345'}', style: const TextStyle(fontSize: 11)),
                                  trailing: Text((u['role'] ?? 'seeker').toString().toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                  onTap: () => widget.onSelectUser(Map<String, dynamic>.from(u)),
                                )),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}
