class Slot {
  final int? id;
  final String timeLabel;
  final String? trackName;
  final String? carModel;
  final int capacity;     // Non-nullable
  final int bookedCount;  // Non-nullable
  final bool isBooked;
  final int? bookedById;

  Slot({
    this.id,
    required this.timeLabel,
    this.trackName,
    this.carModel,
    this.capacity = 3,
    this.bookedCount = 0,
    this.isBooked = false,
    this.bookedById,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time_label': timeLabel,
      'track_name': trackName,
      'car_model': carModel,
      'capacity': capacity,
      'booked_count': bookedCount,
      'is_booked': isBooked ? 1 : 0,
      'booked_by_id': bookedById,
    };
  }

  factory Slot.fromMap(Map<String, dynamic> map) {
    return Slot(
      id: map['id'],
      timeLabel: map['time_label'] ?? 'Unknown Time',
      trackName: map['track_name'],
      carModel: map['car_model'],
      // Use the ?? operator to provide defaults if the DB returns null
      capacity: map['capacity'] ?? 3, 
      bookedCount: map['booked_count'] ?? 0,
      isBooked: map['is_booked'] == 1,
      bookedById: map['booked_by_id'],
    );
  }
}
