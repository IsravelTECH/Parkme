import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/storage.dart';
import '../../models/parking_space.dart';
import '../../services/api_service.dart';
import 'digital_pass_screen.dart';

class BookingBottomSheet extends StatefulWidget {
  final ParkingSpace space;

  const BookingBottomSheet({super.key, required this.space});

  @override
  State<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  final _vehicleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  int _durationHours = 2;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVehicle();
    // Default start time to next rounded hour
    final now = DateTime.now();
    _startTime = TimeOfDay(hour: (now.hour + 1) % 24, minute: 0);
  }

  Future<void> _loadVehicle() async {
    final vehicle = await StorageService.getLastVehicle();
    setState(() => _vehicleController.text = vehicle);
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _calculateEndTime(TimeOfDay start, int hours) {
    final endHour = (start.hour + hours) % 24;
    final h = endHour.toString().padLeft(2, '0');
    final m = start.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _getDayAbbr(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d.weekday - 1];
  }

  Future<void> _handleConfirm() async {
    final vehicle = _vehicleController.text.trim();
    if (vehicle.isEmpty) {
      setState(() => _errorMessage = 'Please enter vehicle registration number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final startStr = _formatTime(_startTime);
      final endStr = _calculateEndTime(_startTime, _durationHours);
      final dayOfWeek = _getDayAbbr(_selectedDate);
      final totalPrice = _durationHours * widget.space.pricePerHour;

      final booking = await ApiService.bookAndConfirmSlot(
        parkingId: widget.space.id,
        vehicleNumber: vehicle,
        bookingDate: dateStr,
        startTime: startStr,
        endTime: endStr,
        dayOfWeek: dayOfWeek,
        parkingName: widget.space.name,
        address: widget.space.address.isNotEmpty ? widget.space.address : widget.space.city,
        totalPrice: totalPrice,
        latitude: widget.space.latitude,
        longitude: widget.space.longitude,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close bottom sheet
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DigitalPassScreen(booking: booking),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = _durationHours * widget.space.pricePerHour;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Space Title & Tariff
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.space.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.space.landmark.isNotEmpty ? widget.space.landmark : widget.space.city,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '₹${widget.space.pricePerHour.toStringAsFixed(0)}/hr',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),

            // Vehicle Plate Number
            const Text('VEHICLE REGISTRATION NUMBER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: _vehicleController,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.directions_car_rounded, color: AppTheme.textMuted, size: 20),
                hintText: 'e.g. TN 09 AB 1234',
              ),
            ),
            const SizedBox(height: 14),

            // Date & Start Time
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DATE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('MMM dd, yyyy').format(_selectedDate),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _startTime,
                      );
                      if (picked != null) setState(() => _startTime = picked);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('START TIME', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
                          const SizedBox(height: 2),
                          Text(
                            _formatTime(_startTime),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Duration Selector Pills
            const Text('DURATION (HOURS)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            Row(
              children: [1, 2, 3, 4, 8].map((h) {
                final isSelected = _durationHours == h;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () => setState(() => _durationHours = h),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
                        ),
                        child: Center(
                          child: Text(
                            '${h}h',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Total Cost Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL PAYABLE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
                      Text(
                        '$_durationHours hr${_durationHours > 1 ? 's' : ''} (until ${_calculateEndTime(_startTime, _durationHours)})',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  Text(
                    '₹${totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.accent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Confirm Button
            ElevatedButton(
              onPressed: _isLoading ? null : _handleConfirm,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Confirm & Issue Pass (₹${totalPrice.toStringAsFixed(0)})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
