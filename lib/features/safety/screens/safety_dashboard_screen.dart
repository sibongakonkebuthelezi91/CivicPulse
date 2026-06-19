import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../services/alert_service.dart';

class SafetyDashboardScreen extends StatefulWidget {
  const SafetyDashboardScreen({super.key});

  @override
  State<SafetyDashboardScreen> createState() => _SafetyDashboardScreenState();
}

class _SafetyDashboardScreenState extends State<SafetyDashboardScreen> {
  bool _isTrackingEnabled = false;

  // Guardian contacts loaded from local auth — using hardcoded demo contacts
  final List<Map<String, String>> _guardians = [
    {'name': 'Mom',          'phone': '+27821234567'},
    {'name': 'Sister',       'phone': '+27739876543'},
    {'name': 'Friend Thandi','phone': '+27615550011'},
  ];

  List<String> get _guardianPhones => _guardians.map((g) => g['phone']!).toList();

  final List<Map<String, String>> _safePaths = [
    {'name': 'Morning: Noord → Jeppe', 'time': '06:00–08:00', 'reports': '0 incidents'},
    {'name': 'Afternoon: Park Station → Soweto', 'time': '15:00–18:00', 'reports': '2 minor alerts'},
    {'name': 'Evening: Sandton → Alexandra', 'time': '17:30–20:00', 'reports': '0 incidents'},
  ];

  Future<void> _activateTracking(String destination) async {
    setState(() => _isTrackingEnabled = true);
    final msg = AlertService.eHailingTracking(
      name: 'Me',
      destination: destination.isEmpty ? 'my destination' : destination,
    );
    await AlertService.alertAll(contacts: _guardianPhones, message: msg);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('🚨 Safe Tracking Active — WhatsApp & SMS sent to guardians!'),
      backgroundColor: AppColors.critical,
      duration: Duration(seconds: 3),
    ));
  }

  Future<void> _sendSOS() async {
    final msg = AlertService.sosAlert(name: 'Me', location: null);
    await AlertService.alertAll(contacts: _guardianPhones, message: msg);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('🚨 SOS SENT! WhatsApp & SMS alert sent to all guardians.'),
      backgroundColor: AppColors.critical,
      duration: Duration(seconds: 5),
    ));
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
              style: TextStyle(color: AppColors.accent, fontSize: 12),
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
        heroTag: 'sos_fab',
        onPressed: _showSOSSheet,
        backgroundColor: AppColors.critical,
        icon: const Icon(Icons.sos, color: Colors.white),
        label: const Text('SOS',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEHailingAlertCard(),
            const SizedBox(height: 24),
            _buildQuickLinksRow(context),
            const SizedBox(height: 24),
            _buildSafePathsCard(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ─── E-Hailing Safe Tracker ───────────────────────────────────────────────

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
                    size: 30,
                    color: _isTrackingEnabled ? AppColors.critical : AppColors.secondary,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'E-Hailing Safe Tracker',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Switch(
                value: _isTrackingEnabled,
                activeTrackColor: AppColors.critical,
                onChanged: (val) {
                  if (val) {
                    _activateTracking('');
                  } else {
                    setState(() => _isTrackingEnabled = false);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('✅ Safe Tracking Deactivated.'),
                      backgroundColor: AppColors.surface,
                      duration: Duration(seconds: 2),
                    ));
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Automatically alert family members on booking, arrival, and drop-off via SMS and WhatsApp.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          if (_isTrackingEnabled) ...[
            const SizedBox(height: 14),
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
                      Icon(Icons.share_location, size: 14, color: AppColors.critical),
                      SizedBox(width: 8),
                      Text('Sharing live coordinates with 3 guardians...',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 10),
                  _guardianRow('Mom', '+27 82 123 4567', true),
                  const SizedBox(height: 6),
                  _guardianRow('Sister', '+27 73 987 6543', true),
                  const SizedBox(height: 6),
                  _guardianRow('Friend Thandi', '+27 61 555 0011', false),
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
                onPressed: _showAddDestinationDialog,
                icon: const Icon(Icons.add_location_alt, color: AppColors.critical, size: 18),
                label: const Text('Set Ride Destination',
                    style: TextStyle(color: AppColors.critical, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _guardianRow(String name, String phone, bool delivered) {
    return Row(
      children: [
        Icon(delivered ? Icons.check_circle : Icons.schedule,
            size: 14, color: delivered ? Colors.green : Colors.orange),
        const SizedBox(width: 8),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        Text(phone, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }

  // ─── Quick Links ──────────────────────────────────────────────────────────

  Widget _buildQuickLinksRow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _quickLinkCard(
                icon: Icons.groups,
                label: 'Walking\nGroups',
                color: AppColors.primary,
                onTap: () {
                  // Switch to Groups tab via parent shell
                  context.findAncestorStateOfType<State>()?.setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tap the "Groups" tab below 👇'), backgroundColor: AppColors.surface),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _quickLinkCard(
                icon: Icons.directions_bus,
                label: 'Taxi\nFinder',
                color: AppColors.primary,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tap the "Groups" tab below 👇'), backgroundColor: AppColors.surface),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _quickLinkCard(
                icon: Icons.route,
                label: 'Journey\nTracker',
                color: AppColors.accent,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tap the "Journey" tab below 👇'), backgroundColor: AppColors.surface),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickLinkCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Safe Paths ───────────────────────────────────────────────────────────

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
          const Row(
            children: [
              Icon(Icons.map_outlined, color: AppColors.accent),
              SizedBox(width: 12),
              Text('Community Safe Paths',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Routes verified by community logs to be safer during commute hours.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ..._safePaths.map((path) {
            final hasAlert = path['reports']!.contains('alert');
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasAlert
                      ? Colors.orange.withValues(alpha: 0.3)
                      : Colors.green.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasAlert ? Icons.warning_amber_rounded : Icons.verified_user,
                    color: hasAlert ? Colors.orange : Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(path['name']!,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(path['time']!, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: hasAlert ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      path['reports']!,
                      style: TextStyle(
                          color: hasAlert ? Colors.orange : Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Dialogs ──────────────────────────────────────────────────────────────

  void _showAddDestinationDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Set Ride Destination',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.critical,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (controller.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('📍 "${controller.text}" shared with guardians.'),
                  backgroundColor: AppColors.surface,
                  duration: const Duration(seconds: 4),
                ));
              }
            },
            child: const Text('Share', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
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
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('🚨 SOS SENT! All 3 guardians alerted with your location.'),
                    backgroundColor: AppColors.critical,
                    duration: Duration(seconds: 5),
                  ));
                },
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text('SEND SOS NOW',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
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
