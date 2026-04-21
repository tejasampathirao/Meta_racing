import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/meta_race_provider.dart';

class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({super.key});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  String _selectedExperience = 'sim';
  String _selectedPlan = 'starter';
  DateTime? _selectedDate;
  final _guestsController = TextEditingController(text: '1');
  final _messageController = TextEditingController();

  static const experiences = [
    {'value': 'sim', 'label': 'Sim Racing'},
    {'value': 'fpv', 'label': 'FPV Drone'},
    {'value': 'both', 'label': 'Both'},
  ];

  static const plans = [
    {'value': 'starter', 'label': 'Starter'},
    {'value': 'racer', 'label': 'Racer'},
    {'value': 'champion', 'label': 'Champion'},
    {'value': 'squad', 'label': 'Squad'},
  ];

  static const int maxSlotsPerTimeRange = 5;

  static const List<Map<String, String>> timeSlots = [
    {'value': '09:00', 'label': '09:00 AM - 10:00 AM'},
    {'value': '10:00', 'label': '10:00 AM - 11:00 AM'},
    {'value': '11:00', 'label': '11:00 AM - 12:00 PM'},
    {'value': '12:00', 'label': '12:00 PM - 01:00 PM'},
    {'value': '13:00', 'label': '01:00 PM - 02:00 PM'},
    {'value': '14:00', 'label': '02:00 PM - 03:00 PM'},
    {'value': '15:00', 'label': '03:00 PM - 04:00 PM'},
    {'value': '16:00', 'label': '04:00 PM - 05:00 PM'},
    {'value': '17:00', 'label': '05:00 PM - 06:00 PM'},
    {'value': '18:00', 'label': '06:00 PM - 07:00 PM'},
    {'value': '19:00', 'label': '07:00 PM - 08:00 PM'},
    {'value': '20:00', 'label': '08:00 PM - 09:00 PM'},
  ];

  /// Return only slots that are still in the future if the selected date is today.
  List<Map<String, String>> _getAvailableSlots() {
    if (_selectedDate == null) return timeSlots;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
    );
    if (selected.isAfter(today)) return timeSlots;
    // Selected date is today — filter out slots whose start time has passed
    return timeSlots.where((slot) {
      final parts = slot['value']!.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final slotStart = DateTime(now.year, now.month, now.day, hour, minute);
      return slotStart.isAfter(now);
    }).toList();
  }

  /// Count how many confirmed bookings exist for a given date + time slot
  int _getBookedCount(String dateStr, String timeSlot) {
    final provider = Provider.of<MetaRaceProvider>(context, listen: false);
    return provider.bookings
        .where(
          (b) =>
              b.status == 'confirmed' &&
              b.date == dateStr &&
              b.timeSlot == timeSlot,
        )
        .length;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.redAccent,
              surface: Color(0xFF1E1E1E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showBookingDialog(String slotValue, String slotLabel, String dateStr) {
    final provider = Provider.of<MetaRaceProvider>(context, listen: false);
    final user = provider.currentUser;
    _guestsController.text = '1';
    _messageController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'CONFIRM BOOKING',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogInfoRow('Name', user?.name ?? 'Guest'),
                const SizedBox(height: 10),
                _dialogInfoRow(
                  'Date',
                  DateFormat('dd MMM yyyy').format(_selectedDate!),
                ),
                const SizedBox(height: 10),
                _dialogInfoRow('Time Slot', slotLabel),
                const SizedBox(height: 10),
                _dialogInfoRow('Experience', _selectedExperience.toUpperCase()),
                const SizedBox(height: 10),
                _dialogInfoRow('Plan', _selectedPlan.toUpperCase()),
                const SizedBox(height: 18),
                const Text(
                  'GUESTS',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _guestsController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '1 - 20',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(
                      Icons.group,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF121212),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'MESSAGE (OPTIONAL)',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _messageController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Any special requests...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF121212),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final guests = int.tryParse(_guestsController.text) ?? 0;
                if (guests < 1 || guests > 20) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Guests must be between 1 and 20'),
                    ),
                  );
                  return;
                }

                provider.createBooking(
                  experience: _selectedExperience,
                  plan: _selectedPlan,
                  date: dateStr,
                  timeSlot: slotValue,
                  guests: guests,
                  message: _messageController.text.trim(),
                );

                Navigator.pop(dialogContext);
                setState(() {}); // refresh slot availability
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.redAccent,
                    content: Text('BOOKING REQUEST SENT'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'BOOK NOW',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _guestsController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Widget _dialogInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
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
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          'BOOK EXPERIENCE',
          style: GoogleFonts.russoOne(fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.redAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Experience selector
            const Text(
              'EXPERIENCE',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: experiences.map((e) {
                final selected = _selectedExperience == e['value'];
                return ChoiceChip(
                  label: Text(e['label']!),
                  selected: selected,
                  selectedColor: Colors.redAccent,
                  backgroundColor: const Color(0xFF1E1E1E),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                  ),
                  onSelected: (_) =>
                      setState(() => _selectedExperience = e['value']!),
                );
              }).toList(),
            ),

            const SizedBox(height: 25),

            // Plan selector
            const Text(
              'PLAN',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: plans.map((p) {
                final selected = _selectedPlan == p['value'];
                return ChoiceChip(
                  label: Text(p['label']!),
                  selected: selected,
                  selectedColor: Colors.redAccent,
                  backgroundColor: const Color(0xFF1E1E1E),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                  ),
                  onSelected: (_) =>
                      setState(() => _selectedPlan = p['value']!),
                );
              }).toList(),
            ),

            const SizedBox(height: 25),

            // Date picker
            const Text(
              'DATE',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.redAccent),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate != null
                          ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                          : 'Select a date',
                      style: TextStyle(
                        color: _selectedDate != null
                            ? Colors.white
                            : Colors.white38,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Time slots (shown after date is selected)
            if (_selectedDate != null) ...[
              const SizedBox(height: 25),
              const Text(
                'TIME SLOT',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap a slot to book',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 10),
              if (_getAvailableSlots().isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Text(
                    'No slots available for today. Please select a future date.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ),
              ..._getAvailableSlots().map((slot) {
                final slotValue = slot['value']!;
                final slotLabel = slot['label']!;
                final booked = _getBookedCount(dateStr!, slotValue);
                final remaining = maxSlotsPerTimeRange - booked;
                final isFull = remaining <= 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: isFull
                          ? null
                          : () => _showBookingDialog(
                              slotValue,
                              slotLabel,
                              dateStr!,
                            ),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFull
                                ? Colors.grey.withValues(alpha: 0.3)
                                : Colors.white24,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: isFull ? Colors.grey : Colors.redAccent,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                slotLabel,
                                style: TextStyle(
                                  color: isFull ? Colors.grey : Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isFull
                                    ? Colors.red.withValues(alpha: 0.2)
                                    : Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isFull
                                    ? 'FULL'
                                    : '$remaining / $maxSlotsPerTimeRange',
                                style: TextStyle(
                                  color: isFull
                                      ? Colors.redAccent
                                      : Colors.greenAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
