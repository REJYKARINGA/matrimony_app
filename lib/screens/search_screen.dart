import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/search_service.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../services/location_service.dart';
import '../services/matching_service.dart';
import '../services/shortlist_service.dart';
import 'view_profile_screen.dart';
import 'messages_screen.dart';
import '../widgets/common_footer.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _updateLocationAndLoad();
  }

  Future<void> _updateLocationAndLoad() async {
    // Try to update location in background
    LocationService.getCurrentLocation().then((position) {
      if (position != null) {
        LocationService.updateLocationToServer(position).then((_) {
          // If location was updated, reload categories to show GPS card
          _loadPreferenceMatches();
        });
      }
    });

    // Initial load
    _loadPreferenceMatches();
  }

  Future<void> _loadPreferenceMatches() async {
    try {
      final response = await SearchService.getPreferenceMatches();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _categories = data['categories'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load searches';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Discover Matches',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF6A5AE0).withOpacity(0.05),
                      Colors.white,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF6A5AE0).withOpacity(0.05),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, top: 70.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Discover Matches',
                            style: TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontWeight: FontWeight.w900,
                              fontSize: 32,
                              letterSpacing: -1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Find your perfect soulmate\nbased on your preferences",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 15,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6A5AE0))),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
            )
          else if (_categories.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 80, color: Color(0xFFD1D1D1)),
                    SizedBox(height: 16),
                    Text(
                      'No preference cards available',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Fill in your preferences to see matches!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.82,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = _categories[index];
                    return _buildPreferenceCard(category, index);
                  },
                  childCount: _categories.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildPreferenceCard(dynamic category, int index) {
    IconData iconData;
    List<Color> gradientColors;
    Color iconBackgroundColor;

    switch (category['field']) {
      case 'religion':
        iconData = Icons.church_rounded;
        gradientColors = [const Color(0xFF6DD5FA), const Color(0xFF2980B9)];
        iconBackgroundColor = const Color(0xFFE3F2FD);
        break;
      case 'caste':
        iconData = Icons.groups_rounded;
        gradientColors = [const Color(0xFFFDC830), const Color(0xFFF37335)];
        iconBackgroundColor = const Color(0xFFFFF3E0);
        break;
      case 'occupation':
        iconData = Icons.work_rounded;
        gradientColors = [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)];
        iconBackgroundColor = const Color(0xFFF3E5F5);
        break;
      case 'education':
        iconData = Icons.school_rounded;
        gradientColors = [const Color(0xFF11998E), const Color(0xFF38EF7D)];
        iconBackgroundColor = const Color(0xFFE8F5E9);
        break;
      case 'marital_status':
        iconData = Icons.favorite_rounded;
        gradientColors = [const Color(0xFFFF5F6D), const Color(0xFFFFC371)];
        iconBackgroundColor = const Color(0xFFFFEBEE);
        break;
      case 'age':
        iconData = Icons.calendar_month_rounded;
        gradientColors = [const Color(0xFF2193B0), const Color(0xFF6DD5ED)];
        iconBackgroundColor = const Color(0xFFE0F7FA);
        break;
      case 'location':
        iconData = Icons.location_on_rounded;
        gradientColors = [const Color(0xFF00B4DB), const Color(0xFF0083B0)];
        iconBackgroundColor = const Color(0xFFE1F5FE);
        break;
      case 'near_me':
      case 'near_me_gps':
        iconData = Icons.near_me_rounded;
        gradientColors = [const Color(0xFFFC466B), const Color(0xFF3F5EFB)];
        iconBackgroundColor = const Color(0xFFF3E5F5);
        break;
      case 'height':
        iconData = Icons.height_rounded;
        gradientColors = [const Color(0xFF74EBD5), const Color(0xFF9FACE6)];
        iconBackgroundColor = const Color(0xFFE0F2F1);
        break;
      case 'income':
        iconData = Icons.payments_rounded;
        gradientColors = [const Color(0xFF13547A), const Color(0xFF80D0C7)];
        iconBackgroundColor = const Color(0xFFE0F7FA);
        break;
      case 'mother_tongue':
        iconData = Icons.translate_rounded;
        gradientColors = [const Color(0xFF667EEA), const Color(0xFF764BA2)];
        iconBackgroundColor = const Color(0xFFE8EAF6);
        break;
      case 'new_members':
        iconData = Icons.person_add_rounded;
        gradientColors = [const Color(0xFFF093FB), const Color(0xFFF5576C)];
        iconBackgroundColor = const Color(0xFFFCE4EC);
        break;
      default:
        iconData = Icons.grid_view_rounded;
        gradientColors = [const Color(0xFF757F9A), const Color(0xFFD7DDE8)];
        iconBackgroundColor = Colors.grey.shade100;
    }

    return GestureDetector(
      onTap: () => _navigateToResults(category),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: gradientColors[1].withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        gradientColors[0].withOpacity(0.1),
                        gradientColors[1].withOpacity(0.02),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: iconBackgroundColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        iconData,
                        size: 28,
                        color: gradientColors[1],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      category['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF2D2D2D),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            category['value'].toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: gradientColors),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: gradientColors[1].withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            category['count'].toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToResults(dynamic category) {
    // Log click for trending sort
    SearchService.logDiscoveryClick(category['field'] ?? 'unknown');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          title: category['title'],
          filter: category,
        ),
      ),
    );
  }
}

class SearchResultsScreen extends StatefulWidget {
  final String title;
  final dynamic filter;

  const SearchResultsScreen({
    Key? key,
    required this.title,
    required this.filter,
  }) : super(key: key);

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  Set<int> _sentInterests = {};
  Set<int> _matchedUserIds = {};
  Set<int> _shortlistedUserIds = {};

  @override
  void initState() {
    super.initState();
    _loadResults();
    _loadInterestsAndMatches();
    _loadShortlistedProfiles();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadShortlistedProfiles() async {
    try {
      final response = await ShortlistService.getShortlistedProfiles();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> shortlistedData;
        if (data is Map<String, dynamic> && data.containsKey('shortlisted')) {
          final shortlistedMap = data['shortlisted'] as Map<String, dynamic>;
          shortlistedData = shortlistedMap['data'] is List ? List.from(shortlistedMap['data']) : [];
        } else {
          shortlistedData = [];
        }
        Set<int> ids = {};
        for (var item in shortlistedData) {
          if (item is Map<String, dynamic> && item.containsKey('shortlisted_user_id')) {
            ids.add(int.parse(item['shortlisted_user_id'].toString()));
          }
        }
        if (mounted) setState(() => _shortlistedUserIds = ids);
      }
    } catch (e) {
      print('Error loading shortlists: $e');
    }
  }

  Future<void> _loadInterestsAndMatches() async {
    try {
      final sentResponse = await MatchingService.getSentInterests();
      final receivedResponse = await MatchingService.getReceivedInterests();
      Set<int> sentIds = {};
      Set<int> matchedIds = {};

      if (sentResponse.statusCode == 200) {
        final data = json.decode(sentResponse.body);
        List<dynamic> interestsData = data['interests']?['data'] ?? [];
        for (var interest in interestsData) {
          int? receiverId = int.tryParse(interest['receiver_id'].toString());
          if (receiverId != null) {
            sentIds.add(receiverId);
            if (interest['status'] == 'accepted') matchedIds.add(receiverId);
          }
        }
      }

      if (receivedResponse.statusCode == 200) {
        final data = json.decode(receivedResponse.body);
        List<dynamic> interestsData = data['interests']?['data'] ?? [];
        for (var interest in interestsData) {
          int? senderId = int.tryParse(interest['sender_id'].toString());
          if (senderId != null && interest['status'] == 'accepted') matchedIds.add(senderId);
        }
      }

      if (mounted) {
        setState(() {
          _sentInterests = sentIds;
          _matchedUserIds = matchedIds;
        });
      }
    } catch (e) {
      print('Error loading interests/matches: $e');
    }
  }

  Future<void> _handleQuickInterest(int userId) async {
    try {
      final response = await MatchingService.sendInterest(userId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _sentInterests.add(userId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Interest sent!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadResults();
    }
  }

  Future<void> _loadResults() async {
    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final field = widget.filter['field'];
      final value = widget.filter['value'];

      String? religion,
          caste,
          occupation,
          education,
          maritalStatus,
          location;
      int? minAge, maxAge;

      if (field == 'religion') religion = value;
      if (field == 'caste') caste = value;
      if (field == 'occupation') occupation = value;
      if (field == 'education') education = value;
      if (field == 'marital_status') maritalStatus = value;
      if (field == 'location' || field == 'near_me') location = value;
      if (field == 'age') {
        // Parse "25 - 35 Years"
        final parts = value.toString().split(' ');
        if (parts.length >= 3) {
          minAge = int.tryParse(parts[0]);
          maxAge = int.tryParse(parts[2]);
        }
      }
      if (field == 'near_me_gps') {
        final responseNearby = await SearchService.getNearbyProfiles(
          radius: 50,
          page: _currentPage,
        );
        if (responseNearby.statusCode == 200) {
          final data = json.decode(responseNearby.body);
          final List<dynamic> profilesData = data['profiles']['data'] ?? [];
          List<User> newUsers = profilesData.map((u) => User.fromJson(u)).toList();

          setState(() {
            _users.addAll(newUsers);
            _isLoading = false;
            _currentPage++;
            _hasMore = data['profiles']['next_page_url'] != null;
          });
          return;
        }
      }

      final response = await SearchService.searchProfiles(
        religion: religion,
        caste: caste,
        occupation: occupation,
        education: education,
        maritalStatus: maritalStatus,
        location: location,
        minAge: minAge,
        maxAge: maxAge,
        field: field,
        page: _currentPage,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> profilesData = data['profiles']['data'] ?? [];
        List<User> newUsers = profilesData.map((u) => User.fromJson(u)).toList();

        setState(() {
          _users.addAll(newUsers);
          _isLoading = false;
          _currentPage++;
          _hasMore = data['profiles']['next_page_url'] != null;
        });
      } else {
        setState(() {
          _error = 'Failed to load results';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF6A5AE0)),
            onPressed: () {
               Navigator.of(context).pushReplacementNamed('/preferences');
            },
            tooltip: 'Update Preferences',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _error != null
          ? Center(child: Text(_error!))
          : _users.isEmpty && !_isLoading
          ? const Center(child: Text('No matches found'))
          : ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
        itemCount: _users.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _users.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final user = _users[index];
          return _buildDynamicProfileCard(user);
        },
      ),
      bottomNavigationBar: const CommonFooter(),
    );
  }

  Widget _buildDynamicProfileCard(User user) {
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

    return Container(
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
              child: profile?.profilePicture != null
                  ? Image.network(
                      ApiService.getImageUrl(profile!.profilePicture!),
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
                  if (profile?.religion != null || profile?.caste != null)
                    Text(
                      '${profile?.religion ?? ''}${profile?.religion != null && profile?.caste != null ? ', ' : ''}${profile?.caste ?? ''}'
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
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => ChatScreen(
                            otherUserId: user.id!,
                            otherUserName: '${user.matrimonyId ?? 'User'}',
                            otherUserImage: user.userProfile?.profilePicture != null
                                ? ApiService.getImageUrl(user.userProfile!.profilePicture!)
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
            Positioned.fill(
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
}
