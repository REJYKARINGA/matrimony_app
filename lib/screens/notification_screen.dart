import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../services/navigation_provider.dart';
import '../widgets/common_footer.dart';
import 'view_profile_screen.dart';
import 'messages_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/rendering.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String? _error;

  // Updated colors to match the cyan header from the image
  static const Color primaryCyan = Color(0xFF00D9E1);
  static const Color accentGreen = Color(0xFF4CD9A6);

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await NotificationService.getNotifications();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          final List<dynamic> allNotifications = data['notifications']['data'] ?? [];
          final List<dynamic> filteredNotifications = [];
          final Set<int> seenMessageSenderIds = {};

          for (var notification in allNotifications) {
            if (notification['type'] == 'message' && notification['sender_id'] != null) {
              final int senderId = notification['sender_id'];
              if (!seenMessageSenderIds.contains(senderId)) {
                filteredNotifications.add(notification);
                seenMessageSenderIds.add(senderId);
              }
            } else {
              filteredNotifications.add(notification);
            }
          }

          setState(() {
            _notifications = filteredNotifications;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load notifications';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(int id, int index) async {
    try {
      await NotificationService.markAsRead(id);
      if (mounted) {
        setState(() {
          _notifications[index]['is_read'] = true;
        });
      }
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  String _getTimeAgo(String? createdAt) {
    if (createdAt == null) return '';
    final date = DateTime.parse(createdAt);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) return 'Yesterday';
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} m ago';
    } else {
      return 'Just now';
    }
  }

  bool _isToday(String? createdAt) {
    if (createdAt == null) return false;
    final date = DateTime.parse(createdAt);
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    // Group notifications
    final todayNotifications = _notifications.where((n) => _isToday(n['created_at'])).toList();
    final thisWeekNotifications = _notifications.where((n) => !_isToday(n['created_at'])).toList();
    final unreadCount = _notifications.where((n) => n['is_read'] == false || n['is_read'] == 0).length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          final navProvider = Provider.of<NavigationProvider>(context, listen: false);
          if (notification.direction == ScrollDirection.reverse) {
            navProvider.setFooterVisible(false);
          } else if (notification.direction == ScrollDirection.forward) {
            navProvider.setFooterVisible(true);
          }
          return true;
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryCyan))
            : _error != null
                ? Center(child: Text(_error!))
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade200),
                          const SizedBox(height: 16),
                          const Text('No notifications yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: primaryCyan,
                      onRefresh: _loadNotifications,
                      child: CustomScrollView(
                        slivers: [
                          SliverAppBar(
                            expandedHeight: 120.0,
                            floating: false,
                            pinned: true,
                            backgroundColor: Colors.white,
                            elevation: 0,
                            leading: IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
                              onPressed: () => Navigator.pop(context),
                            ),
                            actions: [
                              IconButton(
                                icon: const Icon(Icons.done_all_rounded, color: primaryCyan),
                                onPressed: () async {
                                  await NotificationService.markAllAsRead();
                                  _loadNotifications();
                                },
                                tooltip: 'Mark all as read',
                              ),
                              const SizedBox(width: 8),
                            ],
                            flexibleSpace: FlexibleSpaceBar(
                              centerTitle: false,
                              titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              title: Text(
                                'Notifications',
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.85),
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              background: Container(
                                color: Colors.white,
                                padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
                                alignment: Alignment.bottomLeft,
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                    children: [
                                      const TextSpan(text: 'You have '),
                                      TextSpan(
                                        text: '$unreadCount Notifications',
                                        style: const TextStyle(color: primaryCyan, fontWeight: FontWeight.bold),
                                      ),
                                      const TextSpan(text: ' today.'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Today Section
                          if (todayNotifications.isNotEmpty) ...[
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                child: Text(
                                  'Today',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ),
                            ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return _buildNotificationItem(todayNotifications[index], _notifications.indexOf(todayNotifications[index]));
                                },
                                childCount: todayNotifications.length,
                              ),
                            ),
                          ],

                          // This Week Section
                          if (thisWeekNotifications.isNotEmpty) ...[
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(20, 30, 20, 10),
                                child: Text(
                                  'This Week',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ),
                            ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return _buildNotificationItem(thisWeekNotifications[index], _notifications.indexOf(thisWeekNotifications[index]));
                                },
                                childCount: thisWeekNotifications.length,
                              ),
                            ),
                          ],
                          const SliverToBoxAdapter(child: SizedBox(height: 50)),
                        ],
                      ),
                    ),
                  ),
      bottomNavigationBar: Consumer<NavigationProvider>(
        builder: (context, navProvider, child) => AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          offset: navProvider.isFooterVisible ? Offset.zero : const Offset(0, 2),
          child: const CommonFooter(),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(dynamic notification, int realIndex) {
    final sender = notification['sender'];
    final senderProfile = sender != null ? sender['user_profile'] : null;
    final isRead = notification['is_read'] == true || notification['is_read'] == 1;
    final type = notification['type'];

    IconData badgeIcon;
    Color badgeColor;

    switch (type) {
      case 'interest':
        badgeIcon = Icons.favorite_rounded;
        badgeColor = const Color(0xFFFF2D55);
        break;
      case 'message':
        badgeIcon = Icons.chat_bubble_rounded;
        badgeColor = primaryCyan;
        break;
      case 'match':
        badgeIcon = Icons.check_circle_rounded;
        badgeColor = accentGreen;
        break;
      default:
        badgeIcon = Icons.person_rounded;
        badgeColor = Colors.grey;
    }

    return InkWell(
      onTap: () {
        if (!isRead) {
          _markAsRead(notification['id'], realIndex);
        }
        if (type == 'message') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                otherUserId: notification['sender_id'],
                otherUserName: senderProfile != null ? '${senderProfile['first_name']} ${senderProfile['last_name']}' : 'User',
                otherUserImage: senderProfile != null && senderProfile['profile_picture'] != null 
                    ? ApiService.getImageUrl(senderProfile['profile_picture']) 
                    : null,
                isMatched: true,
              ),
            ),
          );
        } else if (notification['sender_id'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewProfileScreen(userId: notification['sender_id']),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Unread Dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isRead ? Colors.transparent : const Color(0xFFFF2D55),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            
            // Avatar with Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade100, width: 2),
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.grey.shade50,
                    backgroundImage: senderProfile != null && senderProfile['profile_picture'] != null
                        ? NetworkImage(ApiService.getImageUrl(senderProfile['profile_picture']))
                        : null,
                    child: senderProfile == null || senderProfile['profile_picture'] == null
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                ),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                    ),
                    child: Icon(badgeIcon, size: 10, color: badgeColor),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            
            // Notification Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                      children: [
                        TextSpan(
                          text: senderProfile != null ? '${senderProfile['first_name']} ${senderProfile['last_name']} ' : 'Someone ',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: primaryCyan),
                        ),
                        TextSpan(text: notification['message'] ?? 'sent you a notification'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getTimeAgo(notification['created_at']),
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ),
            
            // Right Icon/Thumbnail
            const SizedBox(width: 8),
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  type == 'interest' ? Icons.favorite_outline_rounded : (type == 'message' ? Icons.chat_outlined : Icons.notifications_none_rounded),
                  size: 16,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}