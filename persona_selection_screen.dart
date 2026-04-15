import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';

class PersonaSelectionScreen extends StatefulWidget {
  const PersonaSelectionScreen({super.key});

  @override
  State<PersonaSelectionScreen> createState() => _PersonaSelectionScreenState();
}

class _PersonaSelectionScreenState extends State<PersonaSelectionScreen> {
  int _selectedActivityIndex = 0;

  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _heightCtrl = TextEditingController();
  final TextEditingController _ageCtrl = TextEditingController();

  final List<Map<String, dynamic>> _activities = [
    {'title': 'SEDENTARY', 'icon': Icons.chair_alt, 'offset': 0, 'color': const Color(0xFFFFB74D)},
    {'title': 'STUDENT', 'icon': Icons.menu_book, 'offset': 0, 'color': const Color(0xFF64B5F6)},
    {'title': 'GYM', 'icon': Icons.fitness_center, 'offset': 750, 'color': const Color(0xFFE57373)},
    {'title': 'ATHLETE', 'icon': Icons.directions_run, 'offset': 1000, 'color': const Color(0xFF81C784)},
    {'title': 'OUTDOOR WORKER', 'icon': Icons.wb_sunny, 'offset': 500, 'color': const Color(0xFFFFD54F)},
    {'title': 'OFFICE', 'icon': Icons.business_center, 'offset': 0, 'color': const Color(0xFFBA68C8)},
  ];

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  // NEW: Dynamic Calculation Helper
  int _calculateCurrentGoal() {
    final weight = int.tryParse(_weightCtrl.text) ?? 0;
    final offset = _activities[_selectedActivityIndex]['offset'] as int;
    
    // Logic: (Weight * 35ml) + Activity Offset
    if (weight < 20) return 0 + offset; // Show baseline if weight isn't valid yet
    return (weight * 35) + offset;
  }

  Future<void> _startTracking() async {
    final weight = int.tryParse(_weightCtrl.text);
    final height = int.tryParse(_heightCtrl.text);
    final age = int.tryParse(_ageCtrl.text);

    // Biometric Constraints Check
    if (weight == null || weight < 20 || weight > 300 ||
        height == null || height < 50 || height > 300 ||
        age == null || age < 5 || age > 120) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid stats (Weight: 20-300kg, Height: 50-300cm, Age: 5-120yrs)'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final goal = _calculateCurrentGoal();
    final offset = _activities[_selectedActivityIndex]['offset'] as int;
    final prefs = await SharedPreferences.getInstance();
    
    final loggedInEmail = prefs.getString('logged_in_email');
    if (loggedInEmail != null) {
      await DatabaseHelper().updateUserPhysicalStats(loggedInEmail, {
        'weight': weight,
        'height': height,
        'age': age,
        'daily_goal': goal,
      });
    }

    await prefs.setInt('daily_goal', goal);
    await prefs.setInt('activity_offset', offset);
    await prefs.setString('user_weight', _weightCtrl.text);
    await prefs.setString('user_height', _heightCtrl.text);
    await prefs.setString('user_age', _ageCtrl.text);

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E313B),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Your Persona',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(color: Color(0xFF00E5FF), offset: Offset(-1, 0)),
                          Shadow(color: Colors.redAccent, offset: Offset(1, 0)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Let\'s personalize your hydration journey',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 48),

                    const Text(
                      'PHYSICAL STATS',
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
                        Expanded(child: _buildInputBox('WEIGHT (KG)', _weightCtrl, true)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildInputBox('HEIGHT (CM)', _heightCtrl, false)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildInputBox('AGE', _ageCtrl, false)),
                      ],
                    ),
                    const SizedBox(height: 48),

                    const Text(
                      'DAILY ACTIVITY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00E5FF),
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: _activities.length,
                      itemBuilder: (context, index) {
                        return _buildActivityCard(index);
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1E313B),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF24363F),
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'DAILY WATER GOAL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00E5FF),
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${_calculateCurrentGoal()}', // FIXED: Calling helper instead of map
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ml',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ElevatedButton(
                    onPressed: _startTracking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'START TRACKING',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBox(String label, TextEditingController controller, bool triggerUpdate) {
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
              // FIXED: Added onChanged to update the goal card in real-time
              onChanged: (value) {
                if (triggerUpdate) setState(() {});
              },
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '0',
                hintStyle: TextStyle(color: Color(0xFF4C616B)),
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(int index) {
    final activity = _activities[index];
    final isSelected = _selectedActivityIndex == index;
    final activityColor = activity['color'] as Color;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedActivityIndex = index;
        });
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF24363F),
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(
                color: isSelected ? const Color(0xFF00E5FF) : Colors.white.withValues(alpha: 0.05),
                width: isSelected ? 2.0 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    activity['icon'] as IconData,
                    size: 40,
                    color: isSelected ? activityColor : activityColor.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    activity['title'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isSelected)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF00E5FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.black,
                ),
              ),
            ),
        ],
      ),
    );
  }
}