import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meta_race_provider.dart';
import 'service_bookings_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  void _handleLogout() {
    Provider.of<MetaRaceProvider>(context, listen: false).logout();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MetaRaceProvider>(context);
    final user = provider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meta Race Dashboard'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF0D47A1),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome Back,', style: TextStyle(color: Colors.white70, fontSize: 16)),
                Text(
                  user?.username ?? 'Racer',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Manage your race services from here.',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 2, // 2 items per row
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.0, // This makes them PERFECT SQUARES
                children: [
                  _buildSquareServiceCard(
                    context,
                    title: "GRID ENTRY",
                    subtitle: "Book your race",
                    icon: Icons.speed,
                    color: Colors.redAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ServiceBookingsScreen()),
                      );
                    },
                  ),
                  _buildSquareServiceCard(
                    context,
                    title: "BOOKINGS",
                    subtitle: "View history",
                    icon: Icons.calendar_today,
                    color: Colors.blueAccent,
                    onTap: () {},
                  ),
                  _buildSquareServiceCard(
                    context,
                    title: "MY CARS",
                    subtitle: "Manage fleet",
                    icon: Icons.directions_car,
                    color: Colors.orangeAccent,
                    onTap: () {},
                  ),
                  _buildSquareServiceCard(
                    context,
                    title: "SETTINGS",
                    subtitle: "App config",
                    icon: Icons.settings,
                    color: Colors.grey,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
          // Logout Option at Bottom
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('LOGOUT SESSION', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareServiceCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
