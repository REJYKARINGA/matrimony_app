import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/matching_service.dart';
import '../services/api_service.dart';
import 'view_profile_screen.dart';

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
  bool _isLoading = true;
  String? _errorMessage;

  // Gradient colors from login page
  static const Color gradientPurple = Color(0xFFB47FFF);
  static const Color gradientBlue = Color(0xFF5CB3FF);
  static const Color gradientGreen = Color(0xFF4CD9A6);

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
      // Load all relevant data concurrently (Suggestions removed)
      final results = await Future.wait([
        MatchingService.getMatches(),
        MatchingService.getSentInterests(),
        MatchingService.getReceivedInterests(),
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
      appBar: AppBar(
        title: const Text(
          'Matches & Interests',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [gradientPurple, gradientBlue, gradientGreen],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Matches'),
            Tab(text: 'Sent'),
            Tab(text: 'Received'),
            Tab(text: 'Declined'),
          ],
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMatchesTab(),
          _buildSentInterestsTab(),
          _buildReceivedInterestsTab(),
          _buildDeclinedInterestsTab(),
        ],
      ),
    );
  }

  Widget _buildDeclinedInterestsTab() {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(gradientBlue),
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
      color: gradientBlue,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _declinedInterests.length,
        itemBuilder: (context, index) {
          final interest = _declinedInterests[index];
          // Check who the target profile is
          final bool isSentByMe = interest['sender_id'] == _currentUserId;
          
          final userJson = isSentByMe ? interest['receiver'] : interest['sender'];
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
          valueColor: AlwaysStoppedAnimation<Color>(gradientBlue),
        ),
      );
    }

    if (_matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_outline,
              size: 64,
              color: gradientPurple.withOpacity(0.5),
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
      color: gradientBlue,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _matches.length,
        itemBuilder: (context, index) {
          final match = _matches[index];
          final currentUser = _currentUserId; 
          final otherUserJson = match['user1']['id'].toString() != currentUser.toString()
              ? match['user1']
              : match['user2'];
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
          valueColor: AlwaysStoppedAnimation<Color>(gradientBlue),
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
              color: gradientBlue.withOpacity(0.5),
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
      color: gradientBlue,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _sentInterests.length,
        itemBuilder: (context, index) {
          final interest = _sentInterests[index];
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
          valueColor: AlwaysStoppedAnimation<Color>(gradientBlue),
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
              color: gradientGreen.withOpacity(0.5),
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
      color: gradientBlue,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _receivedInterests.length,
        itemBuilder: (context, index) {
          final interest = _receivedInterests[index];
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
    final theme = Theme.of(context);
    
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
      profile?.state,
    ].where((e) => e != null).join(', ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            ? const Color(0xFF4CD9A6) 
                            : status == 'rejected' 
                                ? Colors.redAccent 
                                : const Color(0xFF5CB3FF)).withOpacity(0.9),
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
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            // Profile Details
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
            // Action Buttons
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (isMatch)
                    _buildFloatingButton(
                      onTap: () {
                        // Messaging logic
                      },
                      icon: Icons.chat_bubble_rounded,
                      color: const Color(0xFF5CB3FF),
                    )
                  else if (isInterest && status == 'pending' && user.id != _currentUserId)
                    Row(
                      children: [
                        _buildFloatingButton(
                          onTap: () => _handleInterestAction(user.id!, false),
                          icon: Icons.close_rounded,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(width: 20),
                        _buildFloatingButton(
                          onTap: () => _handleInterestAction(user.id!, true),
                          icon: Icons.favorite_rounded,
                          color: const Color(0xFF4CD9A6),
                        ),
                      ],
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),
            // InkWell for full card tap
            Positioned.fill(
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
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildPlaceholderBackground(String? gender) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          gender == 'female' ? Icons.woman : Icons.man,
          size: 100,
          color: Colors.grey[400],
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
                backgroundColor: accept ? gradientGreen : Colors.redAccent,
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
            backgroundColor: gradientGreen,
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
