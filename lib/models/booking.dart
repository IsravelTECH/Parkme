class Booking {
  final String id;
  final String parkingName;
  final String address;
  final String vehicleNumber;
  final String timeRange;
  final double totalPrice;
  final String status;
  final String? image;
  final int remainingMinutes;
  final double? latitude;
  final double? longitude;

  Booking({
    required this.id,
    required this.parkingName,
    required this.address,
    required this.vehicleNumber,
    required this.timeRange,
    required this.totalPrice,
    required this.status,
    this.image,
    this.remainingMinutes = 0,
    this.latitude,
    this.longitude,
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  factory Booking.fromDashboardJson(Map<String, dynamic> json) {
    return Booking(
      id: json['booking_id'] ?? json['_id'] ?? '',
      parkingName: json['parking_name'] ?? 'Parking Space',
      address: json['address'] ?? json['parking_address'] ?? 'Chennai',
      vehicleNumber: json['vehicle'] ?? json['vehicle_number'] ?? 'N/A',
      timeRange: json['time'] ?? json['time_range'] ?? 'Active Window',
      totalPrice: (json['amount'] ?? json['total_price'] ?? 0).toDouble(),
      status: json['status'] ?? 'active',
      image: json['image'] ?? json['image_url'],
    );
  }

  factory Booking.fromDetailsJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] ?? json['booking_id'] ?? '',
      parkingName: json['parking_name'] ?? 'Parking Space',
      address: json['parking_address'] ?? json['address'] ?? 'Chennai',
      vehicleNumber: json['vehicle_number'] ?? json['vehicle'] ?? '',
      timeRange: json['time_range'] ?? json['time'] ?? '',
      totalPrice: (json['total_price'] ?? json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'active',
      remainingMinutes: json['remaining_minutes'] ?? 0,
    );
  }
}
