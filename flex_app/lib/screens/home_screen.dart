import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ApiService.getHomeSummary();
      setState(() {
        _data = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colors = theme.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        title: Text('FLEX', style: TextStyle(color: colors.text, fontWeight: FontWeight.w700, letterSpacing: 1)),
        actions: [
          IconButton(
            icon: Icon(theme.isDark ? Icons.light_mode : Icons.dark_mode, color: colors.accent),
            onPressed: theme.toggleMode,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _buildBody(colors),
      ),
    );
  }

  Widget _buildBody(AppColors colors) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: colors.accent));
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.wifi_off, size: 48, color: colors.textMuted),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Could not reach the server.\n$_error',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textMuted),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: colors.accent, foregroundColor: colors.onAccent),
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    final streak = _data!['streak'] as int;
    final loggedDays = List<String>.from(_data!['logged_days'] as List);
    final todayCal = _data!['today_calories'];
    final todayProtein = _data!['today_protein'];
    final remainingCal = _data!['remaining_calories'];
    final remainingProtein = _data!['remaining_protein'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StreakCard(streak: streak, colors: colors),
        const SizedBox(height: 14),
        _CalendarCard(loggedDays: loggedDays, colors: colors),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department,
                label: 'Calories today',
                value: '$todayCal',
                sub: '$remainingCal left',
                colors: colors,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.egg_alt,
                label: 'Protein today',
                value: '${todayProtein}g',
                sub: '${remainingProtein}g left',
                colors: colors,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final AppColors colors;
  const _Card({required this.child, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: child,
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int streak;
  final AppColors colors;
  const _StreakCard({required this.streak, required this.colors});

  @override
  Widget build(BuildContext context) {
    return _Card(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current streak', style: TextStyle(color: colors.textMuted, fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.local_fire_department, color: Color(0xFFE8804A), size: 32),
              const SizedBox(width: 8),
              Text(
                '$streak',
                style: TextStyle(color: colors.accent, fontSize: 40, fontWeight: FontWeight.w700, height: 1),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('days', style: TextStyle(color: colors.textMuted, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final List<String> loggedDays; // "YYYY-MM-DD" strings
  final AppColors colors;
  const _CalendarCard({required this.loggedDays, required this.colors});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final startWeekday = firstOfMonth.weekday % 7; // Dart: Mon=1..Sun=7 -> convert so Sun=0

    final loggedSet = loggedDays.map((d) => DateTime.parse(d).day).toSet();

    final monthName = _monthName(now.month);

    return _Card(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$monthName ${now.year}', style: TextStyle(color: colors.text, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => Expanded(
                      child: Center(child: Text(d, style: TextStyle(color: colors.textMuted, fontSize: 10))),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (context, index) {
              final dayNum = index - startWeekday + 1;
              if (dayNum < 1) return const SizedBox();

              final isToday = dayNum == now.day;
              final isLogged = loggedSet.contains(dayNum);
              final weekday = (startWeekday + dayNum - 1) % 7; // 0 = Sunday
              final isSunday = weekday == 0;

              Color bg = Colors.transparent;
              Color fg = isToday ? colors.text : colors.textMuted;
              if (isLogged) {
                bg = colors.accent.withOpacity(0.22);
                fg = colors.accent;
              } else if (isSunday) {
                bg = colors.rest.withOpacity(0.35);
                fg = colors.accentDark;
              }

              return Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday ? Border.all(color: colors.accent) : null,
                ),
                child: Center(
                  child: Text('$dayNum', style: TextStyle(color: fg, fontSize: 11, fontFamily: 'monospace')),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month - 1];
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final AppColors colors;
  const _StatCard({required this.icon, required this.label, required this.value, required this.sub, required this.colors});

  @override
  Widget build(BuildContext context) {
    return _Card(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: colors.textMuted),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: colors.textMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: colors.text, fontSize: 24, fontWeight: FontWeight.w700)),
          Text(sub, style: TextStyle(color: colors.accent, fontSize: 11)),
        ],
      ),
    );
  }
}