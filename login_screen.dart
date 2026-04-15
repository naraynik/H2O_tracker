
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoginMode = false;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitForm() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    // 1. Compulsory Field Verification
    if (email.isEmpty || pass.isEmpty) {
      _showError('Email and Password are required fields.');
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showError('Please enter a valid email address.');
      return;
    }
    if (!_isLoginMode && name.isEmpty) {
      _showError('Full Name is required for Sign Up.');
      return;
    }

    final dbHelper = DatabaseHelper();

    if (_isLoginMode) {
      // LOG IN LOGIC
      final existingUser = await dbHelper.getUserByEmail(email);
      if (existingUser == null) {
        _showError('Account not found. Please Sign Up.');
        return;
      }
      
      if (existingUser['password'] != pass) {
        _showError('Incorrect password! Try again.');
        return;
      }

      // Login Success!
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('logged_in_email', email);
      
      // Load stats back into preferences!
      if (existingUser['name'] != null) {
        await prefs.setString('user_name', existingUser['name'].toString());
      }
      if (existingUser['weight'] != null) {
        await prefs.setString('user_weight', existingUser['weight'].toString());
      }
      if (existingUser['height'] != null) {
        await prefs.setString('user_height', existingUser['height'].toString());
      }
      if (existingUser['age'] != null) {
        await prefs.setString('user_age', existingUser['age'].toString());
      }
      if (existingUser['daily_goal'] != null) {
        await prefs.setInt('daily_goal', existingUser['daily_goal'] as int);
      }
      
      // Load historic water logs to calculate today's intake dynamically
      final historicLogs = await dbHelper.getWaterLogs(email);
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      
      List<String> formattedHistory = [];
      int todayTotal = 0;
      
      for (var log in historicLogs) {
        final amount = log['amount'] as int;
        final timestamp = log['timestamp'] as String;
        formattedHistory.add('$timestamp|$amount');
        
        if (timestamp.startsWith(todayStr)) {
          todayTotal += amount;
        }
      }
      
      await prefs.setStringList('intake_history', formattedHistory);
      
      // Cap today total if it exceeds the user's fetched daily goal 
      final currentGoal = existingUser['daily_goal'] as int? ?? 1800;
      if (todayTotal > currentGoal) {
        todayTotal = currentGoal;
      }
      
      await prefs.setInt('current_intake', todayTotal);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
      
    } else {
      // SIGN UP LOGIC
      final existingUser = await dbHelper.getUserByEmail(email);
      if (existingUser != null) {
        _showError('This email is already registered!');
        return;
      }

      // Save to database
      await dbHelper.insertUser({
        'email': email,
        'name': name,
        'password': pass,
      });

      // Also remember logged in user
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('logged_in_email', email);
      await prefs.setString('user_name', name);

      // Successfully registered
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/persona');
    }
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      // Clear fields when swapping modes
      _nameCtrl.clear();
      _emailCtrl.clear();
      _passCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E313B),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Logo
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E313B),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.water_drop_outlined,
                      size: 50,
                      color: Color(0xFF00E5FF),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // App Title
              const Center(
                child: Text(
                  'H2O Tracker',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(color: Color(0xFF00E5FF), offset: Offset(-1.5, 0)),
                      Shadow(color: Colors.redAccent, offset: Offset(1.5, 0)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              Center(
                child: Text(
                  _isLoginMode ? 'WELCOME BACK' : 'JOIN THE HYDRATION FLOW',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              // Form Card
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF24363F),
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_isLoginMode) ...[
                      _buildTextField(
                        label: 'Full Name',
                        icon: Icons.person_outline,
                        controller: _nameCtrl,
                      ),
                      const SizedBox(height: 20),
                    ],
                    _buildTextField(
                      label: 'Email',
                      icon: Icons.mail_outline,
                      controller: _emailCtrl,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: true,
                      controller: _passCtrl,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                      ),
                      child: Text(
                        _isLoginMode ? 'LOGIN' : 'CREATE ACCOUNT',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Bottom Toggle Mode
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLoginMode ? "DON'T HAVE AN ACCOUNT? " : 'ALREADY HAVE AN ACCOUNT? ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleMode,
                    child: Text(
                      _isLoginMode ? 'SIGN UP' : 'LOG IN',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF00E5FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E313B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
          prefixIcon: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.4),
            size: 22,
          ),
        ),
      ),
    );
  }
}
