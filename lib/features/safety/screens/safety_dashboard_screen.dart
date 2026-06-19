import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SafetyDashboardScreen extends StatefulWidget {
  const SafetyDashboardScreen({super.key});

  @override
  State<SafetyDashboardScreen> createState() => _SafetyDashboardScreenState();
}

class _SafetyDashboardScreenState extends State<SafetyDashboardScreen> {
  bool _isTrackingEnabled = false;
  bool _isCalculating = false;
  List<Map<String, String>>? _dropOffSequence;

  final List<Map<String, dynamic>> _walkingGroups = [
    {'route': 'Station A to High Street', 'time': '17:30', 'members': 8, 'joined': false},
    {'route': 'Central Hub to East Suburbs', 'time': '18:00', 'members': 5, 'joined': true},
    {'route': 'Mall of Africa to Midrand', 'time': '18:45', 'members': 3, 'joined': false},
  ];

  final List<Map<String, String>> _safePaths = [
    {'name': 'Morning Route: Noord → Jeppe', 'time': '06:00 – 08:00', 'reports': '0 incidents', 'icon': 'morning'},
    {'name': 'Afternoon Route: Park Station → Soweto', 'time': '15:00 – 18:00', 'reports': '2 minor alerts', 'icon': 'afternoon'},
    {'name': 'Evening Route: Sandton → Alexandra', 'time': '17:30 – 20:00', 'reports': '0 incidents', 'icon': 'evening'},
  ];

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
              'GBV Safe Hub',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Your safety, our priority.',
              style: TextStyle(color: Color(0xFFF9A8D4), fontSize: 12),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSOSSheet,
        backgroundColor: AppColors.critical,
        icon: const Icon(Icons.sos, color: Colors.white),
        label: const Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEHailingAlertCard(),
            const SizedBox(height: 24),
            _buildSafeWalkingGroupsSection(),
            const SizedBox(height: 24),
            _buildOptimizeDropOffCard(),
            const SizedBox(height: 24),
            _buildSafePathsCard(),
            const SizedBox(height: 80), // space for FAB
          ],
        ),
      ),
    );
  }

  // ─── E-Hailing Safe Tracker ────────────────────────────────────────────────

  Widget _buildEHailingAlertCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isTrackingEnabled ? AppColors.surface : AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isTrackingEnabled ? AppColors.critical : const Color(0x0DFFFFFF),
          width: _isTrackingEnabled ? 2.0 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.security,
                    size: 32,
                    color: _isTrackingEnabled ? AppColors.critical : AppColors.secondary,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'E-Hailing Safe Tracker',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Switch(
                value: _isTrackingEnabled,
                activeTrackColor: AppColors.critical,
                onChanged: (val) {
                  setState(() => _isTrackingEnabled = val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(val
                          ? '🚨 Safe Tracking Active: 3 guardians alerted!'
                          : '✅ Safe Tracking Deactivated.'),
                      backgroundColor: val ? AppColors.critical : AppColors.surface,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Automatically alert close family members on booking, arrival, and drop-off via SMS and WhatsApp.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          if (_isTrackingEnabled) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.share_location, size: 16, color: AppColors.critical),
                      SizedBox(width: 8),
                      Text(
                        'Sharing live coordinates with 3 guardians...',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 8),
                  _buildGuardianRow('Mom', '+27 82 123 4567', Icons.check_circle, Colors.green),
                  const SizedBox(height: 6),
                  _buildGuardianRow('Sister', '+27 73 987 6543', Icons.check_circle, Colors.green),
                  const SizedBox(height: 6),
                  _buildGuardianRow('Friend Thandi', '+27 61 555 0011', Icons.schedule, Colors.orange),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.critical),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () => _showAddDestinationDialog(),
                icon: const Icon(Icons.add_location_alt, color: AppColors.critical, size: 18),
                label: const Text('Set Ride Destination', style: TextStyle(color: AppColors.critical, fontWeight: FontWeight.bold)),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildGuardianRow(String name, String phone, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 8),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        Text(phone, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }

  // ─── Safe Walking Groups ───────────────────────────────────────────────────

  Widget _buildSafeWalkingGroupsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Safe Walking Groups',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: _showCreateGroupDialog,
              child: const Text('+ Create New', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _walkingGroups.length,
          itemBuilder: (context, index) {
            final group = _walkingGroups[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x0DFFFFFF)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group['route']!,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(group['time']!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            const SizedBox(width: 16),
                            const Icon(Icons.people, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text('${group['members']} members', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: group['joined'] ? const Color(0xFF1E293B) : AppColors.primary,
                      side: group['joined'] ? const BorderSide(color: Colors.white24) : BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      setState(() {
                        _walkingGroups[index]['joined'] = !_walkingGroups[index]['joined'];
                        if (_walkingGroups[index]['joined']) {
                          _walkingGroups[index]['members']++;
                        } else {
                          _walkingGroups[index]['members']--;
                        }
                      });
                      final joined = _walkingGroups[index]['joined'] as bool;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(joined
                              ? '✅ Joined "${group['route']}"! You will receive a notification 30 min before departure.'
                              : 'Left the group.'),
                          backgroundColor: AppColors.surface,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                    child: Text(
                      group['joined'] ? 'Joined ✓' : 'Join',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── Group Ride Optimizer ──────────────────────────────────────────────────

  Widget _buildOptimizeDropOffCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x0DFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alt_route, color: AppColors.primary),
              const SizedBox(width: 12),
              const Text(
                'Group Ride Optimizer',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Drops are sorted by drop-off area density. The least-populated area is dropped first so remaining passengers stay in a larger, safer group.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          if (_dropOffSequence != null) ...[
            const SizedBox(height: 16),
            const Text('Optimised Drop-Off Order:', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ..._dropOffSequence!.asMap().entries.map((e) {
              final stop = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primary,
                      child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stop['area']!, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(stop['reason']!, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text(stop['passengers']!, style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _isCalculating ? null : _calculateDropOffSequence,
              child: _isCalculating
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : Text(
                      _dropOffSequence == null ? 'Calculate Drop-Off Sequence' : 'Recalculate',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Safe Paths Card ───────────────────────────────────────────────────────

  Widget _buildSafePathsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x0DFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map_outlined, color: AppColors.accent),
              const SizedBox(width: 12),
              const Text(
                'Morning & Afternoon Safe Paths',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Find paths verified by community logs to be safer during high-traffic commute hours.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _showSafePathsDialog,
              child: const Text('View Safe COMMUTE Map', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Actions / Dialogs ─────────────────────────────────────────────────────

  void _showAddDestinationDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Set Ride Destination', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your destination to share with guardians:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. 14 Bree St, Johannesburg',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.location_on, color: AppColors.critical),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.critical, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (controller.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('📍 Destination "${controller.text}" shared with all guardians.'),
                    backgroundColor: AppColors.surface,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
            child: const Text('Share', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog() {
    final routeController = TextEditingController();
    TimeOfDay selectedTime = const TimeOfDay(hour: 17, minute: 30);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Create Walking Group', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Route Description', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: routeController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g. Park Station to Soweto',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.route, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Departure Time', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final t = await showTimePicker(context: ctx, initialTime: selectedTime);
                  if (t != null) setDlgState(() => selectedTime = t);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: AppColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Text(selectedTime.format(ctx), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      const Icon(Icons.edit, color: AppColors.textMuted, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () {
                if (routeController.text.isNotEmpty) {
                  setState(() {
                    _walkingGroups.add({
                      'route': routeController.text,
                      'time': selectedTime.format(ctx),
                      'members': 1,
                      'joined': true,
                    });
                  });
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Walking group created! Members can now join.'),
                      backgroundColor: AppColors.surface,
                    ),
                  );
                }
              },
              child: const Text('Create Group', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _calculateDropOffSequence() async {
    setState(() {
      _isCalculating = true;
      _dropOffSequence = null;
    });

    // Simulate API call / algorithm
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isCalculating = false;
      _dropOffSequence = [
        {'area': 'Diepsloot (North)', 'passengers': '1 passenger', 'reason': 'Least dense — dropped first for group safety'},
        {'area': 'Midrand (Central)', 'passengers': '2 passengers', 'reason': 'Moderate density'},
        {'area': 'Sandton CBD', 'passengers': '3 passengers', 'reason': 'Highest density — final drop-off'},
      ];
    });
  }

  void _showSafePathsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.map, color: AppColors.accent),
                  SizedBox(width: 10),
                  Text('Community-Verified Safe Paths', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Updated daily by community safety logs.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _safePaths.length,
                itemBuilder: (_, i) {
                  final path = _safePaths[i];
                  final hasAlert = path['reports']!.contains('alert');
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: hasAlert ? Colors.orange.withOpacity(0.4) : Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              hasAlert ? Icons.warning_amber_rounded : Icons.verified_user,
                              color: hasAlert ? Colors.orange : Colors.green,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(path['name']!, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 13, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(path['time']!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: hasAlert ? Colors.orange.withOpacity(0.15) : Colors.green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                path['reports']!,
                                style: TextStyle(color: hasAlert ? Colors.orange : Colors.green, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('🗺️ Loading route: ${path['name']}'),
                                  backgroundColor: AppColors.surface,
                                ),
                              );
                            },
                            child: const Text('Use This Route', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSOSSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Icon(Icons.sos, color: AppColors.critical, size: 48),
            const SizedBox(height: 12),
            const Text('Emergency SOS', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'This will immediately alert all your emergency contacts with your current GPS location.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.critical,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🚨 SOS SENT! All 3 guardians have been alerted with your location.'),
                      backgroundColor: AppColors.critical,
                      duration: Duration(seconds: 5),
                    ),
                  );
                },
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text('SEND SOS NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
