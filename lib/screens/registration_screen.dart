import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/meta_race_provider.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _nameController = TextEditingController();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "JOIN THE RACE",
                      style: GoogleFonts.russoOne(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 30),

                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Column(
                        children: [
                          _buildTextField("Full Name", Icons.person_outline, controller: _nameController),
                          const SizedBox(height: 15),
                          _buildTextField("Email or Phone Number", Icons.contact_mail_outlined, controller: _identifierController),
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
                          const SizedBox(height: 15),
                          _buildTextField("Confirm Password", Icons.lock_reset,
                              controller: _confirmPasswordController,
                              isPassword: true,
                              obscureText: _obscurePassword),
                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_passwordController.text != _confirmPasswordController.text) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Passwords do not match')),
                                  );
                                  return;
                                }
                                final success = await Provider.of<MetaRaceProvider>(context, listen: false).register(
                                  _nameController.text,
                                  _identifierController.text,
                                  _passwordController.text,
                                );
                                if (!mounted) return;
                                if (success) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Account Created! Please login.')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D47A1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text("REGISTER", style: TextStyle(color: Colors.white, fontSize: 18)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
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
