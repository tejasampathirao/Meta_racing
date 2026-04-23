import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/meta_race_provider.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MetaRaceProvider>(context, listen: false).fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MetaRaceProvider>(context);
    final history = provider.history;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('BOOKING HISTORY'),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.blueAccent,
      ),
      body: history.isEmpty
          ? const Center(
              child: Text(
                'NO BOOKING HISTORY FOUND',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                DateTime? bookedAt;
                try {
                  bookedAt = item['booked_at'] != null ? DateTime.parse(item['booked_at']) : null;
                } catch (e) {
                  print("Date Parse Error: $e");
                }
                final formattedDate = bookedAt != null 
                    ? DateFormat('MMM dd, yyyy - hh:mm a').format(bookedAt)
                    : "Unknown Date";

                return Card(
                  color: const Color(0xFF1E1E1E),
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.blueAccent, width: 0.5),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['track_name']?.toUpperCase() ?? "TRACK",
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          ],
                        ),
                        const Divider(color: Colors.white10, height: 20),
                        _buildInfoRow(Icons.person, "DRIVER", item['driver_name'] ?? "N/A"),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.calendar_today, "RACE DATE", item['race_date'] ?? "N/A"),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.access_time, "SHIFT", item['time_label'] ?? "N/A"),
                        const Divider(color: Colors.white10, height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "Booked on: $formattedDate",
                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ],
    );
  }
}
