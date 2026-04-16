import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/meta_race_provider.dart';
import 'registration_screen.dart';
import 'booking_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. MINIMIZED BACKGROUND IMAGE
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: Opacity(
                opacity: 0.6,
                child: Image.asset(
                  'assets/meta-race.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),

          // 2. STRONGER OVERLAY
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),

          // 3. UPDATED FORM
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "META RACE",
                      style: GoogleFonts.russoOne(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 40),

                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Column(
                        children: [
                          _buildTextField("Email or Phone Number", Icons.person_outline, controller: _identifierController),
                          const SizedBox(height: 15),
                          _buildTextField("Password", Icons.lock_outline,
                              controller: _passwordController,
                              isPassword: true,
                              obscureText: _obscurePassword,
                              onToggleVisibility: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          }),
                          
                          // ADDED: Forgot Password Button
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Password reset link sent!')),
                                );
                              },
                              child: const Text(
                                "Forgot Password?",
                                style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          // LOGIN BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: () async {
                                final success = await Provider.of<MetaRaceProvider>(context, listen: false)
                                    .login(_identifierController.text, _passwordController.text);
                                if (!mounted) return;
                                if (success) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => const BookingScreen()),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Invalid credentials')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D47A1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text("LOGIN", style: TextStyle(color: Colors.white, fontSize: 18)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                        );
                      },
                      child: const Text("New here? Create Account", style: TextStyle(color: Colors.white70)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon,
      {required TextEditingController controller,
      bool isPassword = false,
      bool obscureText = false,
      VoidCallback? onToggleVisibility}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? obscureText : false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
                onPressed: onToggleVisibility,
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
      ),
    );
  }
}
