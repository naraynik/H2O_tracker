import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  int _currentIntake = 0;
  int _dailyGoal = 1800;
  List<String> _history = [];
  
  late AnimationController _waveController;

  final List<Map<String, dynamic>> _cupOptions = [
    {'name': 'Shot', 'amount': 150, 'icon': Icons.local_cafe},
    {'name': 'Glass', 'amount': 250, 'icon': Icons.local_drink},
    {'name': 'S Bottle', 'amount': 350, 'icon': Icons.water_drop},
    {'name': 'Bottle', 'amount': 500, 'icon': Icons.local_florist},
    {'name': 'Jug', 'amount': 750, 'icon': Icons.opacity},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentIntake = prefs.getInt('current_intake') ?? 0;
      _dailyGoal = prefs.getInt('daily_goal') ?? 1800;
      final savedHistory = prefs.getStringList('intake_history');
      
      if (savedHistory != null) {
        final today = DateTime.now().toIso8601String().substring(0, 10);
        _history = savedHistory.where((entry) => entry.startsWith(today)).toList();
      }
    });
  }

  Future<void> _addWater(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if we were already at 100% before adding
    final bool wasAlreadyAccomplished = _currentIntake >= _dailyGoal;

    final nowString = DateTime.now().toIso8601String();

    setState(() {
      _currentIntake += amount;
      if (_currentIntake > _dailyGoal) {
        _currentIntake = _dailyGoal;
      }
      _history.insert(0, '$nowString|$amount');
    });
    
    await prefs.setInt('current_intake', _currentIntake);
    await prefs.setStringList('intake_history', _history);

    final email = prefs.getString('logged_in_email');
    if (email != null) {
      await DatabaseHelper().insertWaterLog(email, amount, nowString);
    }
    
    if (!mounted) return;

    // Close bottom sheet if open
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    // Check if we just hit 100%
    if (!wasAlreadyAccomplished && _currentIntake >= _dailyGoal) {
      _showGoalAchievedDialog();
    }
  }

  void _showGoalAchievedDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF24363F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: Color(0xFF00E5FF),
                        size: 64,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'CONGRATULATIONS!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00E5FF),
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Today's target achieved!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'AWESOME!',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showAddWaterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF24363F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Quick Log',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _cupOptions.length,
                  itemBuilder: (context, index) {
                    final cup = _cupOptions[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: InkWell(
                        onTap: () => _addWater(cup['amount'] as int),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                cup['icon'] as IconData,
                                color: const Color(0xFF00E5FF),
                                size: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '+${cup['amount']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteLog(int index, StateSetter setModalState) async {
    final prefs = await SharedPreferences.getInstance();
    final parts = _history[index].split('|');
    final amount = int.parse(parts[1]);

    setState(() {
      _currentIntake -= amount;
      if (_currentIntake < 0) _currentIntake = 0;
      _history.removeAt(index);
    });

    setModalState(() {});

    await prefs.setInt('current_intake', _currentIntake);
    await prefs.setStringList('intake_history', _history);
  }

  void _showLogs() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF24363F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              height: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.history, color: Color(0xFF00E5FF), size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'History',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_currentIntake ml',
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _history.isEmpty
                        ? Center(
                            child: Text(
                              'No logs yet.',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _history.length,
                            itemBuilder: (context, index) {
                              final parts = _history[index].split('|');
                              final time = DateTime.parse(parts[0]);
                              final amount = parts[1];
                              
                              String hour = time.hour > 12 ? '${time.hour - 12}' : (time.hour == 0 ? '12' : '${time.hour}');
                              String min = time.minute.toString().padLeft(2, '0');
                              String amPm = time.hour >= 12 ? 'PM' : 'AM';
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.05),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.water_drop, size: 20, color: Color(0xFF00E5FF)),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Water', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text('$hour:$min $amPm', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                                      ],
                                    ),
                                    const Spacer(),
                                    Text('+$amount ml', style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () => _deleteLog(index, setModalState),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double rawFill = _dailyGoal > 0 ? _currentIntake / _dailyGoal : 0;
    double fillPercentage = rawFill > 1.0 ? 1.0 : rawFill;
    int remaining = _dailyGoal - _currentIntake;
    if (remaining < 0) remaining = 0;

    return Scaffold(
      backgroundColor: const Color(0xFF1E313B),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Center(
                    child: _buildCircularProgress(fillPercentage),
                  ),
                ),
                _buildMetricsCards(remaining),
                // Padding for bottom nav overlap
                const SizedBox(height: 115),
              ],
            ),
          ),
          // Custom Bottom Navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HYDRATION STATUS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00E5FF),
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Dashboard',
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
            ],
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF24363F),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.person_outline, color: Color(0xFF00E5FF)),
                  onPressed: () => Navigator.pushNamed(context, '/profile'),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF24363F),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.login_outlined, color: Colors.white54),
                  onPressed: _logout,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCircularProgress(double fillPercentage) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Find the maximum safe size for the circle. Cap it at 300.
        final size = math.min(300.0, math.min(constraints.maxWidth, constraints.maxHeight));
        
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Wave background fill
                Positioned.fill(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: fillPercentage),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    builder: (context, fillVal, child) {
                      return AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: CircularWavePainter(
                              fillPercentage: fillVal,
                              waveAnimation: _waveController.value,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                
                // Text overlay
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${(fillPercentage * 100).toInt()}',
                          style: TextStyle(
                            fontSize: size * 0.26, // Responsive text
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -2.0,
                          ),
                        ),
                        Text(
                          '%',
                          style: TextStyle(
                            fontSize: size * 0.1, // Responsive text
                            fontWeight: FontWeight.bold,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: size * 0.02),
                    Text(
                      '$_currentIntake / $_dailyGoal ML',
                      style: TextStyle(
                        fontSize: size * 0.045, // Responsive text
                        fontWeight: FontWeight.bold,
                        color: Colors.white54,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildMetricsCards(int remaining) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              title: 'REMAINING',
              amount: remaining,
              icon: Icons.water_drop_outlined,
              iconColor: const Color(0xFF00E5FF),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildMetricCard(
              title: 'GOAL',
              amount: _dailyGoal,
              icon: Icons.circle,
              iconColor: const Color(0xFF00E5FF),
              iconSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({required String title, required int amount, required IconData icon, required Color iconColor, double iconSize = 18}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: iconSize),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$amount',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'ml',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    )));
  }

  Widget _buildBottomNav() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF1B2A31),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home Tab
              Expanded(
                child: InkWell(
                  onTap: () {}, // Already on home
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.grid_view_rounded, color: Color(0xFF00E5FF), size: 28),
                      const SizedBox(height: 4),
                      Text(
                        'HOME',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00E5FF),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 80), // Space for center FAB
              // Logs Tab
              Expanded(
                child: InkWell(
                  onTap: _showLogs,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history, color: Colors.white54, size: 28),
                      const SizedBox(height: 4),
                      Text(
                        'LOGS',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white54,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Center FAB
        Positioned(
          top: -30,
          child: GestureDetector(
            onTap: _showAddWaterBottomSheet,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                size: 40,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CircularWavePainter extends CustomPainter {
  final double fillPercentage;
  final double waveAnimation;

  CircularWavePainter({
    required this.fillPercentage,
    required this.waveAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fillPercentage <= 0.0) return;

    final waterHeight = size.height * fillPercentage;
    final yOffset = size.height - waterHeight;
    
    // Dynamic Color Shift
    final Color startColor = const Color(0xFF00E5FF); // Bright vibrant cyan
    final Color endColor = const Color(0xFF005C8A);   // Deep richer blue
    final Color activeColor = Color.lerp(startColor, endColor, fillPercentage) ?? startColor;

    final paint = Paint()
      ..color = activeColor.withValues(alpha: 0.8) 
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, yOffset);

    // Wave width and height
    final double waveHeight = 6.0; 
    
    // Draw Sine Wave
    for (double i = 0.0; i <= size.width; i++) {
      path.lineTo(
        i, 
        yOffset + math.sin((i / size.width * 2 * math.pi) + (waveAnimation * 2 * math.pi)) * waveHeight
      );
    }
    
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
    
    // Add slightly brighter top layer
    final layer2Paint = Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.4);
    final path2 = Path();
    path2.moveTo(0, size.height);
    path2.lineTo(0, yOffset + waveHeight);
    
    for (double i = 0.0; i <= size.width; i++) {
      path2.lineTo(
        i, 
        yOffset + math.sin((i / size.width * 2 * math.pi) + (waveAnimation * 2 * math.pi) + math.pi) * waveHeight
      );
    }
    
    path2.lineTo(size.width, size.height);
    path2.close();
    
    canvas.drawPath(path2, layer2Paint);
  }

  @override
  bool shouldRepaint(covariant CircularWavePainter oldDelegate) {
    return oldDelegate.waveAnimation != waveAnimation || 
           oldDelegate.fillPercentage != fillPercentage;
  }
}
