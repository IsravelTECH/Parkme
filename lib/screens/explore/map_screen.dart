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
  final ScrollController _listScrollController = ScrollController();

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

  @override
  void dispose() {
    _searchController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  void setSearchQuery(String query) {
    _searchController.text = query;
    setState(() {});
    final list = _filteredSpaces;
    if (list.isNotEmpty) {
      _mapController.move(LatLng(list.first.latitude, list.first.longitude), 14.0);
    }
  }

  void selectSpace(ParkingSpace space) {
    _onSelectSpace(space, centerMap: true, scrollToList: true);
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
      if (_searchController.text.isNotEmpty && _filteredSpaces.isNotEmpty) {
        _mapController.move(
          LatLng(_filteredSpaces.first.latitude, _filteredSpaces.first.longitude),
          14.0,
        );
      }
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
          space.landmark.toLowerCase().contains(query) ||
          space.address.toLowerCase().contains(query) ||
          space.features.any((f) => f.toLowerCase().contains(query));

      if (!matchesQuery) return false;

      if (_activeFilter == 'available') return space.availableSlots > 0;
      if (_activeFilter == 'cheap') return space.pricePerHour <= 50;
      if (_activeFilter == 'ev') {
        return space.features.any((f) => f.toLowerCase().contains('ev'));
      }
      if (_activeFilter == 'cctv') {
        return space.features.any((f) => f.toLowerCase().contains('cctv'));
      }
      if (_activeFilter == 'covered') {
        return space.features.any((f) => f.toLowerCase().contains('covered'));
      }
      return true;
    }).toList();
  }

  void _onSelectSpace(ParkingSpace space, {bool centerMap = true, bool scrollToList = true}) {
    setState(() => _selectedSpace = space);

    if (centerMap) {
      _mapController.move(LatLng(space.latitude, space.longitude), 14.8);
    }

    if (scrollToList && _listScrollController.hasClients) {
      final list = _filteredSpaces;
      final index = list.indexWhere((s) => s.id == space.id);
      if (index != -1) {
        final target = (index * 128.0).clamp(0.0, _listScrollController.position.maxScrollExtent);
        _listScrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displaySpaces = _filteredSpaces;
    final size = MediaQuery.of(context).size;
    final mapHeight = size.height * 0.42;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // ================= UPPER PART: MAP & SEARCH =================
          SizedBox(
            height: mapHeight,
            child: Stack(
              children: [
                // 1. FlutterMap
                FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: _chennaiCenter,
                    initialZoom: 12.8,
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
                            onTap: () => _onSelectSpace(space, centerMap: true, scrollToList: true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primary
                                    : (isAvailable ? Colors.white : AppTheme.surfaceLight),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? AppTheme.accent : AppTheme.border,
                                  width: isSelected ? 2.5 : 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isSelected ? 0.3 : 0.12),
                                    blurRadius: isSelected ? 8 : 4,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: isAvailable ? AppTheme.accent : AppTheme.danger,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '₹${space.pricePerHour.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    '/hr',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white70 : AppTheme.textSecondary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
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

                // 2. Floating Search Bar over Map
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(Icons.search_rounded, color: AppTheme.primary, size: 20),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) {
                                setState(() {});
                                final matches = _filteredSpaces;
                                if (matches.isNotEmpty) {
                                  _mapController.move(
                                    LatLng(matches.first.latitude, matches.first.longitude),
                                    14.0,
                                  );
                                }
                              },
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Search city, landmark, or features...',
                                hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
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
                              icon: const Icon(Icons.clear_rounded, size: 18, color: AppTheme.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Floating Map Controls (Recenter & Refresh)
                Positioned(
                  right: 14,
                  bottom: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'map_recenter_btn',
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primary,
                        elevation: 3,
                        onPressed: () => _mapController.move(_chennaiCenter, 12.8),
                        child: const Icon(Icons.my_location_rounded, size: 18),
                      ),
                      const SizedBox(height: 6),
                      FloatingActionButton.small(
                        heroTag: 'map_refresh_btn',
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.textPrimary,
                        elevation: 3,
                        onPressed: _fetchSpaces,
                        child: const Icon(Icons.refresh_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading Progress Bar
          if (_isLoading)
            const LinearProgressIndicator(
              minHeight: 2.5,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),

          // ================= DOWN PART: SLOTS LIST & FILTERS =================
          Expanded(
            child: Container(
              color: AppTheme.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Filter Chips
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                    color: Colors.white,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('all', 'All Spots (${_spaces.length})'),
                          _buildFilterChip('available', 'Open Slots'),
                          _buildFilterChip('cheap', '< ₹50/hr'),
                          _buildFilterChip('ev', 'EV Charging'),
                          _buildFilterChip('cctv', 'CCTV Guarded'),
                          _buildFilterChip('covered', 'Covered Roof'),
                        ],
                      ),
                    ),
                  ),

                  // Results Header Count
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${displaySpaces.length} PARKING HUBS FOUND',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.6,
                          ),
                        ),
                        if (_selectedSpace != null)
                          Text(
                            'Active: ${_selectedSpace!.name.split(' ').take(2).join(' ')}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Slots List View
                  Expanded(
                    child: displaySpaces.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _listScrollController,
                            padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
                            itemCount: displaySpaces.length,
                            itemBuilder: (context, index) {
                              final space = displaySpaces[index];
                              final isSelected = _selectedSpace?.id == space.id;
                              return _buildSpaceCard(space, isSelected);
                            },
                          ),
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
        backgroundColor: AppTheme.surfaceLight,
        selectedColor: AppTheme.primary,
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.border,
          width: isSelected ? 1.4 : 1.0,
        ),
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isSelected ? Colors.white : AppTheme.textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
    );
  }

  Widget _buildSpaceCard(ParkingSpace space, bool isSelected) {
    final isAvailable = space.availableSlots > 0;
    final imageUrl = ApiService.formatImageUrl(space.image);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.primary : AppTheme.border,
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppTheme.primary.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: isSelected ? 10 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _onSelectSpace(space, centerMap: true, scrollToList: false),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: 82,
                  height: 82,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 82,
                    height: 82,
                    color: AppTheme.surfaceLight,
                    child: const Icon(Icons.local_parking_rounded, color: AppTheme.textSecondary, size: 32),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Details & Booking Action
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Info icon
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            space.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => SpaceDetailsSheet(space: space),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Landmark / City
                    Text(
                      '${space.landmark.isNotEmpty ? space.landmark : space.address}, ${space.city}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Feature tags preview
                    if (space.features.isNotEmpty)
                      Row(
                        children: space.features.take(2).map((feat) {
                          return Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              feat,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 8),

                    // Bottom Row: Price & Slots + Reserve Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '₹${space.pricePerHour.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                const Text(
                                  '/hr',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              isAvailable ? '${space.availableSlots} free' : 'Full',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isAvailable ? AppTheme.accent : AppTheme.danger,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAvailable ? AppTheme.primary : AppTheme.surfaceLight,
                            foregroundColor: isAvailable ? Colors.white : AppTheme.textMuted,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            elevation: isAvailable ? 1 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: isAvailable
                              ? () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => BookingBottomSheet(space: space),
                                  );
                                }
                              : null,
                          child: Text(
                            isAvailable ? 'Reserve' : 'Filled',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            const Text(
              'No Parking Hubs Found',
              style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary, fontSize: 15),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try adjusting your search keywords or clearing filters',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _activeFilter = 'all');
              },
              child: const Text('Reset All Filters', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
