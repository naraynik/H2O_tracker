import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _heightCtrl = TextEditingController();

  String _userName = '';
  List<Map<String, dynamic>> _weeklyData = [];
  int _maxIntake = 1; // Prevent div zero
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load existing stats
    _userName = prefs.getString('user_name') ?? 'User';
    _weightCtrl.text = prefs.getString('user_weight') ?? '';
    _heightCtrl.text = prefs.getString('user_height') ?? '';

    // Calculate Weekly Graph Data
    final savedHistory = prefs.getStringList('intake_history') ?? [];
    Map<String, int> dailyTotals = {};
    
    for (var entry in savedHistory) {
      try {
        final parts = entry.split('|');
        final dateStr = parts[0].substring(0, 10);
        final amt = int.parse(parts[1]);
        dailyTotals[dateStr] = (dailyTotals[dateStr] ?? 0) + amt;
      } catch (e) {
        // Ignore malformed entries
      }
    }

    final now = DateTime.now();
    int localMax = 0;
    List<Map<String, dynamic>> localData = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      final total = dailyTotals[dateStr] ?? 0;
      
      if (total > localMax) localMax = total;

      final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      String dayName = dayLabels[date.weekday - 1];

      localData.add({
        'day': dayName,
        'amount': total,
        'isToday': i == 0,
      });
    }

    setState(() {
      _weeklyData = localData;
      _maxIntake = localMax == 0 ? 1 : localMax; // 1 prevents division by zero
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    // Validation
    final weight = int.tryParse(_weightCtrl.text);
    final height = int.tryParse(_heightCtrl.text);

    if (weight == null || weight < 20 || weight > 300 ||
        height == null || height < 50 || height > 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter realistic stats (Weight: 20-300kg, Height: 50-300cm).'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    
    // Dynamically recalculate personalized goal based on new weight!
    final offset = prefs.getInt('activity_offset') ?? 0;
    final goal = (weight * 35) + offset;
    
    await prefs.setString('user_weight', _weightCtrl.text);
    await prefs.setString('user_height', _heightCtrl.text);
    await prefs.setInt('daily_goal', goal);

    // Save to Database
    final loggedInEmail = prefs.getString('logged_in_email');
    if (loggedInEmail != null) {
      await DatabaseHelper().updateUserPhysicalStats(loggedInEmail, {
        'weight': weight,
        'height': height,
        'daily_goal': goal,
      });
    }

    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: Color(0xFF00E5FF),
      ),
    );
    Navigator.pop(context); // Go back to dashboard
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E313B),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E313B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Color(0xFF00E5FF), size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_userName.toUpperCase()}\'S PROFILE',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00E5FF),
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Weekly Analytics',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Weekly Bar Chart
              Container(
                height: 280,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF24363F),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'LAST 7 DAYS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white54,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          'Max: $_maxIntake ml',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00E5FF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _weeklyData.map((data) {
                          double percentage = data['amount'] / _maxIntake;
                          if (percentage > 1.0) percentage = 1.0;
                          final isToday = data['isToday'] as bool;
                          
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Amount label above bar
                              Text(
                                '${data['amount']}',
                                style: TextStyle(
                                  color: isToday ? const Color(0xFF00E5FF) : Colors.white54,
                                  fontSize: 10,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Animated Bar
                              Container(
                                width: 24,
                                height: 120 * percentage,
                                decoration: BoxDecoration(
                                  color: isToday 
                                      ? const Color(0xFF00E5FF) 
                                      : const Color(0xFF00E5FF).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Day Label
                              Text(
                                data['day'],
                                style: TextStyle(
                                  color: isToday ? Colors.white : Colors.white54,
                                  fontSize: 12,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Edit Stats Section
              const Text(
                'EDIT STATS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00E5FF),
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildInputBox('WEIGHT (KG)', _weightCtrl)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInputBox('HEIGHT (CM)', _heightCtrl)),
                ],
              ),
              const SizedBox(height: 48),

              // Save Button
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'SAVE SETTINGS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBox(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF24363F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Center(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '0',
                hintStyle: TextStyle(
                  color: Color(0xFF4C616B),
                ),
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
