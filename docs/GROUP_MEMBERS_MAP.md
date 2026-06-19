# Group Members Location Map Feature

## Overview

This feature displays a real-time map showing the locations of all group members during safety group activities. It's integrated into the Safety Groups screen and provides a visual way to monitor group cohesion and member locations.

## Architecture

### Components

#### 1. **GroupMemberLocation Model** (`group_members_map.dart`)

- Data class representing a single group member's location
- Fields:
  - `memberId`: Unique identifier for the member
  - `memberName`: Display name of the member
  - `latitude`, `longitude`: GPS coordinates
  - `lastUpdated`: Timestamp of last location update
  - `isOnline`: Boolean indicating connectivity status

#### 2. **GroupMembersMap Widget** (`group_members_map.dart`)

Main interactive map component featuring:

- **Map Tile Layer**: Uses CartoDB Dark Matter tiles for professional appearance
- **Member Markers**: Circular avatars with:
  - Color coding (green=online, grey=offline)
  - Initials of member name
  - Online/offline indicator dot
- **User Location Marker**: Distinct blue marker showing current user
- **Route Polyline**: Visual representation of group's journey path
- **Dynamic Centering**: Auto-centers map to fit all members
- **Bottom Sheet**: Detailed member information when marker is tapped

Features:

```dart
- Auto-calculated zoom level based on member distribution
- Tap handlers for member interaction
- Time-formatted "last updated" display
- Responsive layout for different screen sizes
```

#### 3. **GroupMembersLocationScreen** (`group_members_location_screen.dart`)

Full-screen interface with:

- **Top AppBar**: Shows group route and "Live Map" title
- **Main Map Area**: Full GroupMembersMap widget
- **Bottom Panel**:
  - Member count with online status
  - Horizontal scrollable member list with avatars
  - Quick member status visualization

## Usage

### Opening the Map

```dart
// From groups_screen.dart - "Map" button opens the screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => GroupMembersLocationScreen(group: group),
  ),
);
```

### Displaying Member Locations

```dart
// Create member location data
final members = [
  GroupMemberLocation(
    memberId: 'user123',
    memberName: 'Sarah Johnson',
    latitude: -26.2040,
    longitude: 28.0470,
    lastUpdated: DateTime.now(),
    isOnline: true,
  ),
  // ... more members
];

// Pass to map widget
GroupMembersMap(
  group: group,
  memberLocations: members,
  userLocation: LatLng(-26.2041, 28.0473),
  onMemberTapped: (memberId, memberName) {
    print('Tapped $memberName');
  },
);
```

## Backend Integration

### Current State

- **Mock Data**: Uses hardcoded member locations for demonstration
- **Location Data**: Mock members in `group_members_location_screen.dart` (lines 25-71)

### Required Backend Endpoints

To connect to live location data, implement these endpoints:

#### 1. Get Group Members' Locations

```
GET /api/v1/groups/{groupId}/members/locations

Response:
{
  "members": [
    {
      "id": "member1",
      "name": "Sarah Johnson",
      "latitude": -26.2040,
      "longitude": 28.0470,
      "last_updated": "2026-06-19T10:30:00Z",
      "is_online": true
    }
  ]
}
```

#### 2. Live Location Updates (Optional - WebSocket)

```
WebSocket: wss://api.civicpulse.app/groups/{groupId}/live-locations

Frame:
{
  "type": "location_update",
  "member_id": "member1",
  "latitude": -26.2040,
  "longitude": 28.0470,
  "timestamp": "2026-06-19T10:30:15Z"
}
```

### Integration Steps

1. Update `_initializeMemberLocations()` in `GroupMembersLocationScreen`:

   ```dart
   void _initializeMemberLocations() async {
     final response = await http.get(
       Uri.parse('/api/v1/groups/${widget.group.id}/members/locations'),
     );

     if (response.statusCode == 200) {
       final data = jsonDecode(response.body);
       setState(() {
         _memberLocations = (data['members'] as List)
             .map((m) => GroupMemberLocation.fromJson(m))
             .toList();
       });
     }
   }
   ```

2. Add WebSocket listener for real-time updates (optional)

## Design Details

### Color Scheme

- **Online Members**: Green (#10B981)
- **Offline Members**: Grey (#6B7280)
- **User Location**: Blue (#3B82F6)
- **Route Line**: Blue with opacity

### Visual Indicators

- **Status Dot**: Bottom-right corner of member avatar (online=green, offline=grey)
- **Text Labels**: Member first name below avatar
- **Card Design**: Dark background for contrast with map

### Responsive Behavior

- Map automatically fits all members in view
- Bottom member list scrolls horizontally
- Member cards are tappable for details
- Details open in modal bottom sheet

## Testing

### Test Data (Already Included)

Mock members with various:

- Geographic spreads
- Online/offline statuses
- Time-staggered last updates

### Manual Testing Checklist

- [ ] Map centers correctly on all members
- [ ] Member markers are clickable
- [ ] Bottom sheet shows correct member details
- [ ] Member list scrolls horizontally
- [ ] Online count updates correctly
- [ ] Time formatting displays properly
- [ ] User location marker displays
- [ ] Zoom level appropriate for member distribution

## Future Enhancements

1. **Real-time Updates**
   - WebSocket connection for live location streaming
   - Animated marker movements

2. **Advanced Features**
   - Route history replay
   - Geofence alerts
   - Member panic button integration
   - Distance calculations between members

3. **Performance**
   - Tile caching with flutter_map_cache
   - Marker clustering for large groups
   - Location update throttling

4. **Customization**
   - Custom tile providers
   - Theme variations
   - Export/share map screenshots

## Troubleshooting

### Map Not Displaying

- Ensure `flutter_map` and `latlong2` are installed in pubspec.yaml
- Check that CartoDB tile service is accessible
- Verify `MapController` is properly initialized

### Markers Not Appearing

- Confirm `memberLocations` list is not empty
- Verify latitude/longitude are valid coordinate ranges
- Check marker build methods for null errors

### Performance Issues

- Reduce number of markers displayed
- Implement marker clustering for large groups
- Use tile caching

## Files Reference

- **Map Widget**: `lib/src/mapping/group_members_map.dart`
- **Screen**: `lib/features/safety/screens/group_members_location_screen.dart`
- **Integration**: `lib/features/safety/screens/groups_screen.dart`
