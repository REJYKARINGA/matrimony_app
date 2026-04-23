import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:ui';
import '../models/user_model.dart';
import '../services/matching_service.dart';
import '../services/api_service.dart';
import 'view_profile_screen.dart';
import 'messages_screen.dart' as msg;
import '../services/shortlist_service.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/navigation_provider.dart';
import '../services/photo_request_service.dart';
import '../widgets/watermark_overlay.dart';

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
  List<dynamic> _blockedUsers = [];
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
        ApiService.makeRequest('${ApiService.baseUrl}/users/blocked'),
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

      // Process blocked users
      if (results[4].statusCode == 200) {
        final data = json.decode(results[4].body);
        _blockedUsers = data['blocked_users']['data'] ?? [];
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

  Future<void> _handlePhotoRequest(User user) async {
    if (user.id == null) return;
    
    try {
      final response = await PhotoRequestService.sendRequest(user.id!);
      if (response.statusCode == 201 || response.statusCode == 200) {
        _loadInitialData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo request sent successfully!'), backgroundColor: Colors.green),
          );
        }
      } else {
        final data = json.decode(response.body);
        final String errorMsg = data['error'] ?? 'Unknown error';
        if (errorMsg.contains('already sent') || data['status'] == 'pending') {
          _loadInitialData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo request is already pending.'), backgroundColor: Colors.orange),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to send request: $errorMsg'), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(gradientCyan),
        ),
      );
    }

    final bool hasDeclinedInterests = _declinedInterests.isNotEmpty;
    final bool hasBlockedUsers = _blockedUsers.isNotEmpty;

    if (!hasDeclinedInterests && !hasBlockedUsers) {
      return _buildEmptyState(
        icon: Icons.block_rounded,
        title: 'No Declined Interactions',
        description: 'Profiles you or others have declined will appear here. No activity yet!',
      );
    }

    return RefreshIndicator(
      color: gradientCyan,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        children: [
          // --- Declined Interests Section ---
          if (hasDeclinedInterests) ...
            _declinedInterests.map((interest) {
              if (interest == null) return const SizedBox.shrink();
              final bool isSentByMe = interest['sender_id'] == _currentUserId;
              final userJson = isSentByMe ? interest['receiver'] : interest['sender'];
              if (userJson == null) return const SizedBox.shrink();
              final user = User.fromJson(userJson);
              return _buildProfileCard(
                user,
                isInterest: true,
                status: interest['status'],
                isSentByMe: isSentByMe,
                interestId: interest['id'],
              );
            }).toList(),

          // --- Blocked / Dismissed Section ---
          if (hasBlockedUsers) ...([
            if (hasDeclinedInterests)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                child: Row(
                  children: [
                    Icon(Icons.block_rounded, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(
                      'Dismissed Profiles',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ..._blockedUsers.map((block) {
              final blockedUserJson = block['blocked_user'];
              if (blockedUserJson == null) return const SizedBox.shrink();
              final user = User.fromJson(blockedUserJson);
              return _buildProfileCard(
                user,
                status: 'blocked',
                blockId: block['id'],
              );
            }).toList(),
          ]),
        ],
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
      return _buildEmptyState(
        icon: Icons.favorite_rounded,
        title: 'No Matches Yet',
        description: "Your perfect match might be just a swipe away! Keep exploring profiles to find someone special.",
        actionLabel: 'Browse Profiles',
        onAction: () => Provider.of<NavigationProvider>(context, listen: false).setSelectedIndex(0), 
      );
    }

    return RefreshIndicator(
      color: gradientCyan,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        itemCount: _matches.length,
        itemBuilder: (context, index) {
          final match = _matches[index];
          if (match == null) return const SizedBox.shrink();
          
          dynamic otherUserJson;
          // Check for new API structure 'user' key first
          if (match['user'] != null) {
            otherUserJson = match['user'];
          } 
          // Fallback to old structure with user1/user2 if needed
          else if (match['user1'] != null && match['user2'] != null) {
            final currentUser = _currentUserId; 
            otherUserJson = match['user1']['id']?.toString() != currentUser?.toString()
                ? match['user1']
                : match['user2'];
          }
              
          if (otherUserJson == null) return const SizedBox.shrink();
          
          try {
            final user = User.fromJson(otherUserJson);
            return _buildProfileCard(user, isMatch: true, isSentByMe: true);
          } catch (e) {
            print('Error parsing user in matches: $e');
            return const SizedBox.shrink();
          }
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
      return _buildEmptyState(
        icon: Icons.send_rounded,
        title: 'Nothing Sent Yet',
        description: "Be proactive! When you find an interesting profile, send them an interest to start your journey.",
        actionLabel: 'Browse Profiles',
        onAction: () => Provider.of<NavigationProvider>(context, listen: false).setSelectedIndex(0),
      );
    }

    return RefreshIndicator(
      color: gradientCyan,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            isSentByMe: true,
            interestId: interest['id'],
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
      return _buildEmptyState(
        icon: Icons.notifications_active_rounded,
        title: 'Waiting for Responses',
        description: "No interests received so far. Enhance your profile with better photos to attract more attention.",
        actionLabel: 'Browse Profiles',
        onAction: () => Provider.of<NavigationProvider>(context, listen: false).setSelectedIndex(0),
      );
    }

    return RefreshIndicator(
      color: gradientCyan,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            isSentByMe: false,
            interestId: interest['id'],
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
    bool isSentByMe = false,
    int? interestId,
    int? blockId,
  }) {
    final profile = user.userProfile;
    final isBlurred = (user.isDisplayImageVerified != true) || user.hasHiddenPhotos;
    
    final age = profile?.age;
    String ageText = age != null ? age.toString() : '';

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

    String currentLoc = [
      profile?.presentCity,
      profile?.presentCountry,
    ].where((e) => e != null && e.isNotEmpty).join(', ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  user.displayImage != null
                      ? Image.network(
                          ApiService.getImageUrl(user.displayImage!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholderBackground(profile?.gender),
                        )
                      : _buildPlaceholderBackground(profile?.gender),
                  if (user.displayImage != null && user.displayImage!.trim().isNotEmpty && user.displayImage != 'null') const WatermarkOverlay(),
                    if ((user.displayImage != null && isBlurred) || (user.displayImage == null))
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: Container(
                          color: Colors.black.withOpacity(0.4),
                          child: Align(
                            alignment: const Alignment(0, -0.3),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  (user.displayImage == null)
                                    ? Icons.no_photography_rounded
                                    : (user.isDisplayImageVerified != true 
                                        ? Icons.pending_actions_rounded 
                                        : (user.photoRequestRejected == true 
                                            ? Icons.block_rounded 
                                            : (user.photoRequestPending == true 
                                                ? Icons.pending_actions_rounded 
                                                : Icons.lock_person_rounded))),
                                  color: Colors.white,
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  (user.displayImage == null)
                                    ? 'No Photos Uploaded'
                                    : (user.isDisplayImageVerified != true 
                                        ? 'Photo in Verification' 
                                        : (user.photoRequestRejected == true 
                                            ? 'ACCESS DECLINED' 
                                            : (user.photoRequestPending == true 
                                                ? 'Access Request Pending' 
                                                : 'Photos are Private'))),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                                if (((user.displayImage == null) || (user.isDisplayImageVerified == true && user.hasHiddenPhotos == true)) && 
                                    !(user.photoRequestPending ?? false) && 
                                    !(user.photoRequestRejected ?? false)) ...[
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: () => _handlePhotoRequest(user),
                                    icon: const Icon(Icons.key_rounded, size: 14),
                                    label: Text(
                                      (user.displayImage == null) ? 'Request Photo' : 'Request Access',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00BCD4),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
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
            if (status != null)
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
                                : status == 'blocked'
                                    ? Colors.grey.shade700
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
                    status == 'blocked' ? 'DISMISSED' : status.toUpperCase(),
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
                  // Row 1: Matrimony ID & Age
                  Row(
                    children: [
                      Text(
                        '${profile?.changedFields?.contains('first_name') == true ? 'Under Review' : user.matrimonyId ?? 'User'}${ageText.isNotEmpty ? ', $ageText' : ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (user.userProfile?.isActiveVerified == true)
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF00BCD4),
                          size: 18,
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          user.lastActiveString,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Row 2: Height, Marital Status, Caste
                  Text(
                    '${profile?.height != null ? '${profile!.height} cm, ' : ''}$maritalStatus, ${profile?.caste ?? ''}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Row 3: Education, Occupation
                  if ((profile?.education ?? '').isNotEmpty || (profile?.occupation ?? '').isNotEmpty)
                    Text(
                      '${profile?.education ?? ''}${profile?.education != null && (profile?.occupation ?? '').isNotEmpty ? ', ' : ''}${profile?.occupation ?? ''}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 8),

                  // Row 4: Location & Distance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: Colors.white.withOpacity(0.8),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.isNotEmpty ? loc : 'Unknown Location',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (currentLoc.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        'Present: $currentLoc',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (user.distance != null)
                        Container(
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
              child: status == 'blocked'
                  // --- Blocked: show Unblock button only ---
                  ? GestureDetector(
                      onTap: () async {
                        if (blockId == null) return;
                        try {
                          final response = await ApiService.makeRequest(
                            '${ApiService.baseUrl}/users/${user.id}/block',
                            method: 'DELETE',
                          );
                          if (response.statusCode == 200 && mounted) {
                            setState(() {
                              _blockedUsers.removeWhere((b) => b['id'] == blockId);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile unblocked')),
                            );
                          }
                        } catch (e) {
                          print('Error unblocking: $e');
                        }
                      },
                      child: Container(
                        height: 55,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [gradientCyan, gradientLightBlue],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: gradientCyan.withOpacity(0.35),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_open_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'UNBLOCK PROFILE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Row(
              children: [
                  // Close / Dismiss (Always shown)
                  GestureDetector(
                    onTap: () {
                      if (isInterest && status == 'pending' && !isSentByMe && interestId != null) {
                         _handleInterestAction(interestId, false);
                      } else {
                         _dismissProfile(user.id!);
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
                  const SizedBox(width: 12),

                  // If Matched, show full width contact button
                  if (status == 'accepted' || isMatch)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewProfileScreen(userId: user.id!),
                            ),
                          );
                        },
                        child: Container(
                          height: 55,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xFF42D368), Color(0xFF2E7D32)],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF42D368).withOpacity(0.35),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.phone_iphone_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  'VIEW PROFILE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    // Otherwise show standard action buttons
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
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
                              if (isInterest && status == 'pending' && !isSentByMe && interestId != null) {
                                 _handleInterestAction(interestId, true);
                              } else if (!isMatch && status != 'accepted' && (status != 'pending' || !isSentByMe)) {
                                 _sendInterest(user.id!);
                              }
                            },
                            child: _buildFloatingButton(
                              icon: (status == 'pending' && isSentByMe) ? Icons.done_all_rounded : (status == 'pending' && !isSentByMe ? Icons.check_circle_rounded : Icons.favorite),
                              color: (status == 'pending' && isSentByMe) ? const Color(0xFF42D368) : (status == 'pending' && !isSentByMe ? const Color(0xFF00BCD4) : const Color(0xFFFF2D55)),
                              iconColor: Colors.white,
                              size: 60,
                              shadowColor: ((status == 'pending' && isSentByMe) ? const Color(0xFF42D368) : (status == 'pending' && !isSentByMe ? const Color(0xFF00BCD4) : const Color(0xFFFF2D55))).withOpacity(0.4),
                            ),
                          ),
                        ],
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

  Future<void> _handleInterestAction(int interestId, bool accept) async {
    try {
      final response = accept 
        ? await MatchingService.acceptInterest(interestId)
        : await MatchingService.rejectInterest(interestId);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(accept ? 'Interest accepted!' : 'Interest declined'),
              backgroundColor: accept ? accentGreen : Colors.redAccent,
            ),
          );
        }
        _loadData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to process action'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      print('Error handling interest: $e');
    }
  }

  Future<void> _dismissProfile(int userId) async {
    try {
      final response = await ApiService.makeRequest(
        '${ApiService.baseUrl}/users/$userId/block',
        method: 'POST',
        body: {'reason': 'Dismissed from matching UI'}
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile dismissed')),
          );
        }
        
        // Remove locally immediately for snappy UI
        setState(() {
          _matches.removeWhere((m) {
            final matchUser = m['user'] ?? (m['user1'] != null && m['user1']['id'] != _currentUserId ? m['user1'] : m['user2']);
            return matchUser != null && matchUser['id'] == userId;
          });
          _sentInterests.removeWhere((i) => i['receiver'] != null && i['receiver']['id'] == userId);
          _receivedInterests.removeWhere((i) => i['sender'] != null && i['sender']['id'] == userId);
          _declinedInterests.removeWhere((i) {
             final u = i['sender_id'] == _currentUserId ? i['receiver'] : i['sender'];
             return u != null && u['id'] == userId;
          });
        });
      }
    } catch (e) {
      print('Error dismissing profile: $e');
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

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF00BCD4).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: const Color(0xFF00BCD4).withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF0D47A1)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00BCD4).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}