class Slot {
  final int? id;
  final String timeLabel;
  final String? trackName;
  final String? carModel;
  final bool isBooked;
  final int? bookedById;

  Slot({
    this.id,
    required this.timeLabel,
    this.trackName,
    this.carModel,
    this.isBooked = false,
    this.bookedById,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time_label': timeLabel,
      'track_name': trackName,
      'car_model': carModel,
      'is_booked': isBooked ? 1 : 0,
      'booked_by_id': bookedById,
    };
  }

  factory Slot.fromMap(Map<String, dynamic> map) {
    return Slot(
      id: map['id'],
      timeLabel: map['time_label'],
      trackName: map['track_name'],
      carModel: map['car_model'],
      isBooked: map['is_booked'] == 1,
      bookedById: map['booked_by_id'],
    );
  }
}
