class ParkingSpace {
  final String id;
  final String name;
  final String city;
  final String landmark;
  final String address;
  final double pricePerHour;
  final int totalSlots;
  final int availableSlots;
  final List<String> features;
  final List<String> availableDays;
  final String? image;
  final double latitude;
  final double longitude;

  ParkingSpace({
    required this.id,
    required this.name,
    required this.city,
    required this.landmark,
    required this.address,
    required this.pricePerHour,
    required this.totalSlots,
    required this.availableSlots,
    required this.features,
    required this.availableDays,
    this.image,
    required this.latitude,
    required this.longitude,
  });

  bool get isAvailable => availableSlots > 0;

  factory ParkingSpace.fromJson(Map<String, dynamic> json) {
    double lat = 13.0827; // Default Chennai
    double lng = 80.2707;

    if (json['location'] != null && json['location']['coordinates'] != null) {
      final coords = json['location']['coordinates'];
      if (coords is List && coords.length >= 2) {
        lng = (coords[0] as num).toDouble();
        lat = (coords[1] as num).toDouble();
      }
    } else if (json['lat'] != null && json['lng'] != null) {
      lat = (json['lat'] as num).toDouble();
      lng = (json['lng'] as num).toDouble();
    }

    return ParkingSpace(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Parking Bay',
      city: json['city'] ?? 'Chennai',
      landmark: json['landmark'] ?? '',
      address: json['address'] ?? '',
      pricePerHour: (json['price_per_hour'] ?? json['price'] ?? 20).toDouble(),
      totalSlots: (json['total_slots'] ?? 10) as int,
      availableSlots: (json['available_slots'] ?? 0) as int,
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      availableDays: (json['available_days'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      image: json['image'],
      latitude: lat,
      longitude: lng,
    );
  }
}
