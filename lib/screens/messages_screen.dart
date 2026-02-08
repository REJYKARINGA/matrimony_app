import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/message_service.dart';
import '../services/auth_provider.dart';
import '../services/matching_service.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<dynamic> _conversations = [];
  List<User> _matches = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _loadConversations(isPolling: true);
    });
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadConversations(isPolling: true),
      _loadMatches(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadMatches() async {
    try {
      final response = await MatchingService.getMatches();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> matchesData = data['matches']['data'] ?? [];
        
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUserId = authProvider.user?.id;

        List<User> matchedUsers = [];
        for (var m in matchesData) {
           final u1 = User.fromJson(m['user1']);
           final u2 = User.fromJson(m['user2']);
           matchedUsers.add(u1.id == currentUserId ? u2 : u1);
        }

        if (mounted) {
          setState(() {
            _matches = matchedUsers;
          });
        }
      }
    } catch (e) {
      print('Error loading matches for horizontal list: $e');
    }
  }

  Future<void> _loadConversations({bool isPolling = false}) async {
    try {
      final response = await MessageService.getConversations();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _conversations = data['conversations']['data'] ?? [];
            if (!isPolling) _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (!isPolling) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chats',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.search_rounded, color: Colors.black54, size: 26),
                  ),
                ],
              ),
            ),

            if (_isLoading && _conversations.isEmpty)
              const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4))))
            else
              Expanded(
                child: RefreshIndicator(
                  color: Color(0xFF00BCD4),
                  onRefresh: _loadAllData,
                  child: CustomScrollView(
                    slivers: [
                      // Online Now Section
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Online Now',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (_matches.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00BCD4),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_matches.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 110,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: _matches.length,
                                itemBuilder: (context, index) {
                                  final user = _matches[index];
                                  final profile = user.userProfile;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Column(
                                      children: [
                                        Stack(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.grey.shade200, width: 2),
                                              ),
                                              child: CircleAvatar(
                                                radius: 32,
                                                backgroundColor: Colors.grey.shade100,
                                                backgroundImage: user.displayImage != null
                                                    ? NetworkImage(ApiService.getImageUrl(user.displayImage!))
                                                    : null,
                                                child: user.displayImage == null
                                                    ? Icon(Icons.person, color: Colors.grey.shade400, size: 30)
                                                    : null,
                                              ),
                                            ),
                                            Positioned(
                                              right: 4,
                                              top: 4,
                                              child: Container(
                                                width: 14,
                                                height: 14,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF42D368),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.white, width: 2.5),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          user.matrimonyId ?? 'User',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                            fontWeight: FontWeight.w500,
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

                      // Recent Conversations Header
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                          child: Text(
                            'Recent',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),

                      // List of Conversations
                      _conversations.isEmpty
                        ? const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(40.0),
                              child: Center(child: Text('No recent chats', style: TextStyle(color: Colors.grey))),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final chat = _conversations[index];
                                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                final currentUserId = authProvider.user?.id;
                                
                                final otherUser = chat['sender']['id'] != currentUserId
                                    ? chat['sender']
                                    : chat['receiver'];

                                 final otherUserName = otherUser['matrimony_id'] ?? 'User';
                                
                                final otherUserObj = User.fromJson(otherUser);
                                final profilePic = otherUserObj.displayImage != null
                                    ? ApiService.getImageUrl(otherUserObj.displayImage!)
                                    : null;

                                final bool isUnread = !chat['is_read'] && chat['receiver']['id'] == currentUserId;
                                final bool isMe = chat['sender']['id'] == currentUserId;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  child: ListTile(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatScreen(
                                            otherUserId: otherUser['id'],
                                            otherUserName: otherUserName,
                                            otherUserImage: profilePic,
                                          ),
                                        ),
                                      ).then((_) => _loadConversations());
                                    },
                                    leading: CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.grey.shade100,
                                      backgroundImage: profilePic != null ? NetworkImage(profilePic) : null,
                                      child: profilePic == null ? const Icon(Icons.person, color: Colors.grey) : null,
                                    ),
                                    title: Text(
                                      otherUserName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    subtitle: Text(
                                      chat['message'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isUnread ? Colors.black87 : Colors.grey.shade500,
                                        fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                    trailing: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _formatTime(DateTime.parse(chat['sent_at'])),
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                        ),
                                        const SizedBox(height: 5),
                                        if (isUnread)
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(color: Color(0xFF00BCD4), shape: BoxShape.circle),
                                            child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                          )
                                        else if (isMe)
                                           Icon(Icons.done_all_rounded, size: 18, color: chat['is_read'] ? const Color(0xFF00BCD4) : Colors.grey.shade300),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              childCount: _conversations.length,
                            ),
                          ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class ChatScreen extends StatefulWidget {
  final int otherUserId;
  final String otherUserName;
  final String? otherUserImage;
  final bool isMatched;
  final bool isInterestSent;

  const ChatScreen({
    Key? key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserImage,
    this.isMatched = true,
    this.isInterestSent = false,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  bool _isLoading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadMessages(isPolling: true);
    });
  }

  Future<void> _loadMessages({bool isPolling = false}) async {
    try {
      final response = await MessageService.getMessagesWithUser(widget.otherUserId);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _messages = data['messages'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final txt = _messageController.text.trim();
    _messageController.clear();
    try {
      await MessageService.sendMessage(widget.otherUserId, txt);
      _loadMessages();
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade100,
              backgroundImage: widget.otherUserImage != null ? NetworkImage(widget.otherUserImage!) : null,
              child: widget.otherUserImage == null ? const Icon(Icons.person, color: Colors.grey, size: 20) : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUserName, style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                const Text('Online', style: TextStyle(color: Color(0xFF42D368), fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert_rounded, color: Colors.black54), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  reverse: true,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[_messages.length - 1 - index];
                    final isMe = msg['sender_id'] != widget.otherUserId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF00BCD4) : Colors.grey.shade100,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isMe ? 20 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 20),
                          ),
                        ),
                        child: Text(
                          msg['message'],
                          style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
                        ),
                      ),
                    );
                  },
                ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(25)),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: Color(0xFF00BCD4), shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}