import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meta_race_provider.dart';
import '../models/slot.dart';

class ServiceBookingsScreen extends StatefulWidget {
  const ServiceBookingsScreen({super.key});

  @override
  State<ServiceBookingsScreen> createState() => _ServiceBookingsScreenState();
}

class _ServiceBookingsScreenState extends State<ServiceBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MetaRaceProvider>(context, listen: false).fetchSlots();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showRaceDetails(BuildContext context, Slot slot) {
    final nameController = TextEditingController();
    final dateController = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    final provider = Provider.of<MetaRaceProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("RACE DETAILS", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Driver Name",
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
              ),
            ),
            TextField(
              controller: dateController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Race Date (YYYY-MM-DD)",
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TRACK: ${slot.trackName}", style: const TextStyle(color: Colors.white70)),
                  Text("TIME: ${slot.timeLabel}", style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const Divider(color: Colors.grey),
            Text(
              "AVAILABILITY AFTER BOOKING: ${slot.capacity - slot.bookedCount - 1} SLOTS",
              style: const TextStyle(color: Colors.green, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("EXIT", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final success = await provider.confirmBooking(slot.id!, nameController.text, dateController.text);
                if (success) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("RACE BOOKED!")));
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter Driver Name")));
              }
            },
            child: const Text("CONFIRM GRID ENTRY", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('SERVICE BOOKINGS'),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.redAccent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.speed), text: 'AVAILABLE GRID'),
            Tab(icon: Icon(Icons.flag), text: 'MY GRID'),
          ],
          indicatorColor: Colors.redAccent,
          labelColor: Colors.redAccent,
          unselectedLabelColor: Colors.white54,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableSlotsTab(),
          _buildMyBookingsTab(),
        ],
      ),
    );
  }

  Widget _buildAvailableSlotsTab() {
    final provider = Provider.of<MetaRaceProvider>(context);

    return Container(
      color: const Color(0xFF121212),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: provider.slots.length,
        itemBuilder: (context, index) {
          final shift = provider.slots[index];
          final isFull = shift.bookedCount >= shift.capacity;
          final isAlreadyBookedByMe = shift.isBooked;

          return Card(
            color: const Color(0xFF1E1E1E),
            elevation: 10,
            margin: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: isFull ? Colors.grey : Colors.redAccent, width: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(20),
              leading: Icon(Icons.speed, color: isFull ? Colors.grey : Colors.redAccent, size: 45),
              title: Text(
                shift.timeLabel,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    "Availability: ${shift.capacity - shift.bookedCount} / ${shift.capacity} Slots Left",
                    style: TextStyle(
                      color: isFull ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text("TRACK: ${shift.trackName}", style: const TextStyle(color: Colors.white70)),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: (isFull || isAlreadyBookedByMe)
                    ? null 
                    : () => _showRaceDetails(context, shift),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAlreadyBookedByMe ? Colors.blue : Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  isAlreadyBookedByMe ? "BOOKED" : (isFull ? "FULL" : "BOOK"),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMyBookingsTab() {
    final provider = Provider.of<MetaRaceProvider>(context);
    final myRaces = provider.slots.where((s) => s.bookedById == provider.currentUser?.id).toList();

    return Container(
      color: Colors.black,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'ACTIVE RACE TICKETS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
            ),
          ),
          Expanded(
            child: myRaces.isEmpty
                ? const Center(child: Text('NO ACTIVE TICKETS', style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: myRaces.length,
                    itemBuilder: (context, index) {
                      final race = myRaces[index];
                      return Card(
                        color: Colors.grey[900],
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Colors.blueAccent, width: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: const Icon(Icons.confirmation_number, color: Colors.blueAccent, size: 40),
                          title: Text(
                            race.trackName?.toUpperCase() ?? "UNKNOWN TRACK",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "TIME: ${race.timeLabel}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: TextButton.icon(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            label: const Text("CANCEL RIDE", style: TextStyle(color: Colors.red)),
                            onPressed: () async {
                              final success = await provider.cancelBooking(race.id!);
                              if (success) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("RACE CANCELLED")));
                                }
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
