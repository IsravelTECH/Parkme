import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/storage.dart';
import '../../models/user.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserSession? _user;
  final _vehicleController = TextEditingController();
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await StorageService.getUser();
    final vehicle = await StorageService.getLastVehicle();
    if (mounted) {
      setState(() {
        _user = user;
        _vehicleController.text = vehicle;
      });
    }
  }

  Future<void> _saveSettings() async {
    await StorageService.saveLastVehicle(_vehicleController.text.trim());
    if (mounted) {
      setState(() => _isSaved = true);
    }
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isSaved = false);
  }

  Future<void> _handleLogout() async {
    await StorageService.clearUser();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _vehicleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Driver Profile & Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(
                        (_user?.name ?? 'D').isNotEmpty ? (_user?.name ?? 'D')[0].toUpperCase() : 'D',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user?.name ?? 'Driver Account',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            (_user?.role ?? 'seeker').toUpperCase(),
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Vehicle Plate Number Preference
            const Text(
              'PRIMARY VEHICLE PLATE',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _vehicleController,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.directions_car_rounded, color: AppTheme.textMuted, size: 20),
                hintText: 'e.g. TN 09 AB 1234',
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _saveSettings,
              child: Text(
                _isSaved ? 'Plate Saved Successfully!' : 'Save Vehicle Plate',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 32),

            // Sign Out
            OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout_rounded, color: AppTheme.danger, size: 18),
              label: const Text('Sign Out of Account', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: BorderSide(color: AppTheme.danger.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
