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
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureAuthPassword = true;
  bool _isAdmin = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _authPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Container(
              color: const Color(0xFF121212),
              child: Opacity(
                opacity: 0.3,
                child: Image.asset(
                  'assets/meta-race.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),

          // Form
          SafeArea(
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "JOIN THE RACE",
                              style: GoogleFonts.russoOne(
                                color: Colors.redAccent,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'CREATE YOUR ACCOUNT',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 30),

                            Container(
                              padding: const EdgeInsets.all(25),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E).withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.redAccent.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Role toggle
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF121212),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () => setState(
                                              () => _isAdmin = false,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 14,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: !_isAdmin
                                                    ? Colors.redAccent
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(11),
                                              ),
                                              child: Text(
                                                'USER',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: !_isAdmin
                                                      ? Colors.white
                                                      : Colors.white54,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () =>
                                                setState(() => _isAdmin = true),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 14,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _isAdmin
                                                    ? Colors.redAccent
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(11),
                                              ),
                                              child: Text(
                                                'ADMIN',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: _isAdmin
                                                      ? Colors.white
                                                      : Colors.white54,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildTextField(
                                    "Full Name",
                                    Icons.person_outline,
                                    controller: _nameController,
                                  ),
                                  const SizedBox(height: 15),
                                  _buildTextField(
                                    "Email",
                                    Icons.email_outlined,
                                    controller: _emailController,
                                  ),
                                  const SizedBox(height: 15),
                                  _buildTextField(
                                    "Phone Number (Optional)",
                                    Icons.phone_outlined,
                                    controller: _phoneController,
                                  ),
                                  const SizedBox(height: 15),
                                  _buildTextField(
                                    "Password",
                                    Icons.lock_outline,
                                    controller: _passwordController,
                                    isPassword: true,
                                    obscureText: _obscurePassword,
                                    onToggleVisibility: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 15),
                                  _buildTextField(
                                    "Confirm Password",
                                    Icons.lock_reset,
                                    controller: _confirmPasswordController,
                                    isPassword: true,
                                    obscureText: _obscurePassword,
                                  ),
                                  // Admin authentication password
                                  if (_isAdmin) ...[
                                    const SizedBox(height: 15),
                                    _buildTextField(
                                      "Admin Authentication Key",
                                      Icons.admin_panel_settings,
                                      controller: _authPasswordController,
                                      isPassword: true,
                                      obscureText: _obscureAuthPassword,
                                      onToggleVisibility: () {
                                        setState(() {
                                          _obscureAuthPassword =
                                              !_obscureAuthPassword;
                                        });
                                      },
                                    ),
                                  ],
                                  const SizedBox(height: 25),

                                  SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (_passwordController.text !=
                                            _confirmPasswordController.text) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Passwords do not match',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        // Validate admin auth key
                                        if (_isAdmin) {
                                          if (_authPasswordController.text
                                                  .trim() !=
                                              'admin@2025') {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                backgroundColor: Colors.red,
                                                content: Text(
                                                  'Invalid admin authentication key',
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                        }
                                        final success =
                                            await Provider.of<MetaRaceProvider>(
                                              context,
                                              listen: false,
                                            ).register(
                                              _nameController.text,
                                              _emailController.text.trim(),
                                              _phoneController.text.trim(),
                                              _passwordController.text,
                                              role: _isAdmin ? 'admin' : 'user',
                                            );
                                        if (!mounted) return;
                                        if (success) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              backgroundColor: Colors.redAccent,
                                              content: Text(
                                                'Account Created! Please login.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        _isAdmin
                                            ? "REGISTER AS ADMIN"
                                            : "REGISTER",
                                        style: GoogleFonts.russoOne(
                                          color: Colors.white,
                                          fontSize: 16,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon, {
    required TextEditingController controller,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? obscureText : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.redAccent),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white38,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        filled: true,
        fillColor: const Color(0xFF121212),
      ),
    );
  }
}
