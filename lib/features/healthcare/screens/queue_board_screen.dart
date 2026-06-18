import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class QueueBoardScreen extends StatelessWidget {
  const QueueBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock queue state (in production, this would be updated in real-time via Supabase WebSockets)
    final List<Map<String, dynamic>> mockQueue = [
      {'ticket': 'P-104', 'triage': 'Critical', 'status': 'Serving', 'color': AppColors.critical},
      {'ticket': 'P-105', 'triage': 'Urgent', 'status': 'Next', 'color': AppColors.urgent},
      {'ticket': 'P-106', 'triage': 'Routine', 'status': 'Waiting', 'color': AppColors.routine},
      {'ticket': 'P-107', 'triage': 'Routine', 'status': 'Waiting', 'color': AppColors.routine},
      {'ticket': 'P-108', 'triage': 'Urgent', 'status': 'Waiting', 'color': AppColors.urgent},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Live Queue Board',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBar(),
            const SizedBox(height: 24),
            const Text(
              'Active Waiting List',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: mockQueue.length,
                itemBuilder: (context, index) {
                  final item = mockQueue[index];
                  final isServing = item['status'] == 'Serving';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isServing ? AppColors.surface : const Color(0x80222235),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isServing ? AppColors.primary : const Color(0x0DFFFFFF),
                        width: isServing ? 2.0 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item['ticket']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: item['color'] as Color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item['triage']!,
                                      style: TextStyle(
                                        color: item['color'] as Color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isServing
                                ? const Color(0x336366F1)
                                : const Color(0x0DFFFFFF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item['status']!,
                            style: TextStyle(
                              color: isServing ? AppColors.primary : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
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

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x0DFFFFFF)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text('Estimated Wait', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              SizedBox(height: 6),
              Text('25 Mins', style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          VerticalDivider(color: Colors.white24, width: 1, thickness: 1),
          Column(
            children: [
              Text('Patients Ahead', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              SizedBox(height: 6),
              Text('4 People', style: TextStyle(color: AppColors.secondary, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
