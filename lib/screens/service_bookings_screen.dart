import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meta_race_provider.dart';

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
    final availableRaces = provider.slots.where((s) => !s.isBooked).toList();

    return Container(
      color: const Color(0xFF121212), // Deep black background
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: availableRaces.length,
        itemBuilder: (context, index) {
          final race = availableRaces[index];
          return Card(
            color: const Color(0xFF1E1E1E),
            elevation: 10,
            margin: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.redAccent, width: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(20),
              leading: const Icon(Icons.speed, color: Colors.redAccent, size: 45),
              title: Text(
                race.trackName?.toUpperCase() ?? "UNKNOWN TRACK",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text("VEHICLE: ${race.carModel}", style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text("SESSION: ${race.timeLabel}", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () async {
                  final success = await provider.bookSlot(race.id!);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.redAccent,
                        content: Text('GRID ENTRY CONFIRMED - START YOUR ENGINES'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("JOIN GRID", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMyBookingsTab() {
    final provider = Provider.of<MetaRaceProvider>(context);
    final user = provider.currentUser;
    final myBookings = provider.slots.where((s) => s.bookedById == user?.id).toList();

    return Container(
      color: const Color(0xFF121212),
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
            child: myBookings.isEmpty
                ? const Center(child: Text('NO ACTIVE TICKETS IN YOUR GRID', style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: myBookings.length,
                    itemBuilder: (context, index) {
                      final slot = myBookings[index];
                      return Card(
                        color: const Color(0xFF1E1E1E),
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
                            slot.trackName?.toUpperCase() ?? "UNKNOWN TRACK",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "VEHICLE: ${slot.carModel}\nTIME: ${slot.timeLabel}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () async {
                              final success = await provider.cancelBooking(slot.id!);
                              if (mounted && success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: Colors.grey,
                                    content: Text('GRID EXIT CONFIRMED'),
                                  ),
                                );
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
