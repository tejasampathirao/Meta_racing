import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/meta_race_provider.dart';
import '../models/booking.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
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

  void _handleLogout() {
    Provider.of<MetaRaceProvider>(context, listen: false).logout();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MetaRaceProvider>(context, listen: false).fetchBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MetaRaceProvider>(context);
    final user = provider.currentUser;
    final bookings = provider.bookings;
    final confirmed = bookings.where((b) => b.status == 'confirmed').toList();
    final cancelled = bookings.where((b) => b.status == 'cancelled').toList();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('ADMIN PANEL', style: GoogleFonts.russoOne(fontSize: 18)),
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
      body: Column(
        children: [
          // Admin header
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.redAccent,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Welcome, ${user?.name ?? 'Admin'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (user?.lastLoginTime != null)
                  Text(
                    'Last login: ${_formatLoginTime(user!.lastLoginTime!)}',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                const SizedBox(height: 16),
                // Stats row
                Row(
                  children: [
                    _statCard('Total', bookings.length.toString(), Colors.blue),
                    const SizedBox(width: 12),
                    _statCard(
                      'Active',
                      confirmed.length.toString(),
                      Colors.greenAccent,
                    ),
                    const SizedBox(width: 12),
                    _statCard(
                      'Cancelled',
                      cancelled.length.toString(),
                      Colors.redAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bookings list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.list_alt, color: Colors.redAccent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'ALL BOOKINGS',
                  style: GoogleFonts.russoOne(
                    color: Colors.redAccent,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: bookings.isEmpty
                ? const Center(
                    child: Text(
                      'NO BOOKINGS YET',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      return _buildBookingCard(bookings[index]);
                    },
                  ),
          ),

          // Logout
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'LOGOUT SESSION',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final isActive = booking.status == 'confirmed';
    final borderColor = isActive ? Colors.redAccent : Colors.grey;

    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor, width: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
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
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _infoRow(Icons.email, booking.email),
            _infoRow(
              Icons.sports_esports,
              '${booking.experience.toUpperCase()} • ${booking.plan.toUpperCase()}',
            ),
            _infoRow(Icons.calendar_today, booking.date),
            if (booking.timeSlot.isNotEmpty)
              _infoRow(Icons.access_time, _formatSlotLabel(booking.timeSlot)),
            _infoRow(Icons.group, '${booking.guests} guest(s)'),
            if (booking.message.isNotEmpty)
              _infoRow(Icons.message, booking.message),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLoginTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime);
      final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day}/${dt.month}/${dt.year} $hour:$min $amPm';
    } catch (_) {
      return isoTime;
    }
  }
}
