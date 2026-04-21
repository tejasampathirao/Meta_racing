import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  late MqttServerClient client;
  final String server = '192.168.0.193';
  final String clientId =
      'meta_race_client_${DateTime.now().millisecondsSinceEpoch}';

  bool _isListening = false;
  bool _isReconnecting = false;

  // Publish topics (app → server)
  static const String topicRegister = 'metarace/auth/register';
  static const String topicLogin = 'metarace/auth/login';
  static const String topicLogout = 'metarace/auth/logout';
  static const String topicBookingCreate = 'metarace/bookings/ticketbooking';
  static const String topicBookingCancel =
      'metarace/bookings/ticketcancellation';
  static const String topicBookingView = 'metarace/bookings/viewbookings';

  // Subscribe topics (server → app)
  static const String topicRegisterAck = 'metarace/auth/register/ack';
  static const String topicLoginAck = 'metarace/auth/login/ack';
  static const String topicLogoutAck = 'metarace/auth/logout/ack';
  static const String topicBookingCreateAck =
      'metarace/bookings/ticketbooking/ack';
  static const String topicBookingCancelAck =
      'metarace/bookings/ticketcancellation/ack';
  static const String topicBookingViewAck =
      'metarace/bookings/viewbookings/ack';

  // Stream controllers for ack responses
  final _registerAckController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _loginAckController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _logoutAckController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _bookingCreateAckController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _bookingCancelAckController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _bookingViewAckController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onRegisterAck =>
      _registerAckController.stream;
  Stream<Map<String, dynamic>> get onLoginAck => _loginAckController.stream;
  Stream<Map<String, dynamic>> get onLogoutAck => _logoutAckController.stream;
  Stream<Map<String, dynamic>> get onBookingCreateAck =>
      _bookingCreateAckController.stream;
  Stream<Map<String, dynamic>> get onBookingCancelAck =>
      _bookingCancelAckController.stream;
  Stream<Map<String, dynamic>> get onBookingViewAck =>
      _bookingViewAckController.stream;

  MqttService() {
    client = MqttServerClient(server, clientId);
    client.port = 1883;
    client.logging(on: false);
    client.keepAlivePeriod = 20;

    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;
  }

  Future<bool> connect() async {
    try {
      print('MQTT: Connecting to $server...');
      await client.connect();
      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        _subscribeToAckTopics();
        if (!_isListening) {
          _listenForMessages();
          _isListening = true;
        }
        return true;
      }
      return false;
    } catch (e) {
      print('MQTT: Connection failed - $e');
      client.disconnect();
      return false;
    }
  }

  void _subscribeToAckTopics() {
    final ackTopics = [
      topicRegisterAck,
      topicLoginAck,
      topicLogoutAck,
      topicBookingCreateAck,
      topicBookingCancelAck,
      topicBookingViewAck,
    ];
    for (final topic in ackTopics) {
      client.subscribe(topic, MqttQos.atLeastOnce);
    }
  }

  void _listenForMessages() {
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (final msg in messages) {
        final payload = msg.payload as MqttPublishMessage;
        final jsonStr = MqttPublishPayload.bytesToStringAsString(
          payload.payload.message,
        );
        try {
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          print('MQTT: Received on ${msg.topic}: $jsonStr');
          _routeMessage(msg.topic, data);
        } catch (e) {
          print('MQTT: Failed to parse message on ${msg.topic}: $e');
        }
      }
    });
  }

  void _routeMessage(String topic, Map<String, dynamic> data) {
    switch (topic) {
      case topicRegisterAck:
        _registerAckController.add(data);
        break;
      case topicLoginAck:
        _loginAckController.add(data);
        break;
      case topicLogoutAck:
        _logoutAckController.add(data);
        break;
      case topicBookingCreateAck:
        _bookingCreateAckController.add(data);
        break;
      case topicBookingCancelAck:
        _bookingCancelAckController.add(data);
        break;
      case topicBookingViewAck:
        _bookingViewAckController.add(data);
        break;
    }
  }

  void _onConnected() {
    print('MQTT: Connected to $server');
  }

  void _onDisconnected() {
    print('MQTT: Disconnected from broker');
    _isListening = false;
    _attemptReconnect();
  }

  void _onSubscribed(String topic) {
    print('MQTT: Subscribed to $topic');
  }

  void _attemptReconnect() {
    if (_isReconnecting) return;
    _isReconnecting = true;
    print('MQTT: Attempting reconnect in 3 seconds...');
    Future.delayed(const Duration(seconds: 3), () async {
      _isReconnecting = false;
      final connected = await connect();
      if (!connected) {
        print('MQTT: Reconnect failed, will retry on next publish');
      }
    });
  }

  void _publish(String topic, Map<String, dynamic> payload) {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(jsonEncode(payload));
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      print('MQTT: Published to $topic: ${jsonEncode(payload)}');
    } else {
      print('MQTT: Not connected, attempting reconnect...');
      connect().then((connected) {
        if (connected) {
          final builder = MqttClientPayloadBuilder();
          builder.addString(jsonEncode(payload));
          client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
          print('MQTT: Published to $topic after reconnect');
        } else {
          print('MQTT: Publish failed - could not reconnect');
        }
      });
    }
  }

  // ── Auth methods ──

  void sendRegisterPayload(
    String name,
    String email,
    String phone,
    String password, {
    String role = 'user',
  }) {
    _publish(topicRegister, {
      'action': 'register',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'name': name,
        'email_id': email,
        'phone': phone,
        'password': password,
        'role': role,
      },
    });
  }

  void sendLoginPayload(String email, String password, {String role = 'user'}) {
    _publish(topicLogin, {
      'action': 'login',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {'email_id': email, 'password': password, 'role': role},
    });
  }

  void sendLogoutPayload(int userId) {
    _publish(topicLogout, {
      'action': 'logout',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {'user_id': userId},
    });
  }

  // ── Booking methods ──

  void sendBookingCreate({
    required String name,
    required String email,
    String phone = '',
    required String experience,
    required String plan,
    required String date,
    String timeSlot = '',
    required int guests,
    String message = '',
    int? customerId,
  }) {
    _publish(topicBookingCreate, {
      'action': 'booking_create',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'name': name,
        'email_id': email,
        'phone': phone,
        'experience': experience,
        'time_slot': timeSlot,
        'plan': plan,
        'date': date,
        'guests': guests,
        'message': message,
        'customer_id': customerId,
      },
    });
  }

  void sendBookingCancel(int bookingId) {
    _publish(topicBookingCancel, {
      'action': 'booking_cancel',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {'booking_id': bookingId},
    });
  }

  void sendViewBookings(int customerId) {
    _publish(topicBookingView, {
      'action': 'view_bookings',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {'customer_id': customerId},
    });
  }

  void dispose() {
    _isListening = false;
    _registerAckController.close();
    _loginAckController.close();
    _logoutAckController.close();
    _bookingCreateAckController.close();
    _bookingCancelAckController.close();
    _bookingViewAckController.close();
    client.disconnect();
  }
}
