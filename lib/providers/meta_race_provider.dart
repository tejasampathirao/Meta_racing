import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/slot.dart';
import '../services/database_helper.dart';
import '../services/mqtt_service.dart';

class MetaRaceProvider with ChangeNotifier {
  User? _currentUser;
  List<Slot> _slots = [];
  List<Map<String, dynamic>> _history = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final MqttService _mqttService = MqttService();

  User? get currentUser => _currentUser;
  List<Slot> get slots => _slots;
  List<Map<String, dynamic>> get history => _history;

  MetaRaceProvider() {
    _mqttService.connect();
  }

  Future<bool> register(String name, String identifier, String password) async {
    try {
      User user = User(username: name, identifier: identifier, password: password);
      await _dbHelper.registerUser(user);
      _mqttService.sendRegisterPayload(name, identifier, password);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> login(String identifier, String password) async {
    User? user = await _dbHelper.loginUser(identifier, password);
    if (user != null) {
      _currentUser = user;
      _mqttService.sendLoginPayload(identifier, password);
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    _history = [];
    notifyListeners();
  }

  Future<void> fetchSlots() async {
    _slots = await _dbHelper.getSlots();
    notifyListeners();
  }

  Future<void> fetchHistory() async {
    if (_currentUser == null) return;
    _history = await _dbHelper.getHistory(_currentUser!.id!);
    notifyListeners();
  }

  Future<bool> confirmBooking(int slotId, String driverName, String raceDate) async {
    try {
      if (_currentUser == null) return false;
      if (_slots.isEmpty) {
        await fetchSlots();
      }
      
      final slotIndex = _slots.indexWhere((s) => s.id == slotId);
      if (slotIndex == -1) {
        print("Confirm Booking Error: Slot ID $slotId not found");
        return false;
      }
      final slot = _slots[slotIndex];
      
      if (slot.bookedCount < slot.capacity) {
        // 1. Update Local SQL Slots
        int newCount = slot.bookedCount + 1;
        await _dbHelper.updateSlotBooking(slotId, newCount, _currentUser!.id);

        // 2. Save to History Table
        await _dbHelper.insertHistory({
          'user_id': _currentUser!.id,
          'driver_name': driverName,
          'track_name': slot.trackName,
          'time_label': slot.timeLabel,
          'race_date': raceDate,
          'booked_at': DateTime.now().toIso8601String(),
        });

        // 3. Send detailed MQTT Payload
        _mqttService.sendBookingCreate(
          name: driverName,
          date: raceDate,
          raceData: {
            'id': slot.id,
            'track_name': slot.trackName,
            'time_label': slot.timeLabel,
            'car_model': slot.carModel,
            'capacity': slot.capacity,
            'booked_count': slot.bookedCount,
          },
          userId: _currentUser?.id,
        );

        await fetchSlots();
        await fetchHistory();
        return true;
      }
      return false;
    } catch (e) {
      print("Confirm Booking Error: $e");
      return false;
    }
  }

  Future<bool> bookSlot(int slotId) async {
    return await confirmBooking(slotId, _currentUser?.username ?? "Driver", DateTime.now().toString().split(' ')[0]);
  }

  Future<bool> cancelBooking(int slotId) async {
    try {
      if (_currentUser == null) return false;
      if (_slots.isEmpty) {
        await fetchSlots();
      }

      final shiftIndex = _slots.indexWhere((s) => s.id == slotId);
      if (shiftIndex == -1) {
        print("Cancel Booking Error: Slot ID $slotId not found");
        return false;
      }
      final shift = _slots[shiftIndex];
      int newCount = shift.bookedCount > 0 ? shift.bookedCount - 1 : 0;

      await _dbHelper.cancelBooking(slotId, newCount);
      _mqttService.sendBookingCancel(slotId, _currentUser?.id);

      await fetchSlots();
      await fetchHistory(); // History remains, but status is different usually. For now just refreshing.
      return true;
    } catch (e) {
      print("Cancel Booking Error: $e");
      return false;
    }
  }
}
