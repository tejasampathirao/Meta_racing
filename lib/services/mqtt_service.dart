import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  late MqttServerClient client;
  // Updated to your specific broker address
  final String server = '13.203.2.58'; 
  final String clientId = 'meta_race_client_${DateTime.now().millisecondsSinceEpoch}';

  static const String registerTopic = 'metarace/auth/register';
  static const String loginTopic = 'metarace/auth/login';
  static const String gridUpdateTopic = 'metarace/grid/updates';
  static const String bookingCreateTopic = 'metarace/booking/create';
  static const String bookingCancelTopic = 'metarace/booking/cancel';

  MqttService() {
    client = MqttServerClient(server, clientId);
    client.port = 1883;
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    
    // Set callbacks
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
    
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean() // Non persistent session for auth events
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;
  }

  bool _isConnecting = false;

  Future<bool> connect() async {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      return true;
    }
    if (_isConnecting) {
      print('MQTT: Connection attempt already in progress...');
      return false;
    }

    _isConnecting = true;
    try {
      print('MQTT: Connecting to $server...');
      await client.connect();
      return client.connectionStatus?.state == MqttConnectionState.connected;
    } catch (e) {
      print('MQTT: Connection failed - $e');
      if (client.connectionStatus?.state != MqttConnectionState.disconnected) {
        try {
          client.disconnect();
        } catch (_) {}
      }
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  void _onConnected() {
    print('MQTT: Connected Successfully');
    _isConnecting = false;
  }

  void _onDisconnected() {
    print('MQTT: Disconnected from Broker');
    _isConnecting = false;
  }

  void _onSubscribed(String topic) {
    print('MQTT: Subscribed to $topic');
  }

  void publish(String topic, Map<String, dynamic> payload) {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(jsonEncode(payload));
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      print('MQTT: Published to $topic: ${jsonEncode(payload)}');
    } else {
      print('MQTT: Not connected, attempting to reconnect...');
      connect().then((connected) {
        if (connected) {
          publish(topic, payload);
        }
      });
    }
  }

  void sendRegisterPayload(String name, String identifier, String password) {
    final payload = {
      'action': 'register',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'name': name,
        'identifier': identifier, // Combined Email or Phone
        'password': password,
      }
    };
    publish(registerTopic, payload);
  }

  void sendLoginPayload(String identifier, String password) {
    final payload = {
      'action': 'login',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'identifier': identifier, // Combined Email or Phone
        'password': password
      },
    };
    publish(loginTopic, payload);
  }

  // Specialized method for real-time race telemetry
  void publishRaceEvent(String action, Map<String, dynamic> raceData, int? driverId) {
    final payload = {
      'event': action, // e.g., 'grid_entry' or 'grid_exit'
      'driver_id': driverId,
      'race_details': {
        'slot_id': raceData['id'],
        'track': raceData['track_name'],
        'session_time': raceData['time_label'],
        'vehicle': raceData['car_model'],
      },
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'confirmed'
    };

    publish(gridUpdateTopic, payload);
  }

  void sendBookingCreate({
    required String name,
    required String date,
    required Map<String, dynamic> raceData,
    required int? userId,
  }) {
    final payload = {
      'action': 'ticketbooking',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'driver_name': name,
        'race_date': date,
        'slot_id': raceData['id'],
        'track': raceData['track_name'],
        'time_slot': raceData['time_label'],
        'car_model': raceData['car_model'],
        'remaining_slots': (raceData['capacity'] - raceData['booked_count'] - 1),
        'user_id': userId,
      },
    };
    publish(bookingCreateTopic, payload);
  }

  void sendBookingCancel(int bookingId, int? userId) {
    final payload = {
      'action': 'ticketcancellation',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'booking_id': bookingId,
        'user_id': userId,
        'status': 'cancelled_by_user'
      },
    };
    publish(bookingCancelTopic, payload);
  }
}
