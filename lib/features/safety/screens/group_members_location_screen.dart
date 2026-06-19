import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../src/mapping/group_members_map.dart';
import 'groups_screen.dart';
import '../../../core/constants/app_colors.dart';

class GroupMembersLocationScreen extends StatefulWidget {
  final WalkingGroup group;

  const GroupMembersLocationScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupMembersLocationScreen> createState() =>
      _GroupMembersLocationScreenState();
}

class _GroupMembersLocationScreenState
    extends State<GroupMembersLocationScreen> {
  // Mock member locations - in a real app, these would come from the backend
  late List<GroupMemberLocation> _memberLocations;

  // Mock user location
  final _userLocation = const LatLng(-26.2041, 28.0473);

  @override
  void initState() {
    super.initState();
    _initializeMemberLocations();
  }

  void _initializeMemberLocations() {
    // Generate mock locations for group members
    _memberLocations = [
      GroupMemberLocation(
        memberId: 'member1',
        memberName: 'Sarah Johnson',
        latitude: -26.2040,
        longitude: 28.0470,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 2)),
        isOnline: true,
      ),
      GroupMemberLocation(
        memberId: 'member2',
        memberName: 'Amara Okafor',
        latitude: -26.2050,
        longitude: 28.0480,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
        isOnline: true,
      ),
      GroupMemberLocation(
        memberId: 'member3',
        memberName: 'Emma Williams',
        latitude: -26.2035,
        longitude: 28.0460,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 1)),
        isOnline: true,
      ),
      GroupMemberLocation(
        memberId: 'member4',
        memberName: 'Maria Santos',
        latitude: -26.2060,
        longitude: 28.0490,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 8)),
        isOnline: true,
      ),
      GroupMemberLocation(
        memberId: 'member5',
        memberName: 'Lisa Chen',
        latitude: -26.2055,
        longitude: 28.0465,
        lastUpdated: DateTime.now().subtract(const Duration(hours: 1)),
        isOnline: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.group.route} - Live Map',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Map view
          Expanded(
            child: GroupMembersMap(
              group: widget.group,
              memberLocations: _memberLocations,
              userLocation: _userLocation,
              onMemberTapped: (memberId, memberName) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Viewing location of $memberName'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),

          // Members list at bottom
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(
                top: BorderSide(color: Colors.grey[700]!, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Group Members (${_memberLocations.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_memberLocations.where((m) => m.isOnline).length} online',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _memberLocations.length,
                      itemBuilder: (context, index) {
                        final member = _memberLocations[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () {
                              // Tap to focus on member on map
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: member.isOnline
                                            ? Colors.green
                                            : Colors.grey,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          member.memberName.characters.first
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: member.isOnline
                                            ? Colors.green
                                            : Colors.grey,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  member.memberName.split(' ').first,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
