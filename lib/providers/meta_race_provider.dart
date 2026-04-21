import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/booking.dart';
import '../services/database_helper.dart';
import '../services/mqtt_service.dart';

class MetaRaceProvider with ChangeNotifier {
  User? _currentUser;
  List<Booking> _bookings = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final MqttService _mqttService = MqttService();

  final List<StreamSubscription> _subscriptions = [];

  User? get currentUser => _currentUser;
  List<Booking> get bookings => _bookings;

  MetaRaceProvider() {
    _mqttService.connect();
    _setupListeners();
  }

  void _setupListeners() {
    _subscriptions.add(
      _mqttService.onBookingCreateAck.listen((data) {
        if (data['success'] == true && _currentUser != null) {
          fetchBookings();
        }
      }),
    );

    _subscriptions.add(
      _mqttService.onBookingCancelAck.listen((data) {
        if (data['success'] == true && _currentUser != null) {
          fetchBookings();
        }
      }),
    );

    _subscriptions.add(
      _mqttService.onBookingViewAck.listen((data) {
        if (data['success'] == true) {
          final list = data['bookings'] as List<dynamic>? ?? [];
          _bookings = list
              .map((b) => Booking.fromMap(b as Map<String, dynamic>))
              .toList();
          notifyListeners();
        }
      }),
    );
  }

  Future<bool> register(
    String name,
    String email,
    String phone,
    String password, {
    String role = 'user',
  }) async {
    try {
      User user = User(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );
      await _dbHelper.registerUser(user);
      _mqttService.sendRegisterPayload(
        name,
        email,
        phone,
        password,
        role: role,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    User? user = await _dbHelper.loginUser(email, password);
    if (user != null) {
      _currentUser = user;
      _mqttService.sendLoginPayload(email, password, role: user.role);
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    if (_currentUser?.id != null) {
      _mqttService.sendLogoutPayload(_currentUser!.id!);
    }
    _currentUser = null;
    _bookings = [];
    notifyListeners();
  }

  void fetchBookings() {
    if (_currentUser?.id != null) {
      _mqttService.sendViewBookings(_currentUser!.id!);
    }
  }

  void createBooking({
    required String experience,
    required String plan,
    required String date,
    required String timeSlot,
    required int guests,
    String message = '',
  }) {
    if (_currentUser == null) return;

    // Add to local list immediately so UI updates
    final booking = Booking(
      name: _currentUser!.name,
      email: _currentUser!.email,
      phone: _currentUser!.phone,
      experience: experience,
      plan: plan,
      date: date,
      timeSlot: timeSlot,
      guests: guests,
      message: message,
      status: 'confirmed',
      customerId: _currentUser!.id,
    );
    _bookings.add(booking);
    notifyListeners();

    _mqttService.sendBookingCreate(
      name: _currentUser!.name,
      email: _currentUser!.email,
      phone: _currentUser!.phone,
      experience: experience,
      plan: plan,
      date: date,
      timeSlot: timeSlot,
      guests: guests,
      message: message,
      customerId: _currentUser!.id,
    );
  }

  void cancelBookingByIndex(int index) {
    if (index < 0 || index >= _bookings.length) return;
    final old = _bookings[index];
    _bookings[index] = Booking(
      id: old.id,
      name: old.name,
      email: old.email,
      phone: old.phone,
      experience: old.experience,
      plan: old.plan,
      date: old.date,
      timeSlot: old.timeSlot,
      guests: old.guests,
      message: old.message,
      status: 'cancelled',
      customerId: old.customerId,
    );
    notifyListeners();
    if (old.id != null) {
      _mqttService.sendBookingCancel(old.id!);
    }
  }

  MqttService get mqttService => _mqttService;

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _mqttService.dispose();
    super.dispose();
  }
}
