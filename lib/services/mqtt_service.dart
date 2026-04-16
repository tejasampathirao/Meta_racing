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

  Future<bool> connect() async {
    try {
      print('MQTT: Connecting to $server...');
      await client.connect();
      return client.connectionStatus?.state == MqttConnectionState.connected;
    } catch (e) {
      print('MQTT: Connection failed - $e');
      client.disconnect();
      return false;
    }
  }

  void _onConnected() {
    print('MQTT: Connected Successfully');
  }

  void _onDisconnected() {
    print('MQTT: Disconnected from Broker');
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
}
