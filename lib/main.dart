import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/healthcare/screens/intake_form_screen.dart';
import 'features/healthcare/screens/queue_board_screen.dart';
import 'features/safety/screens/safety_dashboard_screen.dart';
import 'features/infrastructure/screens/report_incident_screen.dart';

void main() {
  runApp(const CivicPulseApp());
}

class CivicPulseApp extends StatelessWidget {
  const CivicPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CivicPulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildStatsSection(),
              const SizedBox(height: 32),
              const Text(
                'Key Programs',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildProgramCard(
                context,
                title: 'Healthcare Portal',
                description: 'Queue management, instant check-in, and multi-language triage routing.',
                icon: Icons.medical_services_outlined,
                gradientColors: [AppColors.primary, AppColors.secondary],
                onTap: () {
                  _showHealthcareOptions(context);
                },
              ),
              const SizedBox(height: 16),
              _buildProgramCard(
                context,
                title: 'GBV & Safety Hub',
                description: 'E-hailing safety alerts, safe commute groups, and drop-off optimization.',
                icon: Icons.security_outlined,
                gradientColors: [const Color(0xFFEC4899), const Color(0xFFF43F5E)],
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SafetyDashboardScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildProgramCard(
                context,
                title: 'Infrastructure & Roads',
                description: 'Report and trace potholes, faulty traffic signals, and animal crossing hazards offline.',
                icon: Icons.alt_route_outlined,
                gradientColors: [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ReportIncidentScreen()),
                  );
                },
              ),
            ],
          ),
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
            Text(
              'CivicPulse',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Active community solutions.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x0DFFFFFF)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Potholes Logs', '12 Active', AppColors.urgent),
          Container(height: 30, width: 1, color: Colors.white12),
          _buildStatItem('Safe Walks', '4 Groups', const Color(0xFFEC4899)),
          Container(height: 30, width: 1, color: Colors.white12),
          _buildStatItem('HC Waiting Time', '~25 Mins', AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: accentColor, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildProgramCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x0DFFFFFF)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showHealthcareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Healthcare Portal',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.assignment_ind_outlined, color: AppColors.primary),
                title: const Text('Check-In (Intake Form)', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const IntakeFormScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.dashboard_outlined, color: AppColors.secondary),
                title: const Text('Live Queue Board', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const QueueBoardScreen()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
