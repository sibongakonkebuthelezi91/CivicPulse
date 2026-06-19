import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

// ─── Enums & Models ───────────────────────────────────────────────────────────

enum JourneyStatus { setup, active, completed }
enum CheckpointStatus { completed, upcoming, missed }

class Checkpoint {
  final int minuteOffset;
  CheckpointStatus status;
  DateTime? checkedInAt;

  Checkpoint({required this.minuteOffset, this.status = CheckpointStatus.upcoming});

  String get label => minuteOffset == 0 ? 'Departed' : '$minuteOffset min checkpoint';
}

class JourneyRecord {
  final String from;
  final String to;
  final DateTime departedAt;
  final int durationMinutes;
  final int checkpointsHit;
  final int checkpointsMissed;
  final bool arrivedSafely;

  const JourneyRecord({
    required this.from,
    required this.to,
    required this.departedAt,
    required this.durationMinutes,
    required this.checkpointsHit,
    required this.checkpointsMissed,
    required this.arrivedSafely,
  });

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(departedAt).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${departedAt.day}/${departedAt.month}/${departedAt.year}';
  }

  String get formattedTime =>
      '${departedAt.hour.toString().padLeft(2, '0')}:${departedAt.minute.toString().padLeft(2, '0')}';
}

// Traffic safety rating per hour (0=very safe, 10=peak danger)
class _HourRating {
  final int hour;
  final double risk; // 0.0 - 1.0
  final String label;
  const _HourRating(this.hour, this.risk, this.label);
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  static void launchJourneyWithGuardian({
    required String start,
    required String destination,
    required String name,
    required String phone,
  }) {
    _JourneyScreenState.activeState?.startJourneyWithGuardian(
      startLocation: start,
      destination: destination,
      guardianName: name,
      guardianPhone: phone,
    );
  }

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static _JourneyScreenState? activeState;

  // Guardian Angel state
  String? _activeGuardianName;
  String? _activeGuardianPhone;
  bool _isGuardianAngelJourney = false;

  // ── Journey tracking state ──
  JourneyStatus _status = JourneyStatus.setup;
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  int _durationMinutes = 30;
  int _checkpointIntervalMinutes = 10;

  List<Checkpoint> _checkpoints = [];
  DateTime? _journeyStartTime;
  int _currentCheckpointIndex = 0;
  int _secondsToNextCheckpoint = 0;
  Timer? _timer;
  bool _missedWarningShown = false;

  static const int _warningThresholdSecs = 120;
  static const int _simSpeed = 30; // 1 real second = 30 journey seconds (demo)

  // ── History / Pattern data ──
  final List<JourneyRecord> _history = [
    JourneyRecord(from: 'Home', to: 'Park Station', departedAt: DateTime.now().subtract(const Duration(hours: 25, minutes: 10)), durationMinutes: 28, checkpointsHit: 3, checkpointsMissed: 0, arrivedSafely: true),
    JourneyRecord(from: 'Park Station', to: 'Sandton City', departedAt: DateTime.now().subtract(const Duration(hours: 24, minutes: 45)), durationMinutes: 35, checkpointsHit: 4, checkpointsMissed: 0, arrivedSafely: true),
    JourneyRecord(from: 'Home', to: 'Park Station', departedAt: DateTime.now().subtract(const Duration(hours: 49, minutes: 5)), durationMinutes: 34, checkpointsHit: 2, checkpointsMissed: 1, arrivedSafely: true),
    JourneyRecord(from: 'Park Station', to: 'Soweto', departedAt: DateTime.now().subtract(const Duration(hours: 48, minutes: 40)), durationMinutes: 45, checkpointsHit: 5, checkpointsMissed: 0, arrivedSafely: true),
    JourneyRecord(from: 'Home', to: 'Noord Taxi Rank', departedAt: DateTime.now().subtract(const Duration(hours: 73, minutes: 12)), durationMinutes: 22, checkpointsHit: 3, checkpointsMissed: 0, arrivedSafely: true),
    JourneyRecord(from: 'Noord Taxi Rank', to: 'Home', departedAt: DateTime.now().subtract(const Duration(hours: 72, minutes: 30)), durationMinutes: 31, checkpointsHit: 2, checkpointsMissed: 1, arrivedSafely: true),
  ];

  // Traffic risk by hour of day
  final List<_HourRating> _hourlyRisk = [
    _HourRating(5,  0.15, 'Very quiet'),
    _HourRating(6,  0.35, 'Early commuters'),
    _HourRating(7,  0.90, 'Peak — high risk'),
    _HourRating(8,  0.85, 'Peak — high risk'),
    _HourRating(9,  0.45, 'Settling down'),
    _HourRating(10, 0.20, 'Quiet'),
    _HourRating(11, 0.20, 'Quiet'),
    _HourRating(12, 0.30, 'Lunch traffic'),
    _HourRating(13, 0.25, 'Quiet'),
    _HourRating(14, 0.30, 'Building up'),
    _HourRating(15, 0.55, 'School run'),
    _HourRating(16, 0.80, 'Peak — high risk'),
    _HourRating(17, 0.95, 'Peak — very high risk'),
    _HourRating(18, 0.85, 'Peak — high risk'),
    _HourRating(19, 0.50, 'Evening calming'),
    _HourRating(20, 0.30, 'Quiet evening'),
    _HourRating(21, 0.40, 'Late risk rising'),
    _HourRating(22, 0.55, 'Night risk'),
  ];

  @override
  void initState() {
    super.initState();
    activeState = this;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    if (activeState == this) {
      activeState = null;
    }
    _timer?.cancel();
    _tabController.dispose();
    _startController.dispose();
    _destController.dispose();
    super.dispose();
  }

  void startJourneyWithGuardian({
    required String startLocation,
    required String destination,
    required String guardianName,
    required String guardianPhone,
  }) {
    setState(() {
      _startController.text = startLocation;
      _destController.text = destination;
      _activeGuardianName = guardianName;
      _activeGuardianPhone = guardianPhone;
      _isGuardianAngelJourney = true;
    });
    _startJourney();
  }

  // ─── Journey logic ────────────────────────────────────────────────────────

  void _startJourney() {
    final intervals = <int>[0];
    for (int m = _checkpointIntervalMinutes; m < _durationMinutes; m += _checkpointIntervalMinutes) {
      intervals.add(m);
    }
    intervals.add(_durationMinutes);

    setState(() {
      _status = JourneyStatus.active;
      _journeyStartTime = DateTime.now();
      _checkpoints = intervals.map((m) => Checkpoint(minuteOffset: m)).toList();
      _checkpoints[0].status = CheckpointStatus.completed;
      _checkpoints[0].checkedInAt = DateTime.now();
      _currentCheckpointIndex = 1;
      _secondsToNextCheckpoint = _checkpointIntervalMinutes * 60 ~/ _simSpeed;
      _missedWarningShown = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer t) {
    if (_currentCheckpointIndex >= _checkpoints.length) { t.cancel(); return; }
    setState(() => _secondsToNextCheckpoint--);

    if (_secondsToNextCheckpoint <= 0 && !_missedWarningShown) {
      setState(() => _missedWarningShown = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isGuardianAngelJourney
            ? '⚠️ Checkpoint overdue! Check in or $_activeGuardianName will be alerted.'
            : '⚠️ Checkpoint overdue! Check in or guardians will be alerted.'),
        backgroundColor: AppColors.urgent,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: 'Check In', textColor: Colors.white, onPressed: _checkIn),
      ));
    }

    if (_secondsToNextCheckpoint <= -(_warningThresholdSecs ~/ _simSpeed)) {
      if (_checkpoints[_currentCheckpointIndex].status == CheckpointStatus.upcoming) {
        setState(() {
          _checkpoints[_currentCheckpointIndex].status = CheckpointStatus.missed;
          _currentCheckpointIndex++;
          if (_currentCheckpointIndex < _checkpoints.length) {
            _secondsToNextCheckpoint = _checkpointIntervalMinutes * 60 ~/ _simSpeed;
            _missedWarningShown = false;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isGuardianAngelJourney
              ? '🚨 Checkpoint missed! Guardian Angel $_activeGuardianName automatically alerted.'
              : '🚨 Checkpoint missed! Guardians automatically alerted.'),
          backgroundColor: AppColors.critical,
          duration: const Duration(seconds: 6),
        ));
      }
    }
  }

  void _checkIn() {
    if (_currentCheckpointIndex >= _checkpoints.length) return;
    setState(() {
      _checkpoints[_currentCheckpointIndex].status = CheckpointStatus.completed;
      _checkpoints[_currentCheckpointIndex].checkedInAt = DateTime.now();
      _currentCheckpointIndex++;
      _missedWarningShown = false;
      if (_currentCheckpointIndex < _checkpoints.length) {
        _secondsToNextCheckpoint = _checkpointIntervalMinutes * 60 ~/ _simSpeed;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_isGuardianAngelJourney
          ? '✅ Checked in! Guardian Angel $_activeGuardianName notified you are safe.'
          : '✅ Checked in! Guardians notified you are safe.'),
      backgroundColor: AppColors.surface,
      duration: const Duration(seconds: 2),
    ));
  }

  void _completeJourney() {
    _timer?.cancel();
    final hit = _checkpoints.where((c) => c.status == CheckpointStatus.completed).length;
    final missed = _checkpoints.where((c) => c.status == CheckpointStatus.missed).length;
    setState(() {
      _status = JourneyStatus.completed;
      for (final cp in _checkpoints) {
        if (cp.status == CheckpointStatus.upcoming) cp.status = CheckpointStatus.completed;
      }
      // Record journey into history
      _history.insert(0, JourneyRecord(
        from: _startController.text,
        to: _destController.text,
        departedAt: _journeyStartTime ?? DateTime.now(),
        durationMinutes: _durationMinutes,
        checkpointsHit: hit,
        checkpointsMissed: missed,
        arrivedSafely: true,
      ));
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_isGuardianAngelJourney
          ? '🏠 Arrived safely! Guardian Angel $_activeGuardianName has been notified.'
          : '🏠 Arrived safely! All guardians have been notified.'),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 5),
    ));
  }

  void _resetJourney() {
    _timer?.cancel();
    setState(() {
      _status = JourneyStatus.setup;
      _checkpoints = [];
      _currentCheckpointIndex = 0;
      _secondsToNextCheckpoint = 0;
      _missedWarningShown = false;
      _isGuardianAngelJourney = false;
      _activeGuardianName = null;
      _activeGuardianPhone = null;
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Journey Tracker',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: -0.5)),
            Text('Track, analyse & travel safer.',
                style: TextStyle(color: AppColors.accent, fontSize: 12)),
          ],
        ),
        actions: [
          if (_status == JourneyStatus.active)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton(
                onPressed: _resetJourney,
                child: const Text('Cancel', style: TextStyle(color: AppColors.critical)),
              ),
            ),
        ],
        bottom: _status == JourneyStatus.setup || _status == JourneyStatus.completed
            ? TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textMuted,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: '🗺️  Track'),
                  Tab(text: '📊  Insights'),
                ],
              )
            : null,
      ),
      body: _status == JourneyStatus.active
          ? _buildActiveJourneyView()
          : TabBarView(
              controller: _tabController,
              children: [
                _status == JourneyStatus.completed ? _buildCompletedView() : _buildSetupView(),
                _buildInsightsView(),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1: TRACK — Setup / Active / Completed
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSmartDepartureBanner(),
          const SizedBox(height: 16),
          _buildSetupCard(),
          const SizedBox(height: 16),
          _buildHowItWorksCard(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSmartDepartureBanner() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentRating = _hourlyRisk.firstWhere(
      (r) => r.hour == currentHour,
      orElse: () => _HourRating(currentHour, 0.2, 'Quiet'),
    );

    // Find best departure in the next 4 hours
    final upcoming = _hourlyRisk.where((r) => r.hour > currentHour && r.hour <= currentHour + 4).toList();
    final best = upcoming.isEmpty ? null : upcoming.reduce((a, b) => a.risk < b.risk ? a : b);

    final riskColor = currentRating.risk > 0.7
        ? AppColors.critical
        : currentRating.risk > 0.4
            ? AppColors.urgent
            : Colors.green;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: riskColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: riskColor, size: 18),
              const SizedBox(width: 8),
              Text('Smart Departure Tip',
                  style: TextStyle(color: riskColor, fontSize: 13, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${currentHour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: riskColor, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            currentRating.risk > 0.7
                ? '⚠️ Right now is a high-risk travel period. ${best != null ? 'Consider departing at ${best.hour}:00 when it\'s safer.' : 'Stay vigilant.'}'
                : currentRating.risk > 0.4
                    ? '🟡 Moderate traffic right now. ${best != null ? '${best.hour}:00 looks quieter.' : 'Travel in groups if possible.'}'
                    : '✅ Good time to travel! Roads are relatively quiet right now.',
            style: TextStyle(color: riskColor.withValues(alpha: 0.9), fontSize: 12),
          ),
          if (best != null && currentRating.risk > 0.4) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _tabController.animateTo(1),
              child: Row(
                children: [
                  Text('View full departure schedule',
                      style: TextStyle(color: riskColor, fontSize: 11, fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, color: riskColor, size: 12),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSetupCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.route, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text('Start a Safe Journey',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Guardians are alerted if you miss a checkpoint.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 20),

          const Text('Starting From', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: _startController,
            style: const TextStyle(color: Colors.white),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'e.g. Home, Park Station...',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.my_location, color: AppColors.primary, size: 18),
            ),
          ),
          const SizedBox(height: 12),

          const Text('Going To', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: _destController,
            style: const TextStyle(color: Colors.white),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'e.g. Soweto, Noord Taxi Rank...',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.location_on, color: AppColors.primary, size: 18),
            ),
          ),

          // Smart estimate from history
          if (_startController.text.isNotEmpty && _destController.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildSmartEstimate(),
          ],

          const SizedBox(height: 20),
          const Text('Expected Duration', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [30, 45, 60, 90].map((mins) {
              final selected = _durationMinutes == mins;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _durationMinutes = mins),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? AppColors.primary : Colors.white10),
                    ),
                    child: Column(
                      children: [
                        Text('$mins',
                            style: TextStyle(
                                color: selected ? Colors.white : AppColors.textMuted,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                        Text('min',
                            style: TextStyle(
                                color: selected ? Colors.white70 : AppColors.textMuted, fontSize: 9)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          const Text('Checkpoint Every', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [5, 10, 15].map((mins) {
              final selected = _checkpointIntervalMinutes == mins;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _checkpointIntervalMinutes = mins),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? AppColors.primary : Colors.white10),
                    ),
                    child: Column(
                      children: [
                        Text('$mins',
                            style: TextStyle(
                                color: selected ? Colors.white : AppColors.textMuted,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                        Text('min',
                            style: TextStyle(
                                color: selected ? Colors.white70 : AppColors.textMuted, fontSize: 9)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              onPressed: _startController.text.isNotEmpty && _destController.text.isNotEmpty
                  ? _startJourney
                  : null,
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text('Start Journey',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartEstimate() {
    // Find similar past journeys
    final similar = _history.where((j) =>
        j.from.toLowerCase().contains(_startController.text.toLowerCase().split(' ').first) ||
        j.to.toLowerCase().contains(_destController.text.toLowerCase().split(' ').first)).toList();

    if (similar.isEmpty) return const SizedBox.shrink();

    final avgDuration = (similar.map((j) => j.durationMinutes).reduce((a, b) => a + b) / similar.length).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: AppColors.primary, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Based on ${similar.length} similar past trips, avg journey is ~$avgDuration min.',
              style: const TextStyle(color: AppColors.primary, fontSize: 11),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _durationMinutes = avgDuration <= 30 ? 30 : avgDuration <= 45 ? 45 : avgDuration <= 60 ? 60 : 90),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Use', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How Checkpoints Work',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _infoRow(Icons.play_circle_outline, 'Journey starts → guardians alerted', Colors.green),
          _infoRow(Icons.timer_outlined, 'Check in at each interval to confirm safety', AppColors.primary),
          _infoRow(Icons.warning_amber_rounded, 'Miss a check-in → 2 min warning fires', AppColors.urgent),
          _infoRow(Icons.emergency, 'Still no check-in → guardians auto-alerted 🚨', AppColors.critical),
          _infoRow(Icons.home_outlined, '"Arrived Safely" → journey logged + guardians told ✅', Colors.green),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.speed, color: AppColors.textMuted, size: 13),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Demo mode: 1 real second = 30 journey seconds',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  // ─── Active Journey ───────────────────────────────────────────────────────

  Widget _buildActiveJourneyView() {
    final secsRemaining = _secondsToNextCheckpoint;
    final nextIdx = _currentCheckpointIndex < _checkpoints.length ? _currentCheckpointIndex : -1;
    final isOverdue = secsRemaining < 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_isGuardianAngelJourney) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🛡️ Guardian Angel Active',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_activeGuardianName is monitoring your journey live. SMS warnings will auto-send to $_activeGuardianPhone.',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Route header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.route, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_startController.text} → ${_destController.text}',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text('$_durationMinutes min · checkpoint every $_checkpointIntervalMinutes min',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Countdown / all done
          if (nextIdx != -1)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isOverdue ? AppColors.critical.withValues(alpha: 0.1) : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isOverdue ? AppColors.critical : AppColors.primary.withValues(alpha: 0.3),
                    width: isOverdue ? 2 : 1),
              ),
              child: Column(
                children: [
                  Text(
                    isOverdue ? '⚠️ CHECKPOINT OVERDUE' : '⏱ Next Checkpoint In',
                    style: TextStyle(
                        color: isOverdue ? AppColors.critical : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isOverdue ? '+${(-secsRemaining).abs()}s overdue' : '${secsRemaining}s',
                    style: TextStyle(
                        color: isOverdue ? AppColors.critical : Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1),
                  ),
                  const SizedBox(height: 4),
                  Text(_checkpoints[nextIdx].label,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOverdue ? AppColors.critical : AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      onPressed: _checkIn,
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: const Text('Check In Now',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 48),
                  SizedBox(height: 12),
                  Text('All checkpoints complete!',
                      style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Tap "Arrived Safely" below.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),

          const SizedBox(height: 24),
          _buildCheckpointTimeline(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              onPressed: _completeJourney,
              icon: const Icon(Icons.home, color: Colors.white),
              label: const Text('Arrived Safely 🏠',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckpointTimeline() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Checkpoint Timeline',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          ...List.generate(_checkpoints.length, (i) {
            final cp = _checkpoints[i];
            final isLast = i == _checkpoints.length - 1;
            Color dotColor;
            IconData dotIcon;
            String statusText;

            switch (cp.status) {
              case CheckpointStatus.completed:
                dotColor = Colors.green;
                dotIcon = Icons.check_circle;
                statusText = cp.checkedInAt != null
                    ? 'Checked in at ${cp.checkedInAt!.hour.toString().padLeft(2, '0')}:${cp.checkedInAt!.minute.toString().padLeft(2, '0')}'
                    : 'Completed';
                break;
              case CheckpointStatus.missed:
                dotColor = AppColors.critical;
                dotIcon = Icons.cancel;
                statusText = _isGuardianAngelJourney
                    ? 'Missed — Guardian $_activeGuardianName alerted'
                    : 'Missed — guardians alerted';
                break;
              case CheckpointStatus.upcoming:
                dotColor = i == _currentCheckpointIndex ? AppColors.primary : Colors.white24;
                dotIcon = i == _currentCheckpointIndex ? Icons.radio_button_checked : Icons.radio_button_unchecked;
                statusText = i == _currentCheckpointIndex ? 'Current' : 'Upcoming';
                break;
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Icon(dotIcon, color: dotColor, size: 22),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 32,
                        color: cp.status == CheckpointStatus.completed
                            ? Colors.green.withValues(alpha: 0.4)
                            : Colors.white10,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cp.minuteOffset == 0
                              ? 'Journey Start'
                              : cp.minuteOffset == _durationMinutes
                                  ? 'Arrival'
                                  : cp.label,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(statusText,
                            style: TextStyle(color: dotColor, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ─── Completed ────────────────────────────────────────────────────────────

  Widget _buildCompletedView() {
    final completed = _checkpoints.where((c) => c.status == CheckpointStatus.completed).length;
    final total = _checkpoints.length;
    final safetyScore = total > 0 ? ((completed / total) * 100).round() : 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.home, color: Colors.green, size: 56),
                const SizedBox(height: 16),
                const Text('Arrived Safely! 🎉',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${_startController.text} → ${_destController.text}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statBadge('$completed/$total', 'Checkpoints', Colors.green),
                    _statBadge('$safetyScore%', 'Safety\nScore', safetyScore >= 80 ? Colors.green : AppColors.urgent),
                    _statBadge(_isGuardianAngelJourney ? '1' : '3', _isGuardianAngelJourney ? 'Guardian\nNotified' : 'Guardians\nNotified', AppColors.primary),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('This journey has been recorded to your travel history.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildCheckpointTimeline(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                  ),
                  onPressed: () => _tabController.animateTo(1),
                  icon: const Icon(Icons.bar_chart, color: AppColors.primary, size: 18),
                  label: const Text('View Insights', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                  ),
                  onPressed: _resetJourney,
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text('New Journey', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _statBadge(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
            textAlign: TextAlign.center),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2: INSIGHTS — Patterns, History, Departure Times
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildInsightsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPatternSummaryCard(),
          const SizedBox(height: 16),
          _buildDepartureHeatmap(),
          const SizedBox(height: 16),
          _buildBestDepartureCard(),
          const SizedBox(height: 16),
          _buildJourneyHistory(),
        ],
      ),
    );
  }

  // ── Travel Pattern Summary ────────────────────────────────────────────────

  Widget _buildPatternSummaryCard() {
    if (_history.isEmpty) {
      return const SizedBox.shrink();
    }

    final avgDuration = (_history.map((j) => j.durationMinutes).reduce((a, b) => a + b) / _history.length).round();
    final totalTrips = _history.length;
    final allCheckpointsHit = _history.fold<int>(0, (sum, j) => sum + j.checkpointsHit);
    final allCheckpointsMissed = _history.fold<int>(0, (sum, j) => sum + j.checkpointsMissed);
    final checkpointRate = allCheckpointsHit + allCheckpointsMissed > 0
        ? ((allCheckpointsHit / (allCheckpointsHit + allCheckpointsMissed)) * 100).round()
        : 100;

    // Find most common departure hour
    final hourCounts = <int, int>{};
    for (final j in _history) {
      hourCounts[j.departedAt.hour] = (hourCounts[j.departedAt.hour] ?? 0) + 1;
    }
    final commonHour = hourCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('Your Travel Patterns', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Based on $totalTrips recorded journeys',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _patternStat('$avgDuration min', 'Avg Journey\nDuration', AppColors.primary)),
              Expanded(child: _patternStat('$checkpointRate%', 'Checkpoint\nCompliance', checkpointRate >= 80 ? Colors.green : AppColors.urgent)),
              Expanded(child: _patternStat('${commonHour.toString().padLeft(2,'0')}:00', 'Most Common\nDeparture', AppColors.primary)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pattern Insight', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  _getPatternInsight(commonHour, avgDuration, checkpointRate),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPatternInsight(int commonHour, int avgDuration, int checkpointRate) {
    final timeRisk = _hourlyRisk.firstWhere((r) => r.hour == commonHour, orElse: () => _HourRating(commonHour, 0.3, ''));
    final timeWarning = timeRisk.risk > 0.7
        ? 'Your most common departure time (${commonHour.toString().padLeft(2,'0')}:00) falls in a high-risk traffic period. '
        : '';
    final checkpointMsg = checkpointRate >= 90
        ? 'Excellent checkpoint compliance — your guardians always know you\'re safe. '
        : 'Some checkpoints were missed. Consider setting a longer interval so you don\'t miss them.';
    return '${timeWarning}Average journey is $avgDuration minutes. $checkpointMsg';
  }

  Widget _patternStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10, height: 1.3)),
      ],
    );
  }

  // ── Departure Time Heatmap ────────────────────────────────────────────────

  Widget _buildDepartureHeatmap() {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('Daily Safety Calendar', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Risk level by hour — green = safer, red = peak danger',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 16),

          // Heatmap bars
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _hourlyRisk.map((r) {
                final isCurrent = r.hour == now.hour;
                final color = Color.lerp(Colors.green, AppColors.critical, r.risk)!;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isCurrent)
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Container(
                          height: 60 * r.risk + 6,
                          decoration: BoxDecoration(
                            color: isCurrent ? color : color.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(3),
                            border: isCurrent ? Border.all(color: Colors.white, width: 1.5) : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          r.hour % 2 == 0 ? '${r.hour}' : '',
                          style: TextStyle(
                            color: isCurrent ? Colors.white : AppColors.textMuted,
                            fontSize: 9,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(Colors.green, 'Safe'),
              const SizedBox(width: 16),
              _legendDot(AppColors.urgent, 'Moderate'),
              const SizedBox(width: 16),
              _legendDot(AppColors.critical, 'High Risk'),
              const SizedBox(width: 16),
              _legendDot(Colors.white, 'Now', isCircle: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label, {bool isCircle = false}) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircle ? null : BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }

  // ── Best Departure Suggestions ────────────────────────────────────────────

  Widget _buildBestDepartureCard() {
    final now = DateTime.now();

    // Best departure slots: 3 safest upcoming hours
    final upcoming = _hourlyRisk.where((r) => r.hour >= now.hour && r.hour <= now.hour + 8).toList()
      ..sort((a, b) => a.risk.compareTo(b.risk));
    final best3 = upcoming.take(3).toList();
    best3.sort((a, b) => a.hour.compareTo(b.hour));

    // Avoid slots: top 2 riskiest in same window
    final worst = _hourlyRisk.where((r) => r.hour >= now.hour && r.hour <= now.hour + 8).toList()
      ..sort((a, b) => b.risk.compareTo(a.risk));
    final avoid2 = worst.take(2).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.recommend, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text('Suggested Departure Times', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Based on your travel patterns and current peak periods.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 16),

          const Text('✅ Best Windows (Next 8 Hours)',
              style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...best3.map((r) => _departureSlot(r, good: true)),

          const SizedBox(height: 16),
          const Text('⚠️ Avoid If Possible',
              style: TextStyle(color: AppColors.urgent, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...avoid2.map((r) => _departureSlot(r, good: false)),
        ],
      ),
    );
  }

  Widget _departureSlot(_HourRating r, {required bool good}) {
    final color = good ? Colors.green : AppColors.urgent;
    final riskPct = (r.risk * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(
            '${r.hour.toString().padLeft(2, '0')}:00',
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: r.risk,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            good ? '${100 - riskPct}% safe' : '$riskPct% risk',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ── Journey History ───────────────────────────────────────────────────────

  Widget _buildJourneyHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Journey History',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            Text('${_history.length} trips',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),
        if (_history.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: const Center(
              child: Text('No journeys recorded yet.\nStart your first journey to see history here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
          )
        else
          ...List.generate(_history.length > 10 ? 10 : _history.length, (i) {
            final j = _history[i];
            final safetyScore = j.checkpointsHit + j.checkpointsMissed > 0
                ? ((j.checkpointsHit / (j.checkpointsHit + j.checkpointsMissed)) * 100).round()
                : 100;
            final scoreColor = safetyScore >= 80 ? Colors.green : AppColors.urgent;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: j.arrivedSafely ? Colors.green.withValues(alpha: 0.15) : AppColors.critical.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      j.arrivedSafely ? Icons.home : Icons.warning,
                      color: j.arrivedSafely ? Colors.green : AppColors.critical,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${j.from} → ${j.to}',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(j.formattedDate,
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            const Text(' · ', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            Text(j.formattedTime,
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            const Text(' · ', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            Text('${j.durationMinutes} min',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$safetyScore%', style: TextStyle(color: scoreColor, fontSize: 14, fontWeight: FontWeight.bold)),
                      Text('safety', style: TextStyle(color: scoreColor.withValues(alpha: 0.7), fontSize: 9)),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
