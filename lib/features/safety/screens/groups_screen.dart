import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'group_chat_screen.dart';

// ─── Data Models ──────────────────────────────────────────────────────────────

enum GroupSession { morning, evening }

class WalkingGroup {
  final String id;
  final String fromLocation;
  final String toLocation;
  final String departureTime;
  final GroupSession session;
  int members;
  bool joined;

  WalkingGroup({
    required this.id,
    required this.fromLocation,
    required this.toLocation,
    required this.departureTime,
    required this.session,
    this.members = 1,
    this.joined = false,
  });

  String get route => '$fromLocation → $toLocation';
}

class TaxiGroup {
  final String destination;
  final int passengerCount;
  final List<TaxiPassenger> passengers;

  TaxiGroup({
    required this.destination,
    required this.passengerCount,
    required this.passengers,
  });
}

class TaxiPassenger {
  final String name;
  final String dropOff;
  final double distanceKm;

  const TaxiPassenger({
    required this.name,
    required this.dropOff,
    required this.distanceKm,
  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Walking Groups state
  GroupSession _selectedSession = GroupSession.morning;
  final List<WalkingGroup> _walkingGroups = [
    WalkingGroup(
      id: 'wg1',
      fromLocation: 'Park Station',
      toLocation: 'Noord Taxi Rank',
      departureTime: '06:00',
      session: GroupSession.morning,
      members: 12,
    ),
    WalkingGroup(
      id: 'wg2',
      fromLocation: 'Bree St Rank',
      toLocation: 'Jeppe Station',
      departureTime: '07:15',
      session: GroupSession.morning,
      members: 7,
    ),
    WalkingGroup(
      id: 'wg3',
      fromLocation: 'Jeppe Station',
      toLocation: 'Berea Community Centre',
      departureTime: '06:45',
      session: GroupSession.morning,
      members: 4,
    ),
    WalkingGroup(
      id: 'wg4',
      fromLocation: 'Park Station',
      toLocation: 'Soweto Taxi Rank',
      departureTime: '17:00',
      session: GroupSession.evening,
      members: 9,
    ),
    WalkingGroup(
      id: 'wg5',
      fromLocation: 'Sandton City',
      toLocation: 'Alexandra Township',
      departureTime: '17:30',
      session: GroupSession.evening,
      members: 6,
    ),
    WalkingGroup(
      id: 'wg6',
      fromLocation: 'Mall of Africa',
      toLocation: 'Midrand Station',
      departureTime: '18:45',
      session: GroupSession.evening,
      members: 3,
    ),
  ];

  // Taxi Finder state
  final TextEditingController _destinationController = TextEditingController();
  bool _isSearching = false;
  TaxiGroup? _foundGroup;
  bool _showNoGroup = false;

  List<WalkingGroup> get _filteredGroups =>
      _walkingGroups.where((g) => g.session == _selectedSession).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _destinationController.dispose();
    super.dispose();
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
              'Safety Groups',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Walk and travel together, stay safe.',
              style: TextStyle(color: Color(0xFFF9A8D4), fontSize: 12),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFEC4899),
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: const Color(0xFFEC4899),
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: '👣  Walking Groups'),
            Tab(text: '🚌  Taxi Finder'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWalkingGroupsTab(),
          _buildTaxiFinderTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _showCreateGroupDialog,
              backgroundColor: const Color(0xFFEC4899),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('New Group',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  // ─── Walking Groups Tab ───────────────────────────────────────────────────

  Widget _buildWalkingGroupsTab() {
    return Column(
      children: [
        _buildSessionToggle(),
        Expanded(
          child: _filteredGroups.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: _filteredGroups.length,
                  itemBuilder: (_, i) => _buildWalkingGroupCard(_filteredGroups[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildSessionToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            _sessionToggleButton(
              label: '🌅  Morning Groups',
              subtitle: '05:30 – 08:00',
              session: GroupSession.morning,
            ),
            _sessionToggleButton(
              label: '🌆  Evening Groups',
              subtitle: '16:00 – 20:00',
              session: GroupSession.evening,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sessionToggleButton({
    required String label,
    required String subtitle,
    required GroupSession session,
  }) {
    final selected = _selectedSession == session;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSession = session),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEC4899) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: selected ? Colors.white70 : AppColors.textMuted,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalkingGroupCard(WalkingGroup group) {
    final joined = group.joined;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: joined ? const Color(0xFFEC4899).withValues(alpha: 0.4) : Colors.white10,
          width: joined ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: group.session == GroupSession.morning
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                        : const Color(0xFF6366F1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    group.session == GroupSession.morning
                        ? Icons.wb_sunny_outlined
                        : Icons.nights_stay_outlined,
                    color: group.session == GroupSession.morning
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.route,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 12, color: Color(0xFFF9A8D4)),
                          const SizedBox(width: 4),
                          Text(
                            'Departs ${group.departureTime}',
                            style: const TextStyle(color: Color(0xFFF9A8D4), fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('👩 Women\'s', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.people, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${group.members} members',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const Spacer(),
                SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: joined ? Colors.transparent : const Color(0xFFEC4899),
                      foregroundColor: Colors.white,
                      side: joined ? const BorderSide(color: Color(0xFFEC4899)) : BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      elevation: 0,
                    ),
                    onPressed: () {
                      final idx = _walkingGroups.indexOf(group);
                      setState(() {
                        _walkingGroups[idx].joined = !_walkingGroups[idx].joined;
                        _walkingGroups[idx].members += _walkingGroups[idx].joined ? 1 : -1;
                      });
                      final nowJoined = _walkingGroups[idx].joined;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(nowJoined
                            ? '✅ Joined! You\'ll get a reminder 15 min before departure.'
                            : 'Left the group.'),
                        backgroundColor: AppColors.surface,
                        duration: const Duration(seconds: 3),
                      ));
                    },
                    child: Text(
                      joined ? '✓ Joined' : 'Join',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups_outlined, color: AppColors.textMuted, size: 56),
          const SizedBox(height: 16),
          const Text('No groups in this session yet.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _showCreateGroupDialog,
            child: const Text('+ Create the first one', style: TextStyle(color: Color(0xFFEC4899))),
          ),
        ],
      ),
    );
  }

  // ─── Taxi Finder Tab ──────────────────────────────────────────────────────

  Widget _buildTaxiFinderTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildDestinationSearchCard(),
          if (_isSearching) ...[
            const SizedBox(height: 24),
            _buildSearchingAnimation(),
          ],
          if (_foundGroup != null) ...[
            const SizedBox(height: 24),
            _buildGroupFoundCard(_foundGroup!),
          ],
          if (_showNoGroup && !_isSearching && _foundGroup == null) ...[
            const SizedBox(height: 24),
            _buildWaitingForGroupCard(),
          ],
          const SizedBox(height: 24),
          _buildHowItWorksCard(),
        ],
      ),
    );
  }

  Widget _buildDestinationSearchCard() {
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
              Icon(Icons.search, color: Color(0xFFEC4899), size: 20),
              SizedBox(width: 8),
              Text(
                'Find Your Taxi Group',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your destination — we\'ll find 3+ women going the same way.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _destinationController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Where are you going?',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.location_on, color: Color(0xFFEC4899)),
              suffixIcon: _destinationController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                      onPressed: () {
                        setState(() {
                          _destinationController.clear();
                          _foundGroup = null;
                          _showNoGroup = false;
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC4899),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              onPressed: _destinationController.text.trim().isEmpty || _isSearching
                  ? null
                  : _searchForTaxiGroup,
              child: const Text(
                'Find Group',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingAnimation() {
    return Center(
      child: Column(
        children: [
          const SizedBox(
            height: 48,
            width: 48,
            child: CircularProgressIndicator(
              color: Color(0xFFEC4899),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Scanning for nearby passengers...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Checking ${_destinationController.text}',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupFoundCard(TaxiGroup group) {
    // Sort by distance descending (furthest first)
    final sorted = [...group.passengers]
      ..sort((a, b) => b.distanceKm.compareTo(a.distanceKm));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Group Found!',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${group.passengerCount} women heading to ${group.destination}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),

        // Drop-off sequence
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.alt_route, color: AppColors.primary, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Drop-Off Order  (Furthest First)',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'The person going furthest is dropped first so the group stays largest and safest for the longest.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 14),
              ...sorted.asMap().entries.map((e) {
                final stop = e.value;
                final idx = e.key;
                final isLast = idx == sorted.length - 1;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: idx == 0
                              ? const Color(0xFFEC4899)
                              : AppColors.primary.withValues(alpha: 0.7),
                          child: Text(
                            '${idx + 1}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 36,
                            color: Colors.white10,
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stop.dropOff,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  '${stop.distanceKm.toStringAsFixed(1)} km from pickup',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '• ${stop.name}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                            if (idx == 0)
                              const Padding(
                                padding: EdgeInsets.only(top: 3),
                                child: Text(
                                  '🛡️ Furthest — dropped first for group safety',
                                  style: TextStyle(color: Color(0xFFEC4899), fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ),
                            if (isLast)
                              const Padding(
                                padding: EdgeInsets.only(top: 3),
                                child: Text(
                                  '🏠 Closest — largest group until the end',
                                  style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC4899),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => GroupChatScreen(
                      destination: group.destination,
                      passengers: group.passengers,
                    ),
                  ));
                },
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
                label: const Text(
                  'Join Group Chat',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWaitingForGroupCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_empty, color: Color(0xFFF59E0B), size: 36),
          const SizedBox(height: 12),
          const Text(
            'Waiting for group...',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Only 1-2 women found going this way right now. You\'ll be notified as soon as 3+ join.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
              foregroundColor: const Color(0xFFF59E0B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('🔔 You\'ll be notified when 3+ women are going your way.'),
                backgroundColor: AppColors.surface,
              ));
            },
            child: const Text('Notify Me When Ready', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How Taxi Groups Work', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _howItWorksStep('1', 'Enter your destination', Icons.location_on_outlined),
          _howItWorksStep('2', '3+ women going same way are matched', Icons.group_add_outlined),
          _howItWorksStep('3', 'Furthest passenger is dropped off first', Icons.alt_route),
          _howItWorksStep('4', 'Group chat keeps everyone connected', Icons.chat_outlined),
        ],
      ),
    );
  }

  Widget _howItWorksStep(String num, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: const Color(0xFFEC4899).withValues(alpha: 0.2),
            child: Text(num, style: const TextStyle(color: Color(0xFFEC4899), fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Icon(icon, color: AppColors.textSecondary, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> _searchForTaxiGroup() async {
    setState(() {
      _isSearching = true;
      _foundGroup = null;
      _showNoGroup = false;
    });

    await Future.delayed(const Duration(seconds: 3));

    // Simulate: 70% chance of finding a group
    final found = DateTime.now().millisecond % 10 < 7;

    setState(() {
      _isSearching = false;
      if (found) {
        _foundGroup = TaxiGroup(
          destination: _destinationController.text,
          passengerCount: 4,
          passengers: [
            TaxiPassenger(name: 'You', dropOff: _destinationController.text, distanceKm: 8.2),
            TaxiPassenger(name: 'Nomsa M.', dropOff: 'Diepkloof Ext 2', distanceKm: 14.7),
            TaxiPassenger(name: 'Thandi K.', dropOff: 'Meadowlands Zone 6', distanceKm: 11.3),
            TaxiPassenger(name: 'Lerato B.', dropOff: 'Pimville', distanceKm: 9.8),
          ],
        );
      } else {
        _showNoGroup = true;
      }
    });
  }

  void _showCreateGroupDialog() {
    final fromController = TextEditingController();
    final toController = TextEditingController();
    GroupSession session = GroupSession.morning;
    TimeOfDay selectedTime = const TimeOfDay(hour: 6, minute: 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.group_add, color: Color(0xFFEC4899), size: 22),
              SizedBox(width: 10),
              Text('Create Walking Group', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('From', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: fromController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Starting location',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.my_location, color: Color(0xFFEC4899), size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('To', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: toController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Destination',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.location_on, color: Color(0xFFEC4899), size: 18),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Session', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setDlgState(() => session = GroupSession.morning),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: session == GroupSession.morning
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: session == GroupSession.morning
                                  ? const Color(0xFFF59E0B)
                                  : Colors.white10,
                            ),
                          ),
                          child: const Column(
                            children: [
                              Text('🌅', style: TextStyle(fontSize: 18)),
                              Text('Morning', style: TextStyle(color: Colors.white, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setDlgState(() {
                          session = GroupSession.evening;
                          selectedTime = const TimeOfDay(hour: 17, minute: 0);
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: session == GroupSession.evening
                                ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: session == GroupSession.evening
                                  ? const Color(0xFF6366F1)
                                  : Colors.white10,
                            ),
                          ),
                          child: const Column(
                            children: [
                              Text('🌆', style: TextStyle(fontSize: 18)),
                              Text('Evening', style: TextStyle(color: Colors.white, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
                        const Icon(Icons.access_time, color: Color(0xFFEC4899), size: 18),
                        const SizedBox(width: 10),
                        Text(selectedTime.format(ctx),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        const Icon(Icons.edit, color: AppColors.textMuted, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC4899),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (fromController.text.isNotEmpty && toController.text.isNotEmpty) {
                  setState(() {
                    _walkingGroups.add(WalkingGroup(
                      id: 'wg_${DateTime.now().millisecondsSinceEpoch}',
                      fromLocation: fromController.text,
                      toLocation: toController.text,
                      departureTime: '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                      session: session,
                      members: 1,
                      joined: true,
                    ));
                    _selectedSession = session;
                  });
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('✅ Group created! Share the code with friends.'),
                    backgroundColor: AppColors.surface,
                  ));
                }
              },
              child: const Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
