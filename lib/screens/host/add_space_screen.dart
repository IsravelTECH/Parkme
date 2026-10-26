import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/config.dart';
import '../../core/storage.dart';
import '../../core/theme.dart';

class AddSpaceScreen extends StatefulWidget {
  const AddSpaceScreen({super.key});

  @override
  State<AddSpaceScreen> createState() => _AddSpaceScreenState();
}

class _AddSpaceScreenState extends State<AddSpaceScreen> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController(text: 'Chennai');
  final _landmarkController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController(text: '13.0827');
  final _lngController = TextEditingController(text: '80.2707');
  final _priceController = TextEditingController(text: '40');
  final _slotsController = TextEditingController(text: '10');

  final List<String> _features = ['CCTV', 'Security Guard'];
  final List<String> _availableDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  bool _isLoading = false;
  String? _errorMessage;

  void _toggleFeature(String f) {
    setState(() {
      if (_features.contains(f)) {
        _features.remove(f);
      } else {
        _features.add(f);
      }
    });
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
      setState(() => _errorMessage = 'Please log in to publish spaces');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/add-parking');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer ${user.token}';

      request.fields['name'] = name;
      request.fields['city'] = _cityController.text.trim();
      request.fields['landmark'] = _landmarkController.text.trim();
      request.fields['address'] = address;
      request.fields['lat'] = _latController.text.trim();
      request.fields['lng'] = _lngController.text.trim();
      request.fields['price_per_hour'] = _priceController.text.trim();
      request.fields['total_slots'] = _slotsController.text.trim();
      request.fields['available_slots'] = _slotsController.text.trim();

      for (var f in _features) {
        request.files.add(http.MultipartFile.fromString('features', f));
      }
      for (var d in _availableDays) {
        request.files.add(http.MultipartFile.fromString('available_days', d));
      }

      // Add dummy 1x1 png image payload if user didn't pick from camera
      // Base64 transparent 1x1 PNG bytes
      const dummyPngBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
      final dummyBytes = base64Decode(dummyPngBase64);
      request.files.add(
        http.MultipartFile.fromBytes('image', dummyBytes, filename: 'parking.png'),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context, true); // Success
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['detail'] ?? data['error'] ?? 'Failed to add space');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('List Parking Space')),
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
                    color: AppTheme.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
                  ),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),

              const Text('FACILITY NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
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
                          style: const TextStyle(color: Colors.white, fontSize: 14),
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
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(hintText: 'Near Metro'),
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
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(hintText: 'No. 45, Anna Salai, Thousand Lights'),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('LATITUDE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
                        const SizedBox(height: 6),
                        TextField(controller: _latController, style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('LONGITUDE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
                        const SizedBox(height: 6),
                        TextField(controller: _lngController, style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                ],
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
                        TextField(controller: _priceController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 14)),
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
                        TextField(controller: _slotsController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              const Text('AMENITIES & SECURITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['CCTV', 'Security Guard', 'Covered', 'EV Charging', '24/7 Access'].map((f) {
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
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Publish Space to ParkMe Network', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
