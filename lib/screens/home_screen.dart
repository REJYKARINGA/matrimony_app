import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/matching_service.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import 'profile_screen_view.dart';
import 'matching_screen.dart';
import 'messages_screen.dart';
import 'subscription_screen.dart';
import 'settings_screen.dart';
import 'view_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _refreshUserData();
  }

  Future<void> _refreshUserData() async {
    if (!_isRefreshing) {
      setState(() {
        _isRefreshing = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.loadCurrentUserWithProfile();

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
    int index,
  ) {
    bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.25)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 1),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSelected ? 9 : 8,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Check if user has completed their profile
    if (authProvider.user != null && authProvider.user!.userProfile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/create-profile');
      });
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        height: 65,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFB47FFF), // Purple
              Color(0xFF5CB3FF), // Blue
              Color(0xFF4CD9A6), // Green
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF5CB3FF),
              blurRadius: 20,
              offset: Offset(0, -3),
              spreadRadius: 0,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0),
                _buildNavItem(
                  Icons.favorite_outline,
                  Icons.favorite,
                  'Matches',
                  1,
                ),
                _buildNavItem(
                  Icons.chat_bubble_outline,
                  Icons.chat_bubble,
                  'Messages',
                  2,
                ),
                _buildNavItem(
                  Icons.person_outline,
                  Icons.person,
                  'Settings',
                  3,
                ),
              ],
            ),
          ),
        ),
      ),
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
  Set<int> _sentInterests = {}; // Track which users have received interests
  bool _isLoadingInterests = false;

  @override
  void initState() {
    super.initState();
    // Load sent interests first, then load recommended users
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSentInterests().then((_) {
        _loadRecommendedUsers();
      });
    });
  }

  Future<void> _loadSentInterests() async {
    try {
      final response = await MatchingService.getSentInterests();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> interestsData;

        // Handle different response formats
        if (data is List) {
          interestsData = data;
        } else if (data is Map<String, dynamic>) {
          // Check for paginated format
          if (data.containsKey('data')) {
            interestsData = data['data'] is List ? List.from(data['data']) : [];
          } else {
            interestsData = [];
          }
        } else {
          interestsData = [];
        }

        // Extract the receiver user IDs from the interests
        Set<int> sentInterestIds = {};
        for (var interest in interestsData) {
          if (interest is Map<String, dynamic> &&
              interest.containsKey('receiver_id')) {
            // Ensure the receiver_id is an integer
            if (interest['receiver_id'] is int) {
              sentInterestIds.add(interest['receiver_id']);
            } else if (interest['receiver_id'] is String) {
              try {
                sentInterestIds.add(int.parse(interest['receiver_id']));
              } catch (e) {
                print(
                  'Could not parse receiver_id: ${interest["receiver_id"]} - $e',
                );
              }
            }
          }
        }

        setState(() {
          _sentInterests = sentInterestIds;
        });
      }
    } catch (e) {
      print('Error loading sent interests: $e');
      // Initialize with empty set if there's an error
      if (mounted) {
        setState(() {
          _sentInterests = {};
        });
      }
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
        final responseBody = response.body;
        dynamic decodedData;

        try {
          decodedData = json.decode(responseBody);
        } catch (e) {
          setState(() {
            _recommendedError = 'Error parsing response data: $e';
            _isLoadingRecommended = false;
          });
          return;
        }

        List<dynamic> usersData;

        // Handle the specific response format from the backend API
        // The response structure is: {"suggestions": {"data": [...]}}
        if (decodedData is List) {
          // Response is a direct list of users
          usersData = List.from(decodedData);
        } else if (decodedData is Map<String, dynamic>) {
          // Check if it's the paginated format: {"suggestions": {"data": [...]}}
          if (decodedData.containsKey('suggestions') &&
              decodedData['suggestions'] is Map<String, dynamic>) {
            var suggestionsData =
                decodedData['suggestions'] as Map<String, dynamic>;
            usersData = suggestionsData['data'] is List
                ? List.from(suggestionsData['data'])
                : [];
          }
          // Or check if it has a 'users' key
          else if (decodedData.containsKey('users')) {
            usersData = decodedData['users'] is List
                ? List.from(decodedData['users'])
                : [];
          }
          // Or fallback to direct data key
          else if (decodedData.containsKey('data')) {
            usersData = decodedData['data'] is List
                ? List.from(decodedData['data'])
                : [];
          } else {
            // Unexpected response format
            usersData = [];
          }
        } else {
          // Unexpected response format
          usersData = [];
        }

        List<User> allUsers = [];

        // Safely parse each user
        for (var userData in usersData) {
          if (userData is Map<String, dynamic>) {
            try {
              allUsers.add(User.fromJson(userData));
            } catch (e) {
              print('Error parsing user data: $e');
              print('Problematic user data: $userData');
            }
          }
        }

        // Get current user's profile to determine gender for filtering
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProvider.user;
        final currentUserProfile = currentUser?.userProfile;

        List<User> filteredUsers;

        // If user is admin, show all users regardless of gender
        if (currentUser?.role == 'admin') {
          filteredUsers = allUsers;
        } else {
          // For non-admin users, show only opposite gender users
          if (currentUserProfile?.gender != null) {
            String currentUserGender = currentUserProfile!.gender!;
            filteredUsers = allUsers.where((user) {
              // Filter out users with the same gender as current user
              // Also make sure the other user has a gender specified
              return user.userProfile?.gender != null &&
                  user.userProfile!.gender!.toLowerCase() !=
                      currentUserGender.toLowerCase();
            }).toList();
          } else {
            // If current user has no gender specified, show all users
            filteredUsers = allUsers;
          }
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

    // Check if user has completed their profile
    if (authProvider.user != null && authProvider.user!.userProfile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/create-profile');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = authProvider.user;
    final profile = user?.userProfile;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // App Bar with Gradient
          SliverAppBar(
            floating: false,
            pinned: true,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFB47FFF), // Purple
                    Color(0xFF5CB3FF), // Blue
                    Color(0xFF4CD9A6), // Green
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
            title: const Text('Dashboard'),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                ),
                onPressed: () {
                  // TODO: Navigate to notifications
                },
              ),
            ],
          ),

          // Profile cards
          _isLoadingRecommended
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(
                        color: Color(0xFF5CB3FF),
                      ),
                    ),
                  ),
                )
              : _recommendedError != null
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(_recommendedError!),
                  ),
                )
              : _recommendedUsers.isEmpty
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No recommendations available'),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: _buildDynamicProfileCard(
                        context,
                        _recommendedUsers[index],
                      ),
                    );
                  }, childCount: _recommendedUsers.length),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  static bool _isProfileIncomplete(profile) {
    return profile.bio == null ||
        profile.education == null ||
        profile.occupation == null;
  }

  static Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicProfileCard(BuildContext context, User user) {
    final profile = user.userProfile;

    // Calculate age from date of birth
    String ageText = '';
    if (profile?.dateOfBirth != null) {
      final today = DateTime.now();
      final birthDate = profile!.dateOfBirth!;
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      ageText = '$age years';
    }

    String locationText = '';
    if (profile?.city != null) {
      locationText += profile!.city!;
    }
    if (profile?.state != null) {
      if (locationText.isNotEmpty) locationText += ', ';
      locationText += profile!.state!;
    }

    return GestureDetector(
      onTap: () {
        // Navigate to view user profile
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewProfileScreen(userId: user.id!),
          ),
        );
      },
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5CB3FF).withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFB47FFF).withOpacity(0.1),
                        const Color(0xFF5CB3FF).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                    child: Image.network(
                      profile?.profilePicture != null &&
                              profile!.profilePicture!.isNotEmpty
                          ? ApiService.getImageUrl(profile.profilePicture!)
                          : (profile?.gender?.toLowerCase() == 'female'
                                ? 'https://media.gettyimages.com/id/1987096880/photo/womens-health-appointment.jpg?s=612x612&w=0&k=20&c=FsN7Z3w1j44RKO-_B5LcbzAK4-NHlmwiQq9aKeMi8Qw='
                                : 'https://media.gettyimages.com/id/1540766473/photo/young-adult-male-design-professional-smiles-for-camera.jpg?s=612x612&w=0&k=20&c=BbwgfMOtFOIJn1Km-ASix_EBbF9SHW5h0FtWbna5nFk='),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 60,
                          color: Color(0xFF5CB3FF),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${profile?.firstName ?? 'User'} ${profile?.lastName ?? ''}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ageText}${locationText.isNotEmpty ? ' • $locationText' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade300,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                // TODO: Implement close/dismiss action
                              },
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade300,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.chat_bubble_outline,
                                color: Color(0xFF5CB3FF),
                              ),
                              onPressed: () {
                                // Navigate to messages
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const MessagesScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade300,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.star_outline,
                                color: Color(0xFFFFB800),
                              ),
                              onPressed: () {
                                // TODO: Implement shortlist action
                              },
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: _sentInterests.contains(user.id ?? -1)
                                  ? null
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFFB47FFF),
                                        Color(0xFF5CB3FF),
                                      ],
                                    ),
                              color: _sentInterests.contains(user.id ?? -1)
                                  ? Colors.white
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: _sentInterests.contains(user.id ?? -1)
                                      ? Colors.grey.shade300
                                      : const Color(
                                          0xFF5CB3FF,
                                        ).withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                _sentInterests.contains(user.id ?? -1)
                                    ? Icons.check
                                    : Icons.favorite_outline,
                                color: _sentInterests.contains(user.id ?? -1)
                                    ? Colors.green
                                    : Colors.white,
                              ),
                              onPressed: () async {
                                // Check if interest already sent
                                if (_sentInterests.contains(user.id ?? -1)) {
                                  // Interest already sent, show message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Interest already sent to this user',
                                      ),
                                      backgroundColor: Colors.blue,
                                    ),
                                  );
                                } else {
                                  // Send interest to user
                                  try {
                                    final response =
                                        await MatchingService.sendInterest(
                                          user.id!,
                                        );
                                    if (response.statusCode == 200) {
                                      // Add to sent interests set
                                      setState(() {
                                        _sentInterests.add(user.id!);
                                      });

                                      // Show success message
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Interest sent successfully!',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else {
                                      // Show error message
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to send interest: ${response.statusCode}',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    // Show error message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error sending interest: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
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
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.visibility, color: Color(0xFF5CB3FF)),
                onPressed: () {
                  // Navigate to view user profile
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
    );
  }
}
