import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme.dart';
import '../../models/parking_space.dart';
import '../../services/api_service.dart';
import 'space_details_sheet.dart';
import '../booking/booking_bottom_sheet.dart';

class MapScreen extends StatefulWidget {
  final String? initialSearchQuery;
  final ParkingSpace? initialSelectedSpace;

  const MapScreen({
    super.key,
    this.initialSearchQuery,
    this.initialSelectedSpace,
  });

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  List<ParkingSpace> _spaces = [];
  bool _isLoading = true;
  String _activeFilter = 'all';
  ParkingSpace? _selectedSpace;

  static const LatLng _chennaiCenter = LatLng(13.0827, 80.2707);

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!;
    }
    if (widget.initialSelectedSpace != null) {
      _selectedSpace = widget.initialSelectedSpace;
    }
    _fetchSpaces();
  }

  void setSearchQuery(String query) {
    _searchController.text = query;
    setState(() {});
  }

  void selectSpace(ParkingSpace space) {
    _onSelectSpace(space);
  }

  Future<void> _fetchSpaces() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiService.getParkingSpaces();
      setState(() {
        _spaces = list;
        _isLoading = false;
        if (list.isNotEmpty && _selectedSpace == null) {
          _selectedSpace = list.first;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<ParkingSpace> get _filteredSpaces {
    final query = _searchController.text.trim().toLowerCase();
    return _spaces.where((space) {
      final matchesQuery = query.isEmpty ||
          space.name.toLowerCase().contains(query) ||
          space.city.toLowerCase().contains(query) ||
          space.landmark.toLowerCase().contains(query);

      if (!matchesQuery) return false;

      if (_activeFilter == 'available') return space.availableSlots > 0;
      if (_activeFilter == 'cheap') return space.pricePerHour <= 50;
      if (_activeFilter == 'cctv') {
        return space.features.any((f) => f.toLowerCase().contains('cctv'));
      }
      if (_activeFilter == 'covered') {
        return space.features.any((f) => f.toLowerCase().contains('covered'));
      }
      return true;
    }).toList();
  }

  void _onSelectSpace(ParkingSpace space) {
    setState(() => _selectedSpace = space);
    _mapController.move(LatLng(space.latitude, space.longitude), 14.5);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SpaceDetailsSheet(space: space),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displaySpaces = _filteredSpaces;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // 1. FlutterMap
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _chennaiCenter,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.parkme.mobile',
              ),
              MarkerLayer(
                markers: displaySpaces.map((space) {
                  final isSelected = _selectedSpace?.id == space.id;
                  final isAvailable = space.availableSlots > 0;

                  return Marker(
                    point: LatLng(space.latitude, space.longitude),
                    width: 86,
                    height: 38,
                    child: GestureDetector(
                      onTap: () => _onSelectSpace(space),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryDark
                              : (isAvailable ? AppTheme.primary : AppTheme.surfaceLight),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppTheme.warning : Colors.white,
                            width: isSelected ? 2.5 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isAvailable ? AppTheme.accent : AppTheme.danger,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '₹${space.pricePerHour.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                            const Text(
                              '/hr',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // 2. Top Search & Filter Floating Card
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search Box
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 22),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Search landmark, area, or city...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              fillColor: Colors.transparent,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: AppTheme.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'All Spots'),
                        _buildFilterChip('available', 'Open Slots'),
                        _buildFilterChip('cheap', '< ₹50/hr'),
                        _buildFilterChip('cctv', 'CCTV Guarded'),
                        _buildFilterChip('covered', 'Covered Roof'),
                      ],
                    ),
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          backgroundColor: AppTheme.border,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 3. Floating Map Controls (Right side)
          Positioned(
            right: 16,
            bottom: _selectedSpace != null ? 140 : 20,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'recenter_btn',
                  backgroundColor: AppTheme.surface.withValues(alpha: 0.95),
                  foregroundColor: Colors.white,
                  onPressed: () => _mapController.move(_chennaiCenter, 13.0),
                  child: const Icon(Icons.my_location_rounded, size: 20),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'refresh_btn',
                  backgroundColor: AppTheme.surface.withValues(alpha: 0.95),
                  foregroundColor: Colors.white,
                  onPressed: _fetchSpaces,
                  child: const Icon(Icons.refresh_rounded, size: 20),
                ),
              ],
            ),
          ),

          // 4. Floating Selected Spot Mini-Card (Bottom preview)
          if (_selectedSpace != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        ApiService.formatImageUrl(_selectedSpace!.image),
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 64,
                          height: 64,
                          color: AppTheme.surfaceLight,
                          child: const Icon(Icons.local_parking_rounded, color: AppTheme.textMuted),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedSpace!.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_selectedSpace!.availableSlots} slots free • ₹${_selectedSpace!.pricePerHour.toStringAsFixed(0)}/hr',
                            style: const TextStyle(fontSize: 11, color: AppTheme.accent, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => BookingBottomSheet(space: _selectedSpace!),
                        );
                      },
                      child: const Text('Book', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String id, String label) {
    final isSelected = _activeFilter == id;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _activeFilter = id),
        backgroundColor: AppTheme.surface.withValues(alpha: 0.9),
        selectedColor: AppTheme.primary,
        checkmarkColor: Colors.white,
        side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.border),
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isSelected ? Colors.white : AppTheme.textSecondary,
        ),
      ),
    );
  }
}

extension ListFilter<E> on List<E> {
  List<E> filter(bool Function(E element) test) {
    return where(test).toList();
  }
}
