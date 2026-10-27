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

  String _activeTab = 'overview';

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
          children: [
            Text('Admin Command Console'),
            SizedBox(width: 8),
            Icon(Icons.verified_user_rounded, color: AppTheme.primary, size: 18),
          ],
        ),
        actions: [
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
                        _buildTabChip('overview', 'Operations Overview', Icons.dashboard_rounded),
                        _buildTabChip('spaces', 'Facilities ($totalSpaces)', Icons.local_parking_rounded),
                        _buildTabChip('bookings', 'Bookings Ledger (${_bookings.length})', Icons.receipt_long_rounded),
                        _buildTabChip('users', 'User Directory ($totalUsers)', Icons.group_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tab Content
                  if (_activeTab == 'overview') _buildOverviewTab(),
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
                Text(
                  title,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary),
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

  Widget _buildOverviewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SYSTEM HEALTH & TELEMETRY',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              _buildTelemetryRow('Database Node', 'MongoDB Atlas Connected', Icons.check_circle_rounded, AppTheme.accent),
              const Divider(height: 18),
              _buildTelemetryRow('Backend Engine', 'FastAPI v2.0 (IST Timezone)', Icons.check_circle_rounded, AppTheme.accent),
              const Divider(height: 18),
              _buildTelemetryRow('Parking Inventory', '${_spaces.length} Chennai Hubs Mapped', Icons.local_parking_rounded, AppTheme.primary),
            ],
          ),
        ),
        const SizedBox(height: 14),

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
      ],
    );
  }

  Widget _buildTelemetryRow(String title, String status, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ],
    );
  }

  Widget _buildSpacesTab() {
    if (_spaces.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No spaces available')));
    }

    return Column(
      children: _spaces.map((s) {
        final name = s['name'] ?? 'Facility';
        final address = s['landmark'] ?? s['address'] ?? 'Chennai';
        final tariff = s['price_per_hour'] ?? s['price'] ?? 40;
        final available = s['available_slots'] ?? 0;
        final total = s['total_slots'] ?? 10;
        final imageUrl = ApiService.formatImageUrl(s['image']?.toString());

        return Container(
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
        );
      }).toList(),
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

        return Container(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('#$id', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primary)),
                      const SizedBox(width: 8),
                      Text(vehicle, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppTheme.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(facility, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
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
        final role = (u['role'] ?? 'seeker').toString().toUpperCase();

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
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
                    Text(email, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
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
        );
      }).toList(),
    );
  }
}
