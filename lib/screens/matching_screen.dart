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
          final user = User.fromJson({
            'email': userJson['email'] ?? '',
            ...userJson,
          });

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
          final currentUser = 1; // This would come from auth provider
          final user = match['user1']['id'] != currentUser
              ? User.fromJson({
                  'email': match['user1']['email'] ?? '',
                  ...match['user1'],
                })
              : User.fromJson({
                  'email': match['user2']['email'] ?? '',
                  ...match['user2'],
                });

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
          final user = User.fromJson({
            'email': interest['receiver']['email'] ?? '',
            ...interest['receiver'],
          });

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
          final user = User.fromJson({
            'email': interest['sender']['email'] ?? '',
            ...interest['sender'],
          });

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
    bool isSuggestion = false,
    bool isMatch = false,
    bool isInterest = false,
    String? status,
  }) {
    final theme = Theme.of(context);

    return Card(
      color: theme.brightness == Brightness.dark
          ? Colors.grey[800]
          : Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        leading: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: user.userProfile?.profilePicture == null
                ? const LinearGradient(colors: [gradientPurple, gradientBlue])
                : null,
          ),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.transparent,
            backgroundImage: user.userProfile?.profilePicture != null
                ? NetworkImage(ApiService.getImageUrl(user.userProfile!.profilePicture!))
                : null,
            child: user.userProfile?.profilePicture == null
                ? const Icon(Icons.person, color: Colors.white, size: 30)
                : null,
          ),
        ),
        title: Text(
          '${user.userProfile?.firstName ?? ''} ${user.userProfile?.lastName ?? ''}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: theme.brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${user.userProfile?.age != null ? '${user.userProfile!.age} years' : ''} • ${user.userProfile?.city ?? ''}',
              style: TextStyle(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
                fontSize: 14,
              ),
            ),
            if (isInterest && status != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'accepted'
                      ? gradientGreen.withOpacity(0.2)
                      : status == 'rejected'
                      ? Colors.red.withOpacity(0.2)
                      : gradientBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: status == 'accepted'
                        ? gradientGreen
                        : status == 'rejected'
                        ? Colors.red
                        : gradientBlue,
                    width: 1,
                  ),
                ),
                child: Text(
                  'Status: ${status.toUpperCase()}',
                  style: TextStyle(
                    color: status == 'accepted'
                        ? gradientGreen
                        : status == 'rejected'
                        ? Colors.red
                        : gradientBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: isSuggestion
            ? Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [gradientPurple, gradientBlue],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gradientBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.white),
                  onPressed: () => _sendInterest(user.id!),
                ),
              )
            : isMatch
            ? Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [gradientBlue, gradientGreen],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gradientGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.message, color: Colors.white),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Messaging feature coming soon!'),
                      ),
                    );
                  },
                ),
              )
            : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewProfileScreen(userId: user.id!),
            ),
          );
        },
      ),
    );
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

extension on UserProfile {
  int? get age {
    if (dateOfBirth != null) {
      var today = DateTime.now();
      var age = today.year - dateOfBirth!.year;
      if (today.month < dateOfBirth!.month ||
          (today.month == dateOfBirth!.month && today.day < dateOfBirth!.day)) {
        age--;
      }
      return age;
    }
    return null;
  }
}
