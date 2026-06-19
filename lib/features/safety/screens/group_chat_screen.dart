import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'groups_screen.dart' show TaxiPassenger;

class GroupChatScreen extends StatefulWidget {
  final String destination;
  final List<TaxiPassenger> passengers;

  const GroupChatScreen({
    super.key,
    required this.destination,
    required this.passengers,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _ChatMessage {
  final String sender;
  final String text;
  final bool isMe;
  final DateTime time;

  _ChatMessage({
    required this.sender,
    required this.text,
    required this.isMe,
    required this.time,
  });
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late List<_ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _messages = [
      _ChatMessage(sender: 'Nomsa M.', text: 'Hi everyone! Where are you all boarding from?', isMe: false, time: now.subtract(const Duration(minutes: 8))),
      _ChatMessage(sender: 'Thandi K.', text: 'I\'m at the taxi rank near Park Station 🙋‍♀️', isMe: false, time: now.subtract(const Duration(minutes: 7))),
      _ChatMessage(sender: 'Lerato B.', text: 'Same! I\'ll be the one in the green jacket 😊', isMe: false, time: now.subtract(const Duration(minutes: 5))),
      _ChatMessage(sender: 'Me', text: 'On my way, give me 3 minutes!', isMe: true, time: now.subtract(const Duration(minutes: 3))),
      _ChatMessage(sender: 'Nomsa M.', text: 'No rush, driver says we leave at :30 👍', isMe: false, time: now.subtract(const Duration(minutes: 2))),
    ];
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(
        sender: 'Me',
        text: text.trim(),
        isMe: true,
        time: DateTime.now(),
      ));
      _msgController.clear();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    // Simulate a reply after 2s
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final replies = [
        ('Thandi K.', 'Got it! 👍'),
        ('Nomsa M.', 'Thanks for letting us know 😊'),
        ('Lerato B.', 'Perfect, see you soon!'),
      ];
      final reply = replies[DateTime.now().second % replies.length];
      setState(() {
        _messages.add(_ChatMessage(
          sender: reply.$1,
          text: reply.$2,
          isMe: false,
          time: DateTime.now(),
        ));
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group → ${widget.destination}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.passengers.length} members',
              style: const TextStyle(color: Color(0xFFF9A8D4), fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline, color: Colors.white),
            onPressed: _showMembersSheet,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white10),
        ),
      ),
      body: Column(
        children: [
          _buildMemberAvatarRow(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _buildMessageBubble(_messages[i]),
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMemberAvatarRow() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          ...widget.passengers.map((p) {
            final isMe = p.name == 'You';
            final initials = isMe ? 'Me' : p.name.substring(0, 2).toUpperCase();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isMe
                        ? const Color(0xFFEC4899)
                        : AppColors.primary.withOpacity(0.7),
                    child: Text(initials,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isMe ? 'You' : p.name.split(' ').first,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
                  ),
                ],
              ),
            );
          }),
          const Spacer(),
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              backgroundColor: const Color(0xFFEC4899).withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('📍 Your live location shared with the group.'),
                backgroundColor: AppColors.surface,
              ));
            },
            icon: const Icon(Icons.share_location, color: Color(0xFFEC4899), size: 14),
            label: const Text('Share Location', style: TextStyle(color: Color(0xFFEC4899), fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    final timeStr =
        '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary.withOpacity(0.5),
              child: Text(
                msg.sender.substring(0, 2).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!msg.isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, left: 4),
                    child: Text(msg.sender,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: msg.isMe ? const Color(0xFFEC4899) : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
                      bottomRight: Radius.circular(msg.isMe ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isMe ? Colors.white : AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                  child: Text(timeStr,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
                ),
              ],
            ),
          ),
          if (msg.isMe) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFFEC4899),
              child: Text('Me', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Message the group...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_msgController.text),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFEC4899),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  void _showMembersSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Group Members', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Heading to: ${widget.destination}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 16),
            ...widget.passengers.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: p.name == 'You' ? const Color(0xFFEC4899) : AppColors.primary.withOpacity(0.6),
                        child: Text(
                          p.name == 'You' ? 'Me' : p.name.substring(0, 2).toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                            Text('Drop-off: ${p.dropOff} (${p.distanceKm.toStringAsFixed(1)} km)',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
