import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/slot.dart';
import '../services/database_helper.dart';
import '../services/mqtt_service.dart';

class MetaRaceProvider with ChangeNotifier {
  User? _currentUser;
  List<Slot> _slots = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final MqttService _mqttService = MqttService();

  User? get currentUser => _currentUser;
  List<Slot> get slots => _slots;

  MetaRaceProvider() {
    _mqttService.connect();
  }

  Future<bool> register(String name, String identifier, String password) async {
    try {
      User user = User(username: name, identifier: identifier, password: password);
      await _dbHelper.registerUser(user);
      
      // Broadcast via MQTT with the unified identifier
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
      
      // Broadcast via MQTT with the unified identifier
      _mqttService.sendLoginPayload(identifier, password);
      
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  Future<void> fetchSlots() async {
    _slots = await _dbHelper.getSlots();
    notifyListeners();
  }

  Future<bool> bookSlot(int slotId) async {
    try {
      if (_currentUser == null) return false;
      await _dbHelper.updateSlotStatus(slotId, 1, _currentUser!.id);
      final race = _slots.firstWhere((s) => s.id == slotId);
      _mqttService.publishRaceEvent(
        'grid_entry',
        {
          'id': race.id,
          'track_name': race.trackName,
          'time_label': race.timeLabel,
          'car_model': race.carModel,
        },
        _currentUser!.id,
      );
      await fetchSlots();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelBooking(int slotId) async {
    try {
      if (_currentUser == null) return false;
      final race = _slots.firstWhere((s) => s.id == slotId);
      await _dbHelper.updateSlotStatus(slotId, 0, null);
      _mqttService.publishRaceEvent(
        'grid_exit',
        {
          'id': race.id,
          'track_name': race.trackName,
          'time_label': race.timeLabel,
          'car_model': race.carModel,
        },
        _currentUser!.id,
      );
      await fetchSlots();
      return true;
    } catch (e) {
      return false;
    }
  }
}
