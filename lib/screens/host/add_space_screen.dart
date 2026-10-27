import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../core/config.dart';
import '../../core/storage.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';

class AddSpaceScreen extends StatefulWidget {
  final dynamic spaceToEdit;

  const AddSpaceScreen({super.key, this.spaceToEdit});

  @override
  State<AddSpaceScreen> createState() => _AddSpaceScreenState();
}

class _AddSpaceScreenState extends State<AddSpaceScreen> {
  final _mapController = MapController();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController(text: 'Chennai');
  final _landmarkController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController(text: '40');
  final _slotsController = TextEditingController(text: '10');
  final _imageUrlController = TextEditingController(
    text: 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?auto=format&fit=crop&w=800&q=80',
  );

  // Dynamic Location State
  double _lat = 13.0827;
  double _lng = 80.2707;
  String? _resolvedLocationName;
  bool _isLocating = false;

  List<String> _features = ['CCTV', 'Security Guard'];
  final List<String> _availableDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  bool _isLoading = false;
  String? _errorMessage;
  bool get _isEditing => widget.spaceToEdit != null;

  static const List<Map<String, String>> _imagePresets = [
    {
      'title': 'Commercial Bay',
      'url': 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Covered Deck',
      'url': 'https://images.unsplash.com/photo-1590674899484-d5640e854abe?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Tech Park MLCP',
      'url': 'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Open Paved Lot',
      'url': 'https://images.unsplash.com/photo-1545459720-aac8509eb02c?auto=format&fit=crop&w=800&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final s = widget.spaceToEdit;
      _nameController.text = s['name']?.toString() ?? '';
      _cityController.text = s['city']?.toString() ?? 'Chennai';
      _landmarkController.text = s['landmark']?.toString() ?? '';
      _addressController.text = s['address']?.toString() ?? '';

      final rawLat = s['lat'] ?? s['latitude'];
      final rawLng = s['lng'] ?? s['longitude'];
      if (rawLat != null) _lat = double.tryParse(rawLat.toString()) ?? 13.0827;
      if (rawLng != null) _lng = double.tryParse(rawLng.toString()) ?? 80.2707;
      _resolvedLocationName = s['landmark'] ?? s['address'] ?? 'Custom Pin';

      _priceController.text = (s['price_per_hour'] ?? s['price'] ?? 40).toString();
      _slotsController.text = (s['total_slots'] ?? s['slots'] ?? 10).toString();
      if (s['image'] != null && s['image'].toString().isNotEmpty) {
        _imageUrlController.text = s['image'].toString();
      }
      if (s['features'] != null && s['features'] is List) {
        _features = List<String>.from(s['features']);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _landmarkController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _slotsController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _toggleFeature(String f) {
    setState(() {
      if (_features.contains(f)) {
        _features.remove(f);
      } else {
        _features.add(f);
      }
    });
  }

  // Analyze location from street address, landmark, and city
  Future<void> _analyzeLocationFromAddress() async {
    final address = _addressController.text.trim();
    final landmark = _landmarkController.text.trim();
    final city = _cityController.text.trim();

    final query = [landmark, address, city].where((s) => s.isNotEmpty).join(', ');
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an address or landmark first')),
      );
      return;
    }

    setState(() => _isLocating = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1',
      );
      final res = await http.get(uri, headers: {'User-Agent': 'ParkMeApp/1.0'}).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat'].toString());
          final lon = double.tryParse(data[0]['lon'].toString());
          if (lat != null && lon != null) {
            setState(() {
              _lat = lat;
              _lng = lon;
              _resolvedLocationName = data[0]['display_name'] ?? query;
            });
            _mapController.move(LatLng(lat, lon), 15.0);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Location found and pinned on map!'),
                  backgroundColor: AppTheme.accent,
                  duration: Duration(seconds: 2),
                ),
              );
            }
            return;
          }
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exact location not found. You can tap anywhere on the map to set pin.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not reach geocoding service. Tap on map to pin spot.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  // Use live location via IP geolocation fallback
  Future<void> _useLiveLocation() async {
    setState(() => _isLocating = true);
    try {
      final res = await http
          .get(Uri.parse('http://ip-api.com/json/'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          final lat = (data['lat'] as num).toDouble();
          final lon = (data['lon'] as num).toDouble();
          setState(() {
            _lat = lat;
            _lng = lon;
            _resolvedLocationName = '${data['city'] ?? 'Live Location'}, ${data['regionName'] ?? ''}';
            if (_cityController.text.isEmpty && data['city'] != null) {
              _cityController.text = data['city'];
            }
          });
          _mapController.move(LatLng(lat, lon), 15.0);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Live location detected: ${data['city'] ?? 'Area'}'),
                backgroundColor: AppTheme.accent,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return;
        }
      }
      // Fallback: move to current pin
      _mapController.move(LatLng(_lat, _lng), 14.5);
    } catch (_) {
      _mapController.move(LatLng(_lat, _lng), 14.5);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  // User taps on the map to manually set or adjust location
  void _onMapTapped(TapPosition tapPosition, LatLng point) async {
    setState(() {
      _lat = point.latitude;
      _lng = point.longitude;
      _resolvedLocationName = 'Pinned on map';
    });
    // Reverse geocode to suggest neighborhood or address
    try {
      final res = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=${point.latitude}&lon=${point.longitude}&format=json'),
        headers: {'User-Agent': 'ParkMeApp/1.0'},
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final displayName = data['display_name'];
        if (displayName != null && mounted) {
          setState(() {
            _resolvedLocationName = displayName.toString();
            if (_addressController.text.trim().isEmpty) {
              _addressController.text = displayName.toString();
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    if (name.isEmpty || address.isEmpty) {
      setState(() => _errorMessage = 'Please provide facility name and address');
      return;
    }

    final user = await StorageService.getUser();
    if (user == null || user.token.isEmpty) {
      setState(() => _errorMessage = 'Please log in to continue');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final imageUrl = _imageUrlController.text.trim();

      if (_isEditing) {
        final spaceId = widget.spaceToEdit['id'] ??
            widget.spaceToEdit['_id'] ??
            widget.spaceToEdit['parking_id'];

        if (spaceId == null || spaceId.toString().isEmpty) {
          throw Exception('Invalid space identifier for update');
        }

        await ApiService.updateParkingSpace(
          spaceId: spaceId.toString(),
          name: name,
          city: _cityController.text.trim(),
          landmark: _landmarkController.text.trim(),
          address: address,
          slots: int.tryParse(_slotsController.text.trim()) ?? 10,
          pricePerHour: double.tryParse(_priceController.text.trim()) ?? 40.0,
          days: _availableDays,
          features: _features,
          imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
          lat: _lat,
          lng: _lng,
        );
      } else {
        final uri = Uri.parse('${AppConfig.apiBaseUrl}/add-parking');
        final request = http.MultipartRequest('POST', uri);
        request.headers['Authorization'] = 'Bearer ${user.token}';

        request.fields['name'] = name;
        request.fields['city'] = _cityController.text.trim();
        request.fields['landmark'] = _landmarkController.text.trim();
        request.fields['address'] = address;
        request.fields['lat'] = _lat.toString();
        request.fields['lng'] = _lng.toString();
        request.fields['price_per_hour'] = _priceController.text.trim();
        request.fields['total_slots'] = _slotsController.text.trim();
        request.fields['available_slots'] = _slotsController.text.trim();
        if (imageUrl.isNotEmpty) {
          request.fields['image_url'] = imageUrl;
        }

        for (var f in _features) {
          request.files.add(http.MultipartFile.fromString('features', f));
        }
        for (var d in _availableDays) {
          request.files.add(http.MultipartFile.fromString('available_days', d));
        }

        const dummyPngBase64 =
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
        final dummyBytes = base64Decode(dummyPngBase64);
        request.files.add(
          http.MultipartFile.fromBytes('image', dummyBytes, filename: 'parking.png'),
        );

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode != 200) {
          final data = jsonDecode(response.body);
          throw Exception(data['detail'] ?? data['error'] ?? 'Failed to add space');
        }
      }

      if (!mounted) return;
      Navigator.pop(context, true); // Success
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewUrl = ApiService.formatImageUrl(_imageUrlController.text.trim());

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Parking Space' : 'List Parking Space'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppTheme.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

              // Property Photo Section
              const Text(
                'PROPERTY PHOTO',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),

              // Image Live Preview
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 130,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        previewUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppTheme.surfaceLight,
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported_outlined, color: AppTheme.textSecondary, size: 36),
                              SizedBox(height: 6),
                              Text('No image preview', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.visibility_rounded, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text('Live Preview', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Presets selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _imagePresets.map((preset) {
                    final isSelected = _imageUrlController.text.trim() == preset['url'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _imageUrlController.text = preset['url']!;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primary.withValues(alpha: 0.12) : AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppTheme.primary : AppTheme.border,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  preset['url']!,
                                  width: 22,
                                  height: 22,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                preset['title']!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _imageUrlController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Or enter custom image URL...',
                  prefixIcon: const Icon(Icons.link_rounded, size: 18),
                  suffixIcon: _imageUrlController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _imageUrlController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              const Text('FACILITY NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(hintText: 'e.g. Express Avenue Basement Bay B'),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _cityController,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('LANDMARK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _landmarkController,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                          decoration: const InputDecoration(hintText: 'Near Metro / Junction'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              const Text('FULL STREET ADDRESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: _addressController,
                maxLines: 2,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(hintText: 'e.g. No. 45, Anna Salai, Thousand Lights'),
              ),
              const SizedBox(height: 14),

              // ================= SMART LOCATION SETTER =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'LOCATION & PINPOINT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary),
                  ),
                  if (_isLocating)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                    ),
                ],
              ),
              const SizedBox(height: 6),

              // Action buttons: "Analyze Address" & "Use Live Location"
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLocating ? null : _analyzeLocationFromAddress,
                      icon: const Icon(Icons.travel_explore_rounded, size: 16),
                      label: const Text('Analyze Address', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary, width: 1.2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLocating ? null : _useLiveLocation,
                      icon: const Icon(Icons.my_location_rounded, size: 16),
                      label: const Text('Live Location', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        foregroundColor: AppTheme.accent,
                        side: const BorderSide(color: AppTheme.accent, width: 1.2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Interactive Mini-Map Pin Selector
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: LatLng(_lat, _lng),
                          initialZoom: 14.5,
                          onTap: _onMapTapped,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.parkme.mobile',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(_lat, _lng),
                                width: 44,
                                height: 44,
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: AppTheme.danger,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.touch_app_rounded, color: AppTheme.primary, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _resolvedLocationName != null && _resolvedLocationName!.isNotEmpty
                                      ? '📍 $_resolvedLocationName'
                                      : 'Tap anywhere on the map to set parking pin',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('HOURLY TARIFF (₹)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOTAL SLOTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _slotsController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text('AMENITIES & SECURITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['CCTV', 'Security Guard', 'Covered', 'EV Charging', '24/7 Access', 'Automated Lift'].map((f) {
                  final isSelected = _features.contains(f);
                  return FilterChip(
                    label: Text(f),
                    selected: isSelected,
                    onSelected: (_) => _toggleFeature(f),
                    backgroundColor: AppTheme.surfaceLight,
                    selectedColor: AppTheme.primary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _isEditing ? 'Save Changes' : 'Publish Space to ParkMe Network',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
