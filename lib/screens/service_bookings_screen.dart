import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/meta_race_provider.dart';
import '../models/booking.dart';

class ServiceBookingsScreen extends StatefulWidget {
  const ServiceBookingsScreen({super.key});

  @override
  State<ServiceBookingsScreen> createState() => _ServiceBookingsScreenState();
}

class _ServiceBookingsScreenState extends State<ServiceBookingsScreen> {
  late StreamSubscription _cancelSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<MetaRaceProvider>(context, listen: false);
      provider.fetchBookings();
    });

    final provider = Provider.of<MetaRaceProvider>(context, listen: false);
    _cancelSub = provider.mqttService.onBookingCancelAck.listen((data) {
      if (!mounted) return;
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('BOOKING CANCELLED'),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _cancelSub.cancel();
    super.dispose();
  }

  /// Convert a 24h time slot value like "09:00" to a friendly label like "09:00 AM - 10:00 AM"
  String _formatSlotLabel(String slotValue) {
    try {
      final parts = slotValue.split(':');
      final hour = int.parse(parts[0]);
      final startFormatted = DateFormat(
        'hh:mm a',
      ).format(DateTime(2000, 1, 1, hour));
      final endFormatted = DateFormat(
        'hh:mm a',
      ).format(DateTime(2000, 1, 1, hour + 1));
      return '$startFormatted - $endFormatted';
    } catch (_) {
      return slotValue;
    }
  }

  /// Parse the start time from a slot like "09:00" (24h format)
  /// combined with the booking date to get a full DateTime.
  DateTime? _getRideStartTime(Booking booking) {
    try {
      final date = DateFormat('yyyy-MM-dd').parse(booking.date);
      final parts = booking.timeSlot.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  /// Returns true if cancellation is still allowed (>= 30 min before ride start)
  bool _canCancel(Booking booking) {
    final rideStart = _getRideStartTime(booking);
    if (rideStart == null) return false;
    final now = DateTime.now();
    final cutoff = rideStart.subtract(const Duration(minutes: 30));
    return now.isBefore(cutoff);
  }

  /// Friendly string showing how much time is left to cancel
  String _cancelWindowText(Booking booking) {
    final rideStart = _getRideStartTime(booking);
    if (rideStart == null) return '';
    final cutoff = rideStart.subtract(const Duration(minutes: 30));
    final now = DateTime.now();
    if (now.isAfter(cutoff)) return 'Cancellation window closed';
    final diff = cutoff.difference(now);
    if (diff.inDays > 0) {
      return 'Cancel available for ${diff.inDays}d ${diff.inHours % 24}h';
    } else if (diff.inHours > 0) {
      return 'Cancel available for ${diff.inHours}h ${diff.inMinutes % 60}m';
    } else {
      return 'Cancel available for ${diff.inMinutes}m';
    }
  }

  void _showBookingDetail(Booking booking, int bookingIndex) {
    final isActive = booking.status == 'confirmed';
    final canCancel = isActive && _canCancel(booking);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking.experience.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.redAccent.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      booking.status.toUpperCase(),
                      style: TextStyle(
                        color: isActive ? Colors.redAccent : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(color: Colors.white12),
              const SizedBox(height: 12),

              // Booking details
              _detailRow(Icons.person, 'Name', booking.name),
              _detailRow(Icons.email, 'Email', booking.email),
              if (booking.phone.isNotEmpty)
                _detailRow(Icons.phone, 'Phone', booking.phone),
              _detailRow(Icons.star, 'Plan', booking.plan.toUpperCase()),
              _detailRow(Icons.calendar_today, 'Date', booking.date),
              if (booking.timeSlot.isNotEmpty)
                _detailRow(
                  Icons.access_time,
                  'Time Slot',
                  _formatSlotLabel(booking.timeSlot),
                ),
              _detailRow(Icons.group, 'Guests', booking.guests.toString()),
              if (booking.message.isNotEmpty)
                _detailRow(Icons.message, 'Message', booking.message),

              // Cancel section for active bookings
              if (isActive) ...[
                const SizedBox(height: 20),
                const Divider(color: Colors.white12),
                const SizedBox(height: 12),

                // Cancel window info
                Row(
                  children: [
                    Icon(
                      canCancel ? Icons.timer : Icons.timer_off,
                      color: canCancel ? Colors.orangeAccent : Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _cancelWindowText(booking),
                      style: TextStyle(
                        color: canCancel ? Colors.orangeAccent : Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Cancel button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: canCancel
                        ? () => _confirmCancel(sheetContext, bookingIndex)
                        : null,
                    icon: Icon(
                      Icons.cancel,
                      color: canCancel ? Colors.white : Colors.grey,
                    ),
                    label: Text(
                      canCancel ? 'CANCEL RIDE' : 'CANCELLATION NOT AVAILABLE',
                      style: TextStyle(
                        color: canCancel ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canCancel
                          ? Colors.red
                          : const Color(0xFF2A2A2A),
                      disabledBackgroundColor: const Color(0xFF2A2A2A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                if (!canCancel)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Rides can only be cancelled 30 minutes before start time.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _confirmCancel(BuildContext sheetContext, int bookingIndex) {
    showDialog(
      context: sheetContext,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'CANCEL RIDE?',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to cancel this ride? This action cannot be undone.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'NO, KEEP IT',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final provider = Provider.of<MetaRaceProvider>(
                  context,
                  listen: false,
                );
                provider.cancelBookingByIndex(bookingIndex);
                Navigator.pop(dialogContext); // close dialog
                Navigator.pop(sheetContext); // close bottom sheet
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.redAccent,
                    content: Text('RIDE CANCELLED'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'YES, CANCEL',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.redAccent, size: 18),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MetaRaceProvider>(context);
    final bookings = provider.bookings;
    final confirmed = <MapEntry<int, Booking>>[];
    final cancelled = <MapEntry<int, Booking>>[];

    for (int i = 0; i < bookings.length; i++) {
      if (bookings[i].status == 'confirmed') {
        confirmed.add(MapEntry(i, bookings[i]));
      } else if (bookings[i].status == 'cancelled') {
        cancelled.add(MapEntry(i, bookings[i]));
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('MY BOOKINGS'),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.redAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.fetchBookings(),
          ),
        ],
      ),
      body: bookings.isEmpty
          ? const Center(
              child: Text(
                'NO BOOKINGS YET',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (confirmed.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'ACTIVE BOOKINGS',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ...confirmed.map((e) => _buildBookingCard(e.value, e.key)),
                ],
                if (cancelled.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 20, bottom: 8),
                    child: Text(
                      'CANCELLED',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ...cancelled.map((e) => _buildBookingCard(e.value, e.key)),
                ],
              ],
            ),
    );
  }

  Widget _buildBookingCard(Booking booking, int index) {
    final isActive = booking.status == 'confirmed';
    final borderColor = isActive ? Colors.redAccent : Colors.grey;

    return GestureDetector(
      onTap: () => _showBookingDetail(booking, index),
      child: Card(
        color: const Color(0xFF1E1E1E),
        elevation: 5,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderColor, width: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking.experience.toUpperCase(),
                    style: TextStyle(
                      color: borderColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.redAccent.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      booking.status.toUpperCase(),
                      style: TextStyle(
                        color: borderColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _infoRow(Icons.star, 'Plan: ${booking.plan.toUpperCase()}'),
              _infoRow(Icons.calendar_today, 'Date: ${booking.date}'),
              if (booking.timeSlot.isNotEmpty)
                _infoRow(
                  Icons.access_time,
                  'Time: ${_formatSlotLabel(booking.timeSlot)}',
                ),
              _infoRow(Icons.group, 'Guests: ${booking.guests}'),
              // Tap hint
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Tap for details',
                      style: TextStyle(color: Colors.white24, fontSize: 11),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: Colors.white24, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
