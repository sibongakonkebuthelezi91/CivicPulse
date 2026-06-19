import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum JourneyStatus { setup, active, completed }
enum CheckpointStatus { completed, upcoming, missed }

class Checkpoint {
  final int minuteOffset;
  CheckpointStatus status;
  DateTime? checkedInAt;

  Checkpoint({
    required this.minuteOffset,
    this.status = CheckpointStatus.upcoming,
  });

  String get label => minuteOffset == 0
      ? 'Departed'
      : '${minuteOffset} min checkpoint';
}

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  JourneyStatus _status = JourneyStatus.setup;

  // Setup form
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  int _durationMinutes = 30;
  int _checkpointIntervalMinutes = 10;

  // Active journey
  List<Checkpoint> _checkpoints = [];
  DateTime? _journeyStartTime;
  int _currentCheckpointIndex = 0;
  int _secondsToNextCheckpoint = 0;
  Timer? _timer;
  bool _missedWarningShown = false;

  static const int _warningThresholdSecs = 120; // 2 min grace
  static const int _simulatedSecondsPerRealSecond = 30; // speed up for demo

  @override
  void dispose() {
    _timer?.cancel();
    _startController.dispose();
    _destController.dispose();
    super.dispose();
  }

  void _startJourney() {
    final intervals = <int>[0];
    for (int m = _checkpointIntervalMinutes; m < _durationMinutes; m += _checkpointIntervalMinutes) {
      intervals.add(m);
    }
    intervals.add(_durationMinutes);

    setState(() {
      _status = JourneyStatus.active;
      _journeyStartTime = DateTime.now();
      _checkpoints = intervals
          .map((m) => Checkpoint(minuteOffset: m))
          .toList();
      _checkpoints[0].status = CheckpointStatus.completed;
      _checkpoints[0].checkedInAt = DateTime.now();
      _currentCheckpointIndex = 1;
      _secondsToNextCheckpoint = _checkpointIntervalMinutes * 60 ~/ _simulatedSecondsPerRealSecond;
      _missedWarningShown = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer t) {
    if (_currentCheckpointIndex >= _checkpoints.length) {
      t.cancel();
      return;
    }

    setState(() {
      _secondsToNextCheckpoint--;
    });

    if (_secondsToNextCheckpoint <= 0 && !_missedWarningShown) {
      setState(() => _missedWarningShown = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('⚠️ Checkpoint overdue! Please check in or guardians will be alerted.'),
        backgroundColor: AppColors.urgent,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Check In',
          textColor: Colors.white,
          onPressed: _checkIn,
        ),
      ));
    }

    if (_secondsToNextCheckpoint <= -(_warningThresholdSecs ~/ _simulatedSecondsPerRealSecond)) {
      // Mark as missed
      if (_checkpoints[_currentCheckpointIndex].status == CheckpointStatus.upcoming) {
        setState(() {
          _checkpoints[_currentCheckpointIndex].status = CheckpointStatus.missed;
          _currentCheckpointIndex++;
          if (_currentCheckpointIndex < _checkpoints.length) {
            _secondsToNextCheckpoint =
                _checkpointIntervalMinutes * 60 ~/ _simulatedSecondsPerRealSecond;
            _missedWarningShown = false;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('🚨 Checkpoint missed! Guardians have been automatically alerted.'),
          backgroundColor: AppColors.critical,
          duration: Duration(seconds: 6),
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
        _secondsToNextCheckpoint =
            _checkpointIntervalMinutes * 60 ~/ _simulatedSecondsPerRealSecond;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('✅ Checked in! Guardians notified you are safe.'),
      backgroundColor: AppColors.surface,
      duration: Duration(seconds: 2),
    ));
  }

  void _completeJourney() {
    _timer?.cancel();
    setState(() {
      _status = JourneyStatus.completed;
      // Mark remaining checkpoints
      for (final cp in _checkpoints) {
        if (cp.status == CheckpointStatus.upcoming) {
          cp.status = CheckpointStatus.completed;
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('🏠 Arrived safely! All guardians have been notified.'),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 5),
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
    });
  }

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
            Text(
              'Journey Tracker',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Safety checkpoints every step of the way.',
              style: TextStyle(color: Color(0xFFF9A8D4), fontSize: 12),
            ),
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
      ),
      body: _status == JourneyStatus.setup
          ? _buildSetupView()
          : _status == JourneyStatus.active
              ? _buildActiveJourneyView()
              : _buildCompletedView(),
    );
  }

  // ─── Setup ────────────────────────────────────────────────────────────────

  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSetupCard(),
          const SizedBox(height: 20),
          _buildSafetyInfoCard(),
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
              Icon(Icons.route, color: Color(0xFFEC4899), size: 22),
              SizedBox(width: 8),
              Text('Start a Safe Journey', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Set up checkpoints. Guardians are alerted if you miss one.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 20),

          const Text('Starting From', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: _startController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'e.g. Park Station',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.my_location, color: Color(0xFFEC4899), size: 18),
            ),
          ),
          const SizedBox(height: 12),

          const Text('Going To', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: _destController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'e.g. Soweto',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.location_on, color: Color(0xFFEC4899), size: 18),
            ),
          ),
          const SizedBox(height: 20),

          const Text('Expected Journey Duration', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
                      color: selected ? const Color(0xFFEC4899) : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? const Color(0xFFEC4899) : Colors.white10),
                    ),
                    child: Column(
                      children: [
                        Text('$mins', style: TextStyle(color: selected ? Colors.white : AppColors.textMuted, fontSize: 15, fontWeight: FontWeight.bold)),
                        Text('min', style: TextStyle(color: selected ? Colors.white70 : AppColors.textMuted, fontSize: 9)),
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
                        Text('$mins', style: TextStyle(color: selected ? Colors.white : AppColors.textMuted, fontSize: 15, fontWeight: FontWeight.bold)),
                        Text('min', style: TextStyle(color: selected ? Colors.white70 : AppColors.textMuted, fontSize: 9)),
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
                backgroundColor: const Color(0xFFEC4899),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              onPressed: _startController.text.isNotEmpty && _destController.text.isNotEmpty
                  ? _startJourney
                  : null,
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text('Start Journey', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyInfoCard() {
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
          const Text('How Journey Checkpoints Work', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _infoRow(Icons.play_circle_outline, 'Journey starts → guardians are alerted', Colors.green),
          _infoRow(Icons.timer_outlined, 'App prompts you to check in at each interval', AppColors.primary),
          _infoRow(Icons.warning_amber_rounded, 'Miss a checkpoint → 2 min grace period', AppColors.urgent),
          _infoRow(Icons.emergency, 'Still no check-in → guardians auto-alerted', AppColors.critical),
          _infoRow(Icons.home_outlined, '"Arrived Safely" → guardians notified ✅', Colors.green),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.textMuted, size: 14),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Demo mode: checkpoints are sped up (1 real second = 30 journey seconds)',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                  ),
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
    final nextCheckpointIndex = _currentCheckpointIndex < _checkpoints.length
        ? _currentCheckpointIndex
        : -1;
    final isOverdue = secsRemaining < 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Route header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.route, color: Color(0xFFEC4899), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_startController.text} → ${_destController.text}',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$_durationMinutes min journey · checkpoint every $_checkpointIntervalMinutes min',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Next checkpoint countdown
          if (nextCheckpointIndex != -1) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isOverdue ? AppColors.critical.withOpacity(0.1) : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isOverdue ? AppColors.critical : AppColors.primary.withOpacity(0.3),
                  width: isOverdue ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    isOverdue ? '⚠️ CHECKPOINT OVERDUE' : '⏱ Next Checkpoint In',
                    style: TextStyle(
                      color: isOverdue ? AppColors.critical : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isOverdue
                        ? '+${(-secsRemaining).abs()} sec overdue'
                        : '${secsRemaining}s',
                    style: TextStyle(
                      color: isOverdue ? AppColors.critical : Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _checkpoints[nextCheckpointIndex].label,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
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
                      label: const Text('Check In Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 48),
                  SizedBox(height: 12),
                  Text('All checkpoints complete!', style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Tap below when you arrive home safely.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Checkpoint timeline
          _buildCheckpointTimeline(),

          const SizedBox(height: 24),

          // Arrived safely button
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
              label: const Text('Arrived Safely 🏠', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
          const Text('Checkpoint Timeline', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
                statusText = 'Missed — guardians alerted';
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
                            ? Colors.green.withOpacity(0.4)
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
                          cp.minuteOffset == 0 ? 'Journey Start' : cp.minuteOffset == _durationMinutes ? 'Arrival' : cp.label,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(statusText, style: TextStyle(color: dotColor, fontSize: 11)),
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
    final missed = _checkpoints.where((c) => c.status == CheckpointStatus.missed).length;
    final total = _checkpoints.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.home, color: Colors.green, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'Arrived Safely! 🎉',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_startController.text} → ${_destController.text}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statBadge('$completed/$total', 'Checkpoints', Colors.green),
                    _statBadge('$missed', missed > 0 ? 'Missed' : 'Missed', missed > 0 ? AppColors.critical : Colors.green),
                    _statBadge('3', 'Guardians\nNotified', AppColors.primary),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'All 3 guardians have been notified that you arrived home safely.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
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
                backgroundColor: const Color(0xFFEC4899),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              onPressed: _resetJourney,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Start New Journey', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10), textAlign: TextAlign.center),
      ],
    );
  }
}
