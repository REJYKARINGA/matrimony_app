import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/matching_service.dart';
import '../services/api_service.dart';
import '../services/shortlist_service.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';
import 'profile_screen_view.dart';
import 'matching_screen.dart';
import 'messages_screen.dart';
import 'subscription_screen.dart';
import 'settings_screen.dart';
import 'view_profile_screen.dart';
import 'notification_screen.dart';
import '../services/reverb_service.dart';
import '../services/message_service.dart';
import '../services/navigation_provider.dart';
import '../services/profile_view_service.dart';
import '../widgets/common_footer.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isRefreshing = false;
  int _unreadMessageCount = 0;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _refreshUserData();
    _loadUnreadMessageCount();
    _startPolling();

    // Initialize Reverb real-time listening
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ReverbService.initialize(context);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _loadUnreadMessageCount();
    });
  }

  Future<void> _loadUnreadMessageCount() async {
    try {
      final response = await MessageService.getUnreadCount();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _unreadMessageCount = data['unread_count'] ?? 0;
          });
        }
      }
    } catch (e) {
      print('Error loading unread message count: $e');
    }
  }

  Future<void> _refreshUserData() async {
    if (!_isRefreshing) {
      setState(() {
        _isRefreshing = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.loadCurrentUserWithProfile();

      // Trigger Reverb test broadcast
      try {
        await ApiService.triggerTestBroadcast();
      } catch (e) {
        print('Error triggering test broadcast: $e');
      }

      setState(() {
        _isRefreshing = false;
      });
    }
  }

  final List<Widget> _widgetOptions = <Widget>[
    const DashboardScreen(),
    const MatchingScreen(),
    const MessagesScreen(),
    const SettingsScreen(),
    const SearchScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildNavItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int index, {
    bool showBadge = false,
  }) {
    bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _onItemTapped(index);
          if (index == 2) {
            _loadUnreadMessageCount();
          }
        },
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? activeIcon : icon,
                    color: isSelected
                        ? const Color(0xFF6A5AE0)
                        : Colors.grey.shade600,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF6A5AE0)
                          : Colors.grey.shade600,
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                    child: Text(label),
                  ),
                ],
              ),
              if (showBadge)
                Positioned(
                  top: 0,
                  right: 15,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4B4B),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterMatchButton() {
    bool isSelected = _selectedIndex == 1; // 1 is Matches
    return GestureDetector(
      onTap: () => _onItemTapped(1),
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF2D55).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              isSelected ? Icons.favorite : Icons.favorite_border,
              color: const Color(0xFFFF2D55),
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final navProvider = Provider.of<NavigationProvider>(context);

    // Check if user has completed their profile
    if (authProvider.user != null && authProvider.user!.userProfile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/create-profile');
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: _widgetOptions.elementAt(navProvider.selectedIndex),
      bottomNavigationBar: const CommonFooter(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<User> _recommendedUsers = [];
  bool _isLoadingRecommended = true;
  String? _recommendedError;
  late Set<int> _sentInterests;
  late Set<int> _matchedUserIds;
  bool _isLoadingInterests = false;
  late Map<int, Timer?> _interestTimers;
  late Map<int, int> _interestCountdown;
  late Set<int> _shortlistedUserIds;
  int _unreadNotificationCount = 0;
  List<dynamic> _visitors = [];
  bool _isLoadingVisitors = true;

  @override
  void initState() {
    super.initState();
    _sentInterests = {};
    _interestTimers = {};
    _interestCountdown = {};
    _shortlistedUserIds = {};
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await Future.wait([
          _loadUnreadCount(),
          _loadShortlistedProfiles(),
          _loadInterestsAndMatches(),
          _loadVisitors(),
          _checkNewMatches(),
        ]);
      } catch (e) {
        print('Error during initial data load: $e');
      } finally {
        _loadRecommendedUsers();
      }
    });
  }

  Future<void> _loadUnreadCount() async {
    try {
      final response = await NotificationService.getUnreadCount();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _unreadNotificationCount = data['unread_count'] ?? 0;
          });
        }
      }
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  Future<void> _loadVisitors() async {
    try {
      final response = await ProfileViewService.getVisitors();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _visitors = data['visitors'] ?? [];
            _isLoadingVisitors = false;
          });
        }
      }
    } catch (e) {
      print('Error loading visitors: $e');
      if (mounted) {
        setState(() {
          _isLoadingVisitors = false;
        });
      }
    }
  }

  Future<void> _loadShortlistedProfiles() async {
    try {
      final response = await ShortlistService.getShortlistedProfiles();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> shortlistedData;

        if (data is Map<String, dynamic> && data.containsKey('shortlisted')) {
          final shortlistedMap = data['shortlisted'] as Map<String, dynamic>;
          shortlistedData = shortlistedMap['data'] is List
              ? List.from(shortlistedMap['data'])
              : [];
        } else {
          shortlistedData = [];
        }

        Set<int> ids = {};
        for (var item in shortlistedData) {
          if (item is Map<String, dynamic> &&
              item.containsKey('shortlisted_user_id')) {
            ids.add(int.parse(item['shortlisted_user_id'].toString()));
          }
        }

        if (mounted) {
          setState(() {
            _shortlistedUserIds = ids;
          });
        }
      }
    } catch (e) {
      print('Error loading shortlisted profiles: $e');
    }
  }

  Future<void> _checkNewMatches() async {
    try {
      final response = await NotificationService.getNotifications();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> notifications = data['notifications']['data'] ?? [];
        
        final matchNotification = notifications.firstWhere(
          (n) => n['type'] == 'match' && (n['is_read'] == false || n['is_read'] == 0),
          orElse: () => null,
        );

        if (matchNotification != null) {
          final senderData = matchNotification['sender'];
          if (senderData != null) {
            final otherUser = User.fromJson(senderData);
            // Mark as read immediately so it doesn't pop up again
            await NotificationService.markAsRead(matchNotification['id']);
            if (mounted) {
              _showMatchPopup(otherUser);
              _loadUnreadCount(); // Update the bell icon count
            }
          }
        }
      }
    } catch (e) {
      print('Error checking for matches: $e');
    }
  }

  void _showMatchPopup(User otherUser) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => MatchCelebrationDialog(
        otherUser: otherUser,
      ),
    );
  }

  Future<void> _loadInterestsAndMatches() async {
    try {
      final sentResponse = await MatchingService.getSentInterests();
      final receivedResponse = await MatchingService.getReceivedInterests();

      Set<int> sentIds = {};
      Set<int> matchedIds = {};

      if (sentResponse.statusCode == 200) {
        final data = json.decode(sentResponse.body);
        List<dynamic> interestsData = [];
        if (data is Map<String, dynamic> && data.containsKey('interests')) {
          final interestsMap = data['interests'];
          if (interestsMap is Map<String, dynamic> &&
              interestsMap.containsKey('data')) {
            interestsData = List.from(interestsMap['data']);
          } else if (interestsMap is List) {
            interestsData = List.from(interestsMap);
          }
        }
        for (var interest in interestsData) {
          if (interest is Map<String, dynamic>) {
            int? receiverId = interest['receiver_id'] is int
                ? interest['receiver_id']
                : int.tryParse(interest['receiver_id'].toString());
            if (receiverId != null) {
              sentIds.add(receiverId);
              if (interest['status'] == 'accepted') matchedIds.add(receiverId);
            }
          }
        }
      }

      if (receivedResponse.statusCode == 200) {
        final data = json.decode(receivedResponse.body);
        List<dynamic> interestsData = [];
        if (data is Map<String, dynamic> && data.containsKey('interests')) {
          final interestsMap = data['interests'];
          if (interestsMap is Map<String, dynamic> &&
              interestsMap.containsKey('data')) {
            interestsData = List.from(interestsMap['data']);
          } else if (interestsMap is List) {
            interestsData = List.from(interestsMap);
          }
        }
        for (var interest in interestsData) {
          if (interest is Map<String, dynamic>) {
            int? senderId = interest['sender_id'] is int
                ? interest['sender_id']
                : int.tryParse(interest['sender_id'].toString());
            if (senderId != null && interest['status'] == 'accepted')
              matchedIds.add(senderId);
          }
        }
      }

      if (mounted) {
        setState(() {
          _sentInterests = sentIds;
          _matchedUserIds = matchedIds;
        });
      }
    } catch (e) {
      print('Error loading interests and matches: $e');
    }
  }

  Future<void> _handleQuickInterest(int userId) async {
    try {
      final response = await MatchingService.sendInterest(userId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _sentInterests.add(userId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Interest sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send interest'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _loadRecommendedUsers() async {
    try {
      setState(() {
        _isLoadingRecommended = true;
        _recommendedError = null;
      });

      final response = await MatchingService.getSuggestions();

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        List<dynamic> usersData = [];

        if (decodedData is List) {
          usersData = List.from(decodedData);
        } else if (decodedData is Map<String, dynamic>) {
          if (decodedData.containsKey('suggestions') &&
              decodedData['suggestions'] is Map<String, dynamic>) {
            usersData = List.from(decodedData['suggestions']['data'] ?? []);
          } else if (decodedData.containsKey('users')) {
            usersData = List.from(decodedData['users'] ?? []);
          } else if (decodedData.containsKey('data')) {
            usersData = List.from(decodedData['data'] ?? []);
          }
        }

        List<User> allUsers = [];
        for (var userData in usersData) {
          if (userData is Map<String, dynamic>) {
            try {
              allUsers.add(User.fromJson(userData));
            } catch (e) {
              print('Error parsing user: $e');
            }
          }
        }

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUserProfile = authProvider.user?.userProfile;

        List<User> filteredUsers;
        if (authProvider.user?.role == 'admin') {
          filteredUsers = allUsers;
        } else if (currentUserProfile?.gender != null) {
          String gender = currentUserProfile!.gender!.toLowerCase();
          filteredUsers = allUsers
              .where(
                (u) =>
                    u.userProfile?.gender != null &&
                    u.userProfile!.gender!.toLowerCase() != gender,
              )
              .toList();
          if (filteredUsers.isEmpty) filteredUsers = allUsers;
        } else {
          filteredUsers = allUsers;
        }

        setState(() {
          _recommendedUsers = filteredUsers;
          _isLoadingRecommended = false;
        });
      } else {
        setState(() {
          _recommendedError =
              'Failed to load recommendations. Status: ${response.statusCode}';
          _isLoadingRecommended = false;
        });
      }
    } catch (e) {
      setState(() {
        _recommendedError = 'Error loading recommendations: $e';
        _isLoadingRecommended = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final profile = user?.userProfile;

    if (authProvider.user != null && authProvider.user!.userProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFF),
      body: Stack(
        children: [
          // Background Blobs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6A5AE0).withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF2D55).withOpacity(0.03),
              ),
            ),
          ),
          CustomScrollView(
        slivers: [
          // Personal Greeting Header
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade200, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundImage: user?.displayImage != null
                            ? NetworkImage(
                                ApiService.getImageUrl(user!.displayImage!),
                              )
                            : null,
                        child: user?.displayImage == null
                            ? const Icon(Icons.person, color: Color(0xFF5CB3FF))
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hey, ${profile?.firstName ?? 'User'}!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const Text(
                          "Let's Find A Match",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.notifications_none_rounded,
                            color: Color(0xFF1A1A1A),
                            size: 28,
                          ),
                          if (_unreadNotificationCount > 0)
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF4B4B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => const NotificationScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Visitors section
          if (_visitors.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: Text(
                      'Recent Visitors',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _visitors.length,
                      itemBuilder: (context, index) {
                        final visitor = _visitors[index];
                        final pic = visitor['user_profile']?['profile_picture'];
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) =>
                                  ViewProfileScreen(userId: visitor['id']),
                            ),
                          ).then((_) => _loadVisitors()),
                          child: Container(
                            width: 80,
                            height: 80,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            child: CustomPaint(
                              painter: DashedCirclePainter(
                                color: const Color(0xFFFF2D55),
                                dashWidth: 14,
                                dashSpace: 8,
                                strokeWidth: 3,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(6.0),
                                child: CircleAvatar(
                                  radius: 34,
                                backgroundColor: Colors.grey.shade100,
                                backgroundImage: pic != null
                                    ? NetworkImage(ApiService.getImageUrl(pic))
                                    : null,
                                child: pic == null
                                    ? Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.grey.shade200,
                                              Colors.grey.shade300,
                                            ],
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.person,
                                            color: Colors.grey,
                                            size: 30,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  ),
                  const Divider(
                    height: 24,
                    indent: 16,
                    endIndent: 16,
                    thickness: 0.5,
                  ),
                ],
              ),
            ),

          // Cards List - Full Width Responsive
          _isLoadingRecommended
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        color: Color(0xFF5CB3FF),
                      ),
                    ),
                  ),
                )
              : _recommendedError != null
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_recommendedError!),
                  ),
                )
              : _recommendedUsers.isEmpty
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No recommendations available'),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return _buildDynamicProfileCard(
                      context,
                      _recommendedUsers[index],
                    );
                  }, childCount: _recommendedUsers.length),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    ],
  ),
);
  }

  Widget _buildDynamicProfileCard(BuildContext context, User user) {
    final profile = user.userProfile;
    String ageText = '';
    if (profile?.dateOfBirth != null) {
      final birth = profile!.dateOfBirth!;
      int age = DateTime.now().year - birth.year;
      if (DateTime.now().month < birth.month ||
          (DateTime.now().month == birth.month &&
              DateTime.now().day < birth.day))
        age--;
      ageText = '$age';
    }

    String loc = [
      profile?.city,
      profile?.district,
    ].where((e) => e != null).join(', ');

    String maritalStatus = profile?.maritalStatus?.toLowerCase() == 'never_married' 
        ? 'Single' 
        : (profile?.maritalStatus ?? '').replaceAll('_', ' ').split(' ').map((word) {
            if (word.isEmpty) return word;
            return word[0].toUpperCase() + word.substring(1).toLowerCase();
          }).join(' ');

    return SwipeCard(
      onSwipeRight: () {
        _handleQuickInterest(user.id!);
        setState(() {
          _recommendedUsers.removeWhere((u) => u.id == user.id);
        });
      },
      onSwipeLeft: () {
        setState(() {
          _recommendedUsers.removeWhere((u) => u.id == user.id);
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        height: 480,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
          children: [
            Positioned.fill(
              child: user.displayImage != null
                  ? Image.network(
                      ApiService.getImageUrl(user.displayImage!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderBackground(profile?.gender),
                    )
                  : _buildPlaceholderBackground(profile?.gender),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.45),
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0.0, 0.45, 0.7, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${user.matrimonyId ?? 'User'}, $ageText',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF5CB3FF),
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const SizedBox(height: 4),
                  if (profile?.caste != null || maritalStatus.isNotEmpty)
                    Text(
                      '${profile?.caste ?? ''}${profile?.caste != null && maritalStatus.isNotEmpty ? ', ' : ''}$maritalStatus'
                          .toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: Colors.white.withOpacity(0.8),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        loc.isNotEmpty ? loc : 'Unknown Location',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),
            // Floating Action Buttons Row
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Pass (Close)
                  GestureDetector(
                    onTap: () {},
                    child: _buildFloatingButton(
                      icon: Icons.close_rounded,
                      color: Colors.white,
                      iconColor: Colors.grey.shade600,
                      size: 50,
                    ),
                  ),

                  // Chat
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => ChatScreen(
                            otherUserId: user.id!,
                            otherUserName: '${user.matrimonyId ?? 'User'}',
                            otherUserImage: user.displayImage != null
                                ? ApiService.getImageUrl(user.displayImage!)
                                : null,
                            isMatched: _matchedUserIds.contains(user.id),
                            isInterestSent: _sentInterests.contains(user.id),
                          ),
                        ),
                      );
                    },
                    child: _buildFloatingButton(
                      icon: Icons.chat_bubble_rounded,
                      color: const Color(0xFF5CB3FF),
                      iconColor: Colors.white,
                      size: 50,
                      shadowColor: const Color(0xFF5CB3FF).withOpacity(0.3),
                    ),
                  ),

                  // Star (Save)
                  GestureDetector(
                    onTap: () async {
                      if (_shortlistedUserIds.contains(user.id!)) {
                        if ((await ShortlistService.removeFromShortlist(user.id!)).statusCode == 200) {
                          setState(() => _shortlistedUserIds.remove(user.id!));
                        }
                      } else {
                        if ((await ShortlistService.addToShortlist(user.id!)).statusCode == 200) {
                          setState(() => _shortlistedUserIds.add(user.id!));
                        }
                      }
                    },
                    child: _buildFloatingButton(
                      icon: _shortlistedUserIds.contains(user.id!) ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: _shortlistedUserIds.contains(user.id!) ? const Color(0xFFFFD700) : Colors.white,
                      iconColor: _shortlistedUserIds.contains(user.id!) ? Colors.white : const Color(0xFFFFD700),
                      size: 50,
                      shadowColor: _shortlistedUserIds.contains(user.id!) ? const Color(0xFFFFD700).withOpacity(0.4) : null,
                    ),
                  ),

                  // Like (Heart/Check)
                  GestureDetector(
                    onTap: () => _handleQuickInterest(user.id!),
                    child: _buildFloatingButton(
                      icon: _sentInterests.contains(user.id) ? Icons.done_all_rounded : Icons.favorite,
                      color: _sentInterests.contains(user.id) ? const Color(0xFF42D368) : const Color(0xFFFF2D55),
                      iconColor: Colors.white,
                      size: 60,
                      shadowColor: (_sentInterests.contains(user.id) ? const Color(0xFF42D368) : const Color(0xFFFF2D55)).withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            // Clickable area for card - positioned to avoid button areas
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 140, // Leave space for buttons at bottom
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => ViewProfileScreen(userId: user.id!),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildPlaceholderBackground(String? gender) {
    bool isFemale = gender?.toLowerCase() == 'female';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isFemale
              ? [const Color(0xFFFFEBF0), const Color(0xFFFFD1DC)]
              : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
        ),
      ),
      child: Center(
        child: Icon(
          isFemale ? Icons.face_3_rounded : Icons.face_6_rounded,
          size: 80,
          color: isFemale
              ? const Color(0xFFFF2D55).withOpacity(0.3)
              : const Color(0xFF5CB3FF).withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required double size,
    Color? shadowColor,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: shadowColor ?? Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, color: iconColor, size: size * 0.5),
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;

  DashedCirclePainter({
    required this.color,
    this.dashWidth = 5,
    this.dashSpace = 3,
    this.strokeWidth = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double radius = (size.width - strokeWidth) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    final double circumference = 2 * 3.141592653589793238 * radius;
    final int dashCount = (circumference / (dashWidth + dashSpace)).floor();
    
    // Adjust dashSpace slightly to fill the circle perfectly
    final double actualDashSpace = (circumference / dashCount) - dashWidth;

    for (int i = 0; i < dashCount; i++) {
      final double startAngle = (i * (dashWidth + actualDashSpace)) / radius;
      final double sweepAngle = dashWidth / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SwipeCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onSwipeRight;
  final VoidCallback onSwipeLeft;

  const SwipeCard({
    Key? key,
    required this.child,
    required this.onSwipeRight,
    required this.onSwipeLeft,
  }) : super(key: key);

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> {
  Offset _offset = Offset.zero;
  double _angle = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _offset += details.delta;
              _angle = 0.1 * (_offset.dx / 150);
            });
          },
          onPanEnd: (details) {
            if (_offset.dx > 100) {
              widget.onSwipeRight();
            } else if (_offset.dx < -100) {
              widget.onSwipeLeft();
            }
            setState(() {
              _offset = Offset.zero;
              _angle = 0;
            });
          },
          child: Stack(
            children: [
              Transform.translate(
                offset: _offset,
                child: Transform.rotate(
                  angle: _angle,
                  child: widget.child,
                ),
              ),
              if (_offset.dx.abs() > 20)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Opacity(
                        opacity: (_offset.dx.abs() / 150).clamp(0.0, 1.0),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: (_offset.dx > 0 
                                ? const Color(0xFF42D368) 
                                : const Color(0xFFFF4B4B)).withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: Icon(
                            _offset.dx > 0 ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
class MatchCelebrationDialog extends StatelessWidget {
  final User otherUser;

  const MatchCelebrationDialog({
    Key? key,
    required this.otherUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          Container(
            width: double.infinity,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF2D55).withOpacity(0.2),
                  blurRadius: 100,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
          
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "It's a Match!",
                style: TextStyle(
                  fontSize: 48,
                  fontFamily: 'Pacifico', // Fallback to normal if not available
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(blurRadius: 10, color: Colors.black45, offset: Offset(0, 4)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "You and ${otherUser.matrimonyId} are both interested in each other",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              
              // Avatars Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPulseAvatar(currentUser?.displayImage, -1),
                  const SizedBox(width: -20), // Overlap
                  _buildPulseAvatar(otherUser.displayImage, 1),
                ],
              ),
              
              const SizedBox(height: 50),
              
              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF2D55), Color(0xFFFF5277)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF2D55).withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                otherUserId: otherUser.id!,
                                otherUserName: '${otherUser.matrimonyId ?? 'User'}',
                                otherUserImage: otherUser.displayImage != null 
                                  ? ApiService.getImageUrl(otherUser.displayImage!)
                                  : null,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "SEND A MESSAGE",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "KEEP BROWSING",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Confetti-like bits (Static representation)
          Positioned(top: 100, left: 40, child: _buildConfetti(Colors.blueAccent, 10)),
          Positioned(top: 150, right: 60, child: _buildConfetti(Colors.pinkAccent, 12)),
          Positioned(bottom: 120, left: 80, child: _buildConfetti(Colors.yellowAccent, 8)),
          Positioned(bottom: 180, right: 30, child: _buildConfetti(Colors.greenAccent, 10)),
        ],
      ),
    );
  }

  Widget _buildPulseAvatar(String? imageUrl, double rotation) {
    return Transform.rotate(
      angle: rotation * 0.1,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: imageUrl != null ? NetworkImage(ApiService.getImageUrl(imageUrl)) : null,
          child: imageUrl == null ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
        ),
      ),
    );
  }

  Widget _buildConfetti(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
