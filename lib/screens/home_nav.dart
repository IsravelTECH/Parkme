import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/parking_space.dart';
import 'home/home_screen.dart';
import 'explore/map_screen.dart';
import 'bookings_list/my_bookings_screen.dart';
import 'host/host_dashboard_screen.dart';
import 'profile/profile_screen.dart';

class HomeNav extends StatefulWidget {
  final int initialTabIndex;

  const HomeNav({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<HomeNav> createState() => _HomeNavState();
}

class _HomeNavState extends State<HomeNav> {
  late int _currentIndex;
  final GlobalKey<MapScreenState> _mapScreenKey = GlobalKey<MapScreenState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  void _navigateToTab(int index, {String? searchQuery, ParkingSpace? selectedSpace}) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 1) {
      // Explore Map tab
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (searchQuery != null && searchQuery.isNotEmpty) {
          _mapScreenKey.currentState?.setSearchQuery(searchQuery);
        }
        if (selectedSpace != null) {
          _mapScreenKey.currentState?.selectSpace(selectedSpace);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onNavigateTab: _navigateToTab),
      MapScreen(key: _mapScreenKey),
      const MyBookingsScreen(),
      const HostDashboardScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: AppTheme.border, width: 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.explore_rounded, 'Explore'),
                _buildNavItem(2, Icons.confirmation_number_rounded, 'Bookings'),
                _buildNavItem(3, Icons.add_business_rounded, 'Host'),
                _buildNavItem(4, Icons.person_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
