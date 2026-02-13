import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/matching_service.dart';
import '../services/api_service.dart';
import 'view_profile_screen.dart';
import 'messages_screen.dart' as msg;
import '../services/shortlist_service.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({Key? key}) : super(key: key);

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _matches = [];
  List<dynamic> _sentInterests = [];
  List<dynamic> _receivedInterests = [];
  List<dynamic> _declinedInterests = [];
  Set<int> _shortlistedUserIds = {};
  bool _isLoading = true;
  String? _errorMessage;

  // Updated gradient colors to match the cyan header in the image
  static const Color gradientCyan = Color(0xFF00D9E1); // Bright cyan from image
  static const Color gradientLightBlue = Color(0xFF64C3E8); // Light blue gradient
  static const Color accentGreen = Color(0xFF4CD9A6);

  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final userResponse = await ApiService.getUser();
      if (userResponse.statusCode == 200) {
        final userData = json.decode(userResponse.body);
        _currentUserId = userData['user']['id'];
      }
    } catch (e) {
      print('Error fetching user: $e');
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load all relevant data concurrently
      final results = await Future.wait([
        MatchingService.getMatches(),
        MatchingService.getSentInterests(),
        MatchingService.getReceivedInterests(),
        ShortlistService.getShortlistedProfiles(),
      ]);

      // Process matches
      if (results[0].statusCode == 200) {
        final data = json.decode(results[0].body);
        _matches = data['matches']['data'] ?? [];
      }

      // Process sent interests
      if (results[1].statusCode == 200) {
        final data = json.decode(results[1].body);
        final List<dynamic> sent = data['interests']['data'] ?? [];
        _sentInterests = sent.where((i) => i['status'] != 'rejected').toList();
        
        // Collect declined sent interests
        _declinedInterests = sent.where((i) => i['status'] == 'rejected').toList();
      }

      // Process received interests
      if (results[2].statusCode == 200) {
        final data = json.decode(results[2].body);
        final List<dynamic> received = data['interests']['data'] ?? [];
        _receivedInterests = received.where((i) => i['status'] != 'rejected').toList();
        
        // Collect declined received interests & combine
        final declinedReceived = received.where((i) => i['status'] == 'rejected').toList();
        _declinedInterests.addAll(declinedReceived);
      }

      // Process shortlist
      if (results[3].statusCode == 200) {
        final data = json.decode(results[3].body);
        final List<dynamic> items = data['shortlist']['data'] ?? [];
        _shortlistedUserIds = items.map((i) => i['shortlisted_user_id'] as int).toSet();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Global Background with Design
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF00BCD4).withOpacity(0.08),
                    const Color(0xFF00BCD4).withOpacity(0.02),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00BCD4).withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 150,
                    left: -50,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00BCD4).withOpacity(0.05),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                  expandedHeight: 110.0,
                  pinned: true,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  backgroundColor: Colors.transparent,
                  title: const Text(
                    'Matches & Interests',
                    style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  centerTitle: true,
                  iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: Container(),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(70),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: const Color(0xFF00BCD4),
                          unselectedLabelColor: Colors.grey.shade600,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          dividerColor: Colors.transparent,
                          indicatorPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          tabs: const [
                            Tab(text: 'Matches'),
                            Tab(text: 'Sent'),
                            Tab(text: 'Received'),
                            Tab(text: 'Declined'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildMatchesTab(),
                _buildSentInterestsTab(),
                _buildReceivedInterestsTab(),
                _buildDeclinedInterestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeclinedInterestsTab() {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(gradientCyan),
        ),
      );
    }

    if (_declinedInterests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block_outlined,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No declined interests',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: gradientCyan,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _declinedInterests.length,
        itemBuilder: (context, index) {
          final interest = _declinedInterests[index];
          if (interest == null) return const SizedBox.shrink();
          
          // Check who the target profile is
          final bool isSentByMe = interest['sender_id'] == _currentUserId;
          
          final userJson = isSentByMe ? interest['receiver'] : interest['sender'];
          if (userJson == null) return const SizedBox.shrink();
          
          final user = User.fromJson(userJson);

          return _buildProfileCard(
            user,
            isInterest: true,
            status: interest['status'],
          );
        },
      ),
    );
  }

  Widget _buildMatchesTab() {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(gradientCyan),
        ),
      );
    }

    if (_matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: gradientCyan.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No matches yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send interests to increase your matches',
              style: TextStyle(
                fontSize: 14,
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: gradientCyan,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _matches.length,
        itemBuilder: (context, index) {
          final match = _matches[index];
          if (match == null || match['user1'] == null || match['user2'] == null) {
            return const SizedBox.shrink();
          }
          
          final currentUser = _currentUserId; 
          final otherUserJson = match['user1']['id'].toString() != currentUser.toString()
              ? match['user1']
              : match['user2'];
              
          if (otherUserJson == null) return const SizedBox.shrink();
          final user = User.fromJson(otherUserJson);

          return _buildProfileCard(user, isMatch: true);
        },
      ),
    );
  }

  Widget _buildSentInterestsTab() {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(gradientCyan),
        ),
      );
    }

    if (_sentInterests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.send_outlined,
              size: 64,
              color: gradientCyan.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No interests sent',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: gradientCyan,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _sentInterests.length,
        itemBuilder: (context, index) {
          final interest = _sentInterests[index];
          if (interest == null || interest['receiver'] == null) {
            return const SizedBox.shrink();
          }
          final user = User.fromJson(interest['receiver']);

          return _buildProfileCard(
            user,
            isInterest: true,
            status: interest['status'],
          );
        },
      ),
    );
  }

  Widget _buildReceivedInterestsTab() {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(gradientCyan),
        ),
      );
    }

    if (_receivedInterests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_outlined,
              size: 64,
              color: accentGreen.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No interests received',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: gradientCyan,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _receivedInterests.length,
        itemBuilder: (context, index) {
          final interest = _receivedInterests[index];
          if (interest == null || interest['sender'] == null) {
            return const SizedBox.shrink();
          }
          final user = User.fromJson(interest['sender']);

          return _buildProfileCard(
            user,
            isInterest: true,
            status: interest['status'],
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(
    User user, {
    bool isMatch = false,
    bool isInterest = false,
    String? status,
  }) {
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 480,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BCD4).withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Background Image
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
            // Gradient Overlay
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
            // Status Badge
            if (isInterest && status != null)
              Positioned(
                top: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: (status == 'accepted' 
                            ? accentGreen 
                            : status == 'rejected' 
                                ? Colors.redAccent 
                                : gradientCyan).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            // Profile Details
            Positioned(
              left: 24,
              right: 24,
              bottom: 110,
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
                        color: Color(0xFF00BCD4),
                        size: 20,
                      ),
                    ],
                  ),
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
                      Expanded(
                        child: Text(
                          loc.isNotEmpty ? loc : 'Unknown Location',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.distance != null)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BCD4).withOpacity(0.35),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.near_me_rounded,
                                color: Colors.white,
                                size: 10,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${user.distance!.toStringAsFixed(1)} KM',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Action Buttons
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   // Close / Dismiss
                  GestureDetector(
                    onTap: () {
                      if (isInterest && status == 'pending') {
                         _handleInterestAction(user.id!, false);
                      } else {
                         // For matches or other states, just show a snackbar for now
                         // or implement "Hide this profile" logic if available
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Profile dismissed')),
                         );
                      }
                    },
                    child: _buildFloatingButton(
                      icon: Icons.close_rounded,
                      color: Colors.white,
                      iconColor: Colors.black54,
                      size: 50,
                      shadowColor: Colors.black.withOpacity(0.1),
                    ),
                  ),

                  // Chat
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => msg.ChatScreen(
                            otherUserId: user.id!,
                            otherUserName: '${user.matrimonyId ?? 'User'}',
                            otherUserImage: user.displayImage != null
                                ? ApiService.getImageUrl(user.displayImage!)
                                : null,
                            isMatched: isMatch || status == 'accepted',
                          ),
                        ),
                      );
                    },
                    child: _buildFloatingButton(
                      icon: Icons.chat_bubble_rounded,
                      color: const Color(0xFF00BCD4),
                      iconColor: Colors.white,
                      size: 50,
                      shadowColor: const Color(0xFF00BCD4).withOpacity(0.3),
                    ),
                  ),

                  // Shortlist (Star)
                  GestureDetector(
                    onTap: () async {
                      try {
                        if (_shortlistedUserIds.contains(user.id!)) {
                          final response = await ShortlistService.removeFromShortlist(user.id!);
                          if (response.statusCode == 200) {
                            setState(() {
                              _shortlistedUserIds.remove(user.id!);
                            });
                          }
                        } else {
                          final response = await ShortlistService.addToShortlist(user.id!);
                          if (response.statusCode == 200 || response.statusCode == 201) {
                            setState(() {
                              _shortlistedUserIds.add(user.id!);
                            });
                          }
                        }
                      } catch (e) {
                         print('Error toggling shortlist: $e');
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

                  // Accept / Match (Heart)
                  GestureDetector(
                    onTap: () {
                      if (isInterest && status == 'pending') {
                         _handleInterestAction(user.id!, true);
                      } else if (!isMatch && status != 'accepted') {
                         _sendInterest(user.id!);
                      }
                    },
                    child: _buildFloatingButton(
                      icon: (isMatch || status == 'accepted') ? Icons.done_all_rounded : Icons.favorite,
                      color: (isMatch || status == 'accepted') ? const Color(0xFF42D368) : const Color(0xFFFF2D55),
                      iconColor: Colors.white,
                      size: 60,
                      shadowColor: ((isMatch || status == 'accepted') ? const Color(0xFF42D368) : const Color(0xFFFF2D55)).withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            // Clickable area for profile view (top part only to avoid blocking buttons)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 120, 
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewProfileScreen(userId: user.id!),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
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

  Widget _buildPlaceholderBackground(String? gender) {
    bool isFemale = gender?.toLowerCase() == 'female';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isFemale
              ? [const Color(0xFFFFEBF0), const Color(0xFFFFD1DC)]
              : [
                  const Color(0xFFE0F7FA),
                  const Color(0xFFB2EBF2)
                ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.face,
          size: 80,
          color: isFemale
              ? const Color(0xFF0D47A1).withOpacity(0.3)
              : const Color(0xFF00BCD4).withOpacity(0.3),
        ),
      ),
    );
  }

  Future<void> _handleInterestAction(int userId, bool accept) async {
    try {
      final status = await MatchingService.getReceivedInterests();
      if (status.statusCode == 200) {
        final data = json.decode(status.body);
        final List<dynamic> received = data['interests']['data'] ?? [];
        final interest = received.firstWhere(
          (i) => i['sender_id'] == userId && i['status'] == 'pending',
          orElse: () => null,
        );

        if (interest != null) {
          final response = accept 
            ? await MatchingService.acceptInterest(interest['id'])
            : await MatchingService.rejectInterest(interest['id']);

          if (response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(accept ? 'Interest accepted!' : 'Interest declined'),
                backgroundColor: accept ? accentGreen : Colors.redAccent,
              ),
            );
            _loadData();
          }
        }
      }
    } catch (e) {
      print('Error handling interest: $e');
    }
  }

  Future<void> _sendInterest(int userId) async {
    try {
      final response = await MatchingService.sendInterest(userId);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Interest sent successfully!'),
            backgroundColor: accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        _loadData();
      } else {
        final data = json.decode(response.body);
        String message = data['error'] ?? 'Failed to send interest';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}