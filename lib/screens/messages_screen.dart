import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/message_service.dart';
import '../services/auth_provider.dart';
import '../services/matching_service.dart';
import '../services/api_service.dart';
import '../services/profile_service.dart';
import '../models/user_model.dart';
import '../services/search_service.dart';
import 'view_profile_screen.dart';
import '../utils/app_colors.dart';

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
    _pollingTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
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
      final response = await SearchService.searchProfiles(field: 'online');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> profilesData = data['profiles'] != null 
            ? (data['profiles']['data'] ?? []) 
            : (data['data'] ?? []);
        
        List<User> onlineUsers = [];
        for (var p in profilesData) {
           onlineUsers.add(User.fromJson(p));
        }

        if (mounted) {
          setState(() {
            _matches = onlineUsers;
          });
        }
      }
    } catch (e) {
      print('Error loading online users: $e');
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
      backgroundColor: AppColors.offWhite,
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
                      color: AppColors.darkGreen,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            if (_isLoading && _conversations.isEmpty)
              const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)))
            else
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primaryGreen,
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
                                      color: AppColors.bodyText,
                                    ),
                                  ),
                                  if (_matches.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.deepEmerald,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_matches.length}',
                                      style: const TextStyle(color: Colors.white,
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
                                  return GestureDetector(
                                    onTap: () {
                                      if (user.id != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ViewProfileScreen(userId: user.id!),
                                          ),
                                        );
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Column(
                                        children: [
                                        Stack(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3), width: 2),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(32),
                                                child: CircleAvatar(
                                                  radius: 32,
                                                  backgroundColor: AppColors.softMint,
                                                  child: Stack(
                                                    children: [
                                                      if (user.displayImage != null)
                                                        Positioned.fill(
                                                          child: Image.network(
                                                            ApiService.getImageUrl(user.displayImage!),
                                                            fit: BoxFit.cover,
                                                            errorBuilder: (context, error, stackTrace) =>
                                                                const Icon(Icons.person, color: Colors.grey),
                                                          ),
                                                        ),
                                                      if (user.displayImage == null)
                                                        const Center(child: Icon(Icons.person, color: Colors.grey, size: 30)),
                                                      
                                                      // Visibility Overlays
                                                      if (user.displayImage != null) ...[
                                                        // 1. Under Review (Blur)
                                                        if (user.isDisplayImageVerified != true)
                                                          Positioned.fill(
                                                            child: ClipRRect(
                                                              child: BackdropFilter(
                                                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                                                child: Container(
                                                                  color: Colors.white70.withOpacity(0.2),
                                                                  child: const Icon(Icons.pending_rounded, color: Colors.white70, size: 20),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        // 2. Locked (Private)
                                                        if (user.hasHiddenPhotos && !user.isContactUnlocked)
                                                          Positioned.fill(
                                                            child: Container(
                                                              color: Colors.white70.withOpacity(0.4),
                                                              child: const Icon(Icons.lock_rounded, color: AppColors.cardDark, size: 20),
                                                            ),
                                                          ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              right: 4,
                                              top: 4,
                                              child: Container(
                                                width: 14,
                                                height: 14,
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryGreen,
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
                              color: AppColors.bodyText,
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
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                      leading: Stack(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isUnread ? AppColors.primaryGreen : Colors.transparent,
                                                width: 2,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(30),
                                              child: CircleAvatar(
                                                radius: 28,
                                                backgroundColor: AppColors.softMint,
                                                child: Stack(
                                                  children: [
                                                    if (profilePic != null)
                                                      Positioned.fill(
                                                        child: Image.network(
                                                          profilePic,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) =>
                                                              const Icon(Icons.person, color: Colors.grey),
                                                        ),
                                                      ),
                                                    if (profilePic == null)
                                                      const Center(child: Icon(Icons.person, color: Colors.grey)),

                                                    // Visibility Overlays
                                                    if (profilePic != null) ...[
                                                      // 1. Under Review (Blur)
                                                      if (otherUserObj.isDisplayImageVerified != true)
                                                        Positioned.fill(
                                                          child: ClipRRect(
                                                            child: BackdropFilter(
                                                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                                              child: Container(
                                                                color: Colors.white70.withOpacity(0.2),
                                                                child: const Icon(Icons.pending_rounded, color: Colors.white70, size: 18),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      // 2. Locked (Private)
                                                      if (otherUserObj.hasHiddenPhotos && !otherUserObj.isContactUnlocked)
                                                        Positioned.fill(
                                                          child: Container(
                                                            color: Colors.white70.withOpacity(0.4),
                                                            child: const Icon(Icons.lock_rounded, color: AppColors.bodyText, size: 18),
                                                          ),
                                                        ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (isUnread)
                                            Positioned(
                                              right: 2,
                                              top: 2,
                                              child: Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryGreen,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.white, width: 2),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      title: Text(
                                        otherUserName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.bodyText),
                                      ),
                                      subtitle: Text(
                                        chat['message'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isUnread ? AppColors.bodyText : AppColors.mutedText,
                                          fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                      trailing: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _formatTime(DateTime.parse(chat['sent_at'])),
                                            style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                                          ),
                                          const SizedBox(height: 5),
                                          if (isUnread)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryGreen,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Text('New', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                            )
                                          else if (isMe)
                                             Icon(Icons.done_all_rounded, size: 18, color: chat['is_read'] ? AppColors.primaryGreen : AppColors.mutedText),
                                        ],
                                      ),
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
  User? _otherUser;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadOtherUserProfile();
    _loadMessages();
    _startPolling();
  }

  Future<void> _loadOtherUserProfile() async {
    try {
      final response = await ProfileService.getUserProfile(widget.otherUserId);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _otherUser = User.fromJson(data['user']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading other user profile: $e');
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
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
      final response = await MessageService.sendMessage(widget.otherUserId, txt);
      if (response.statusCode == 200 || response.statusCode == 201) {
        _loadMessages();
      } else if (response.statusCode == 403) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.lock, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Contact Locked'),
                ],
              ),
              content: const Text(
                'You must unlock this contact before you can send messages. Do you want to go to their profile to purchase contact access?',
                style: TextStyle(fontSize: 15),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewProfileScreen(userId: widget.otherUserId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('View Profile'),
                ),
              ],
            ),
          );
        }
      } else {
        final data = json.decode(response.body);
        final errorMessage = data['error'] ?? 'Failed to send message';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkGreen, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.softMint,
                  child: Stack(
                    children: [
                      if (widget.otherUserImage != null)
                        Positioned.fill(
                          child: Image.network(
                            widget.otherUserImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.person, color: Colors.grey, size: 20),
                          ),
                        ),
                      if (widget.otherUserImage == null)
                        const Center(child: Icon(Icons.person, color: Colors.grey, size: 20)),

                      // Visibility Overlays (using _otherUser data if available)
                      if (widget.otherUserImage != null && _otherUser != null) ...[
                        // 1. Under Review (Blur)
                        if (_otherUser!.isDisplayImageVerified != true)
                          Positioned.fill(
                            child: ClipRRect(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                                child: Container(
                                  color: Colors.white70.withOpacity(0.1),
                                  child: const Icon(Icons.pending_rounded, color: Colors.white70, size: 14),
                                ),
                              ),
                            ),
                          ),
                        // 2. Locked (Private)
                        if (_otherUser!.hasHiddenPhotos && !_otherUser!.isContactUnlocked)
                          Positioned.fill(
                            child: Container(
                              color: Colors.white70.withOpacity(0.3),
                              child: const Icon(Icons.lock_rounded, color: AppColors.bodyText, size: 14),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUserName, style: const TextStyle(color: AppColors.bodyText, fontSize: 16, fontWeight: FontWeight.bold)),
                const Text('Online', style: TextStyle(color: AppColors.primaryGreen, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert_rounded, color: AppColors.darkGreen), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
              : _messages.isEmpty 
                  ? _buildProfileCard()
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
                          color: isMe ? AppColors.primaryGreen : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isMe ? 20 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 20),
                          ),
                          boxShadow: isMe ? [] : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          msg['message'],
                          style: TextStyle(color: isMe ? Colors.white : AppColors.bodyText, fontSize: 15),
                        ),
                      ),
                    );
                  },
                ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(25)),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: AppColors.bodyText),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: AppColors.mutedText),
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
                    decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
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

  Widget _buildProfileCard() {
    if (_otherUser == null) return const SizedBox.shrink();
    final profile = _otherUser!.userProfile;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: AppColors.primaryGreen.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.softMint,
                          child: Stack(
                            children: [
                              if (widget.otherUserImage != null)
                                Positioned.fill(
                                  child: Image.network(
                                    widget.otherUserImage!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.person, color: Colors.grey, size: 40),
                                  ),
                                ),
                              if (widget.otherUserImage == null)
                                const Center(child: Icon(Icons.person, color: Colors.grey, size: 40)),

                              // Visibility Overlays
                              if (widget.otherUserImage != null && _otherUser != null) ...[
                                // 1. Under Review (Blur)
                                if (_otherUser!.isDisplayImageVerified != true)
                                  Positioned.fill(
                                    child: ClipRRect(
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                        child: Container(
                                          color: Colors.white70.withOpacity(0.2),
                                          child: const Icon(Icons.pending_rounded, color: Colors.white70, size: 30),
                                        ),
                                      ),
                                    ),
                                  ),
                                // 2. Locked (Private)
                                if (_otherUser!.hasHiddenPhotos && !_otherUser!.isContactUnlocked)
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.white70.withOpacity(0.4),
                                      child: const Icon(Icons.lock_rounded, color: AppColors.bodyText, size: 30),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.bodyText),
                  ),
                  const SizedBox(height: 8),
                  if (profile != null)
                    Text(
                      '${profile.age} yrs • ${profile.height} cm • ${profile.maritalStatus?.replaceAll('_', ' ').toUpperCase() ?? ''}',
                      style: const TextStyle(color: AppColors.mutedText, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 16),
                  _buildProfileCardRow(Icons.location_on_outlined, '${profile?.city ?? ''}, ${profile?.state ?? ''}'),
                  const SizedBox(height: 12),
                  _buildProfileCardRow(Icons.work_outline_rounded, profile?.occupation ?? 'Not specified'),
                  const SizedBox(height: 12),
                  _buildProfileCardRow(Icons.school_outlined, profile?.education ?? 'Not specified'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewProfileScreen(userId: widget.otherUserId),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.softMint,
                      foregroundColor: AppColors.darkGreen,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('View Full Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'No messages yet. Say hello! 👋',
              style: const TextStyle(color: AppColors.mutedText, fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCardRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: AppColors.primaryGreen),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: AppColors.bodyText, fontSize: 14)),
      ],
    );
  }
}














