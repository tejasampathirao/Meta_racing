class Booking {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String experience; // sim, fpv, both
  final String plan; // starter, racer, champion, squad
  final String date;
  final String timeSlot;
  final int guests;
  final String message;
  final String status; // confirmed, cancelled
  final int? customerId;

  Booking({
    this.id,
    required this.name,
    required this.email,
    this.phone = '',
    required this.experience,
    required this.plan,
    required this.date,
    this.timeSlot = '',
    required this.guests,
    this.message = '',
    this.status = 'confirmed',
    this.customerId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'experience': experience,
      'plan': plan,
      'date': date,
      'time_slot': timeSlot,
      'guests': guests,
      'message': message,
      'status': status,
      'customer_id': customerId,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'],
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      experience: map['experience'] ?? '',
      plan: map['plan'] ?? '',
      date: map['date'] ?? '',
      timeSlot: map['time_slot'] ?? map['timeSlot'] ?? '',
      guests: map['guests'] is int
          ? map['guests']
          : int.tryParse(map['guests']?.toString() ?? '0') ?? 0,
      message: map['message'] ?? '',
      status: map['status'] ?? 'confirmed',
      customerId: map['customerId'] ?? map['customer_id'],
    );
  }
}
