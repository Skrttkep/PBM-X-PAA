import 'package:flutter/material.dart';
import '../services/activity_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ActivityService _service = ActivityService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  static const int _stepTarget = 8000;
  static const double _calorieTarget = 500;

  String _warningMessage = '';
  bool _showWarning = false;

  @override
  void initState() {
    super.initState();
    _service.initialize();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _service.warningStream.listen((msg) {
      setState(() {
        _warningMessage = msg;
        _showWarning = true;
      });
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => _showWarning = false);
      });
    });
  }

  @override
  void dispose() {
    _service.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _activityLabel(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return '🏃 Lari';
      case ActivityType.walking:
        return '🚶 Jalan';
      case ActivityType.idle:
        return '🛋️ Rebahan';
    }
  }

  Color _activityColor(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return const Color(0xFFFF6B35);
      case ActivityType.walking:
        return const Color(0xFF4ECDC4);
      case ActivityType.idle:
        return const Color(0xFF95A5A6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildActivityCard(),
                  const SizedBox(height: 16),
                  _buildStatsRow(),
                  const SizedBox(height: 16),
                  _buildProgressCard(
                    label: 'Langkah Hari Ini',
                    icon: '👟',
                    stream: _service.stepsStream.map((s) => s.toDouble()),
                    target: _stepTarget.toDouble(),
                    unit: 'langkah',
                    color: const Color(0xFF4ECDC4),
                  ),
                  const SizedBox(height: 12),
                  _buildProgressCard(
                    label: 'Kalori Terbakar',
                    icon: '🔥',
                    stream: _service.caloriesStream,
                    target: _calorieTarget,
                    unit: 'kcal',
                    color: const Color(0xFFFF6B35),
                  ),
                  const SizedBox(height: 16),
                  _buildSedentaryCard(),
                  const SizedBox(height: 16),
                  _buildTips(),
                ],
              ),
            ),
            if (_showWarning)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildWarningBanner(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Tracker',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              _getGreeting(),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: StreamBuilder<int>(
            stream: _service.sedentaryStream,
            initialData: 0,
            builder: (ctx, snap) {
              final mins = snap.data ?? 0;
              return Text(
                mins > 0 ? '😴 ${mins}m diem' : '✅ Aktif',
                style: TextStyle(
                  color: mins > 20
                      ? const Color(0xFFFF6B35)
                      : const Color(0xFF4ECDC4),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard() {
    return StreamBuilder<ActivityType>(
      stream: _service.activityStream,
      initialData: ActivityType.idle,
      builder: (ctx, snap) {
        final activity = snap.data ?? ActivityType.idle;
        final color = _activityColor(activity);

        return AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Transform.scale(
            scale: activity != ActivityType.idle ? _pulseAnim.value : 1.0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.25),
                    color.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: color.withOpacity(0.4), width: 1.5),
              ),
              child: Column(
                children: [
                  Text(
                    activity == ActivityType.running
                        ? '🏃‍♂️'
                        : activity == ActivityType.walking
                            ? '🚶‍♂️'
                            : '🛋️',
                    style: const TextStyle(fontSize: 56),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _activityLabel(activity),
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity == ActivityType.idle
                        ? 'Eh, gerak dikit kek...'
                        : activity == ActivityType.walking
                            ? 'Bagus! Terusin jalannya 💪'
                            : 'GAS! Kalori pada kabur 🔥',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<int>(
            stream: _service.stepsStream,
            initialData: 0,
            builder: (ctx, snap) => _miniStat(
              '👟',
              '${snap.data ?? 0}',
              'langkah',
              const Color(0xFF4ECDC4),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StreamBuilder<double>(
            stream: _service.caloriesStream,
            initialData: 0.0,
            builder: (ctx, snap) => _miniStat(
              '🔥',
              '${(snap.data ?? 0).toStringAsFixed(1)}',
              'kcal',
              const Color(0xFFFF6B35),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StreamBuilder<int>(
            stream: _service.sedentaryStream,
            initialData: 0,
            builder: (ctx, snap) => _miniStat(
              '⏱️',
              '${snap.data ?? 0}',
              'mnt diem',
              const Color(0xFFFFD93D),
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniStat(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard({
    required String label,
    required String icon,
    required Stream<double> stream,
    required double target,
    required String unit,
    required Color color,
  }) {
    return StreamBuilder<double>(
      stream: stream,
      initialData: 0.0,
      builder: (ctx, snap) {
        final value = snap.data ?? 0;
        final progress = (value / target).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$icon $label',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${value.toStringAsFixed(unit == 'kcal' ? 1 : 0)} / ${target.toStringAsFixed(0)} $unit',
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                progress >= 1.0
                    ? '✅ Target tercapai! Mantap!'
                    : '${(progress * 100).toStringAsFixed(0)}% dari target',
                style: TextStyle(
                  color: progress >= 1.0 ? color : Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSedentaryCard() {
    return StreamBuilder<int>(
      stream: _service.sedentaryStream,
      initialData: 0,
      builder: (ctx, snap) {
        final mins = snap.data ?? 0;
        final isWarning = mins >= 30;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isWarning
                ? const Color(0xFFFF6B35).withOpacity(0.15)
                : const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(20),
            border: isWarning
                ? Border.all(color: const Color(0xFFFF6B35).withOpacity(0.5))
                : null,
          ),
          child: Row(
            children: [
              Text(
                mins == 0 ? '🎉' : mins < 30 ? '😌' : '🚨',
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isWarning ? 'SEDENTARY ALERT!' : 'Sedentary Monitor',
                      style: TextStyle(
                        color: isWarning
                            ? const Color(0xFFFF6B35)
                            : Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mins == 0
                          ? 'Kamu aktif sekarang! 💪'
                          : 'Diem $mins menit... ${isWarning ? "GERAK SEKARANG!" : ""}',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTips() {
    final tips = [
      '💡 Jalan kaki 8000 langkah = ~400 kalori terbakar',
      '💡 Berdiri setiap 30 menit bantu metabolisme',
      '💡 Lari 30 menit bisa bakar 300-400 kalori',
      '💡 Diem 8 jam = cuma bakar ~80 kalori. Serem kan?',
    ];
    final tip = tips[DateTime.now().hour % tips.length];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        tip,
        style: const TextStyle(color: Colors.white60, fontSize: 12),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withOpacity(0.4),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🚨', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _warningMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat pagi! Udah gerak belum?';
    if (hour < 17) return 'Siang nih, jangan rebahan mulu 😤';
    return 'Sore/malem, kalori hari ini gimana?';
  }
}