import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../core/storage.dart';
import '../models/user.dart';
import '../models/parking_space.dart';
import '../models/booking.dart';

class ApiService {
  static String get baseUrl => AppConfig.apiBaseUrl;

  static Future<Map<String, String>> _getHeaders({bool requireAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requireAuth) {
      final user = await StorageService.getUser();
      if (user != null && user.token.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${user.token}';
      }
    }
    return headers;
  }

  // Auth: Login
  static Future<UserSession> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final session = UserSession(
        token: data['token'] ?? '',
        name: data['name'] ?? 'Driver',
        role: data['role'] ?? 'seeker',
      );
      await StorageService.saveUser(session);
      return session;
    } else {
      throw Exception(data['detail'] ?? data['error'] ?? 'Login failed');
    }
  }

  // Auth: Signup
  static Future<UserSession> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final session = UserSession(
        token: data['token'] ?? '',
        name: data['name'] ?? name,
        role: data['role'] ?? 'seeker',
      );
      await StorageService.saveUser(session);
      return session;
    } else {
      throw Exception(data['detail'] ?? data['error'] ?? 'Registration failed');
    }
  }

  // Parkings: Fetch all locations
  static Future<List<ParkingSpace>> getParkingSpaces() async {
    final response = await http.get(
      Uri.parse('$baseUrl/parkings'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final dynamic list = jsonDecode(response.body);
      if (list is List) {
        return list.map((item) => ParkingSpace.fromJson(item)).toList();
      }
      return [];
    } else {
      throw Exception('Failed to load parking locations');
    }
  }

  // Bookings: Reserve slot & atomically activate
  static Future<Booking> bookAndConfirmSlot({
    required String parkingId,
    required String vehicleNumber,
    required String bookingDate,
    required String startTime,
    required String endTime,
    required String dayOfWeek,
    required String parkingName,
    required String address,
    required double totalPrice,
    double? latitude,
    double? longitude,
  }) async {
    // 1. Post /book-slot
    final bookRes = await http.post(
      Uri.parse('$baseUrl/book-slot'),
      headers: await _getHeaders(requireAuth: true),
      body: jsonEncode({
        'parking_id': parkingId,
        'vehicle_number': vehicleNumber.trim().toUpperCase(),
        'booking_date': bookingDate,
        'start_time': startTime,
        'end_time': endTime,
        'selected_days': [dayOfWeek],
      }),
    );

    final bookData = jsonDecode(bookRes.body);
    if (bookData['error'] != null) {
      throw Exception(bookData['error']);
    }

    final bookingId = bookData['booking_details']?['_id'] ??
        bookData['booking_id'] ??
        bookData['_id'];

    if (bookingId == null) {
      throw Exception('Failed to initialize booking session');
    }

    // Save vehicle for next time
    await StorageService.saveLastVehicle(vehicleNumber);

    // 2. Activate via /complete-booking
    final completeRes = await http.put(
      Uri.parse('$baseUrl/complete-booking/$bookingId'),
      headers: await _getHeaders(requireAuth: true),
    );

    final completeData = jsonDecode(completeRes.body);
    if (completeData['error'] != null) {
      throw Exception(completeData['error']);
    }

    return Booking(
      id: bookingId,
      parkingName: parkingName,
      address: address,
      vehicleNumber: vehicleNumber.trim().toUpperCase(),
      timeRange: '$startTime - $endTime',
      totalPrice: totalPrice,
      status: 'active',
      latitude: latitude,
      longitude: longitude,
    );
  }

  // Dashboard: Get Driver Bookings
  static Future<Map<String, dynamic>> getUserDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/user-booking-dashboard'),
      headers: await _getHeaders(requireAuth: true),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user booking dashboard');
    }
  }

  // Bookings: Cancel reservation & restore slot
  static Future<void> cancelBooking(String bookingId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/cancel-booking/$bookingId'),
      headers: await _getHeaders(requireAuth: true),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? data['error'] ?? 'Cancellation failed');
    }
  }

  // Host: Get Host Spaces & Earnings
  static Future<Map<String, dynamic>> getHostDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/my-dashboard'),
      headers: await _getHeaders(requireAuth: true),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load host dashboard');
    }
  }

  // Host: Delete Space
  static Future<void> deleteParkingSpace(String parkingId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/delete-parking/$parkingId'),
      headers: await _getHeaders(requireAuth: true),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? data['error'] ?? 'Delete failed');
    }
  }

  // Form image URL
  static String formatImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?auto=format&fit=crop&w=600&q=80';
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '$baseUrl/$path';
  }
}
