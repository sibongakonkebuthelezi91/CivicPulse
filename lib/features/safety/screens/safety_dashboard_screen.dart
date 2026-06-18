import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SafetyDashboardScreen extends StatefulWidget {
  const SafetyDashboardScreen({super.key});

  @override
  State<SafetyDashboardScreen> createState() => _SafetyDashboardScreenState();
}

class _SafetyDashboardScreenState extends State<SafetyDashboardScreen> {
  bool _isTrackingEnabled = false;
  final List<Map<String, dynamic>> _walkingGroups = [
    {'route': 'Station A to High Street', 'time': '17:30', 'members': 8, 'joined': false},
    {'route': 'Central Hub to East Suburbs', 'time': '18:00', 'members': 5, 'joined': true},
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
          ],
        ),
      ),
    );
  }

  Widget _buildEHailingAlertCard() {
    return Container(
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
                        ? 'Safe Tracking Active: Contacts alerted!' 
                        : 'Safe Tracking Deactivated.'
                      ),
                      backgroundColor: val ? AppColors.critical : AppColors.surface,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.share, size: 16, color: AppColors.critical),
                  SizedBox(width: 8),
                  Text(
                    'Sharing live coordinates with 3 guardians...',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

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
              onPressed: () {},
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
                      backgroundColor: group['joined'] ? AppColors.surface : AppColors.primary,
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
                    },
                    child: Text(
                      group['joined'] ? 'Joined' : 'Join',
                      style: const TextStyle(fontSize: 12),
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
            'Drops are sorted by drop-off area density. The location with the least volume is dropped off first to ensure the remaining passengers travel in a larger, safer group.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                // Open drop-off order dialog or navigation
              },
              child: const Text('Calculate Drop-Off Sequence', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

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
              onPressed: () {
                // View safe paths on map
              },
              child: const Text('View Safe COMMUTE Map', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
