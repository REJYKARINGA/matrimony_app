import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/matching_service.dart';
import '../services/payment_service.dart';
import '../utils/date_formatter.dart';
import 'messages_screen.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import 'verification_screen.dart';
import 'wallet_transactions_screen.dart';
import '../services/shortlist_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class ViewProfileScreen extends StatefulWidget {
  final int userId;

  const ViewProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen>
    with SingleTickerProviderStateMixin {
  User? _user;
  bool _isLoading = true;
  String? _errorMessage;
  dynamic _interestSent;
  dynamic _interestReceived;
  bool _isActionLoading = false;
  bool _contactUnlocked = false;
  double _walletBalance = 0.0;
  int? _currentTransactionId;
  int _todayUnlockCount = 0;
  static const int _dailyUnlockLimit = 20; // Can be changed to 20 or any value
  Set<int> _shortlistedUserIds = {};
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Razorpay _razorpay;

  // Unlocked contact details (fetched via separate API)
  String? _unlockedPhone;
  String? _unlockedFatherName;
  String? _unlockedMotherName;
  bool _isLoadingContactDetails = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _loadUserProfile();
    _checkContactUnlock();
    _loadWalletBalance();
    _loadTodayUnlockCount();
    _loadShortlistedProfiles();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.makeRequest(
        '${ApiService.baseUrl}/profiles/${widget.userId}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = User.fromJson(data['user']);
        if (!mounted) return;
        setState(() {
          _user = user;
          _interestSent = data['interest_sent'];
          _interestReceived = data['interest_received'];
          _isLoading = false;
          // Set unlock status directly from profile response contact_info
          if (user.contactInfo != null) {
            _contactUnlocked = user.contactInfo!.isContactUnlocked;
          }
          // Reset cached unlocked details on refresh
          _unlockedPhone = null;
          _unlockedFatherName = null;
          _unlockedMotherName = null;
        });
        _animationController.forward();
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Failed to load profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
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

  Future<void> _handleAcceptInterest() async {
    if (_interestReceived == null) return;

    setState(() {
      _isActionLoading = true;
    });

    try {
      final response = await MatchingService.acceptInterest(
        _interestReceived['id'],
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          _interestReceived = data['interest'];
          _isActionLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Interest accepted! You are now matched.'),
            backgroundColor: Color(0xFF4CD9A6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        if (!mounted) return;
        setState(() {
          _isActionLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to accept interest')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isActionLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _handleSendInterest() async {
    if (_user?.id == null) return;

    setState(() {
      _isActionLoading = true;
    });

    try {
      final response = await MatchingService.sendInterest(_user!.id!);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          _interestSent = data['interest'];
          _isActionLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Interest sent!'),
            backgroundColor: Color(0xFF00BCD4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        if (!mounted) return;
        setState(() {
          _isActionLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send interest')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isActionLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(lightBackground: true),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00BCD4),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(lightBackground: true),
              Expanded(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Oops!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadUserProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00BCD4),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Try Again',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhotoGallery(),
                  _buildProfileDetails(),
                  _buildFooter(),
                  const SizedBox(height: 100), // Space for sticky bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildStickyBottomActions(),
      extendBody: true,
    );
  }

  Widget _buildAppBar({bool lightBackground = false}) {
    final fgColor = lightBackground ? Colors.grey.shade800 : Colors.white;
    final btnBg = lightBackground ? Colors.grey.shade300 : Colors.white.withOpacity(0.2);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: btnBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: fgColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Profile',
            style: TextStyle(
              color: fgColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final displayImage = _user?.displayImage;
    return SliverAppBar(
      expandedHeight: 420.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF00BCD4),
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.3),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WalletTransactionsScreen(),
                ),
              );
              _loadWalletBalance(); // Refresh balance after returning
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_balance_wallet, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '₹${_walletBalance.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background blur/image
            if (displayImage != null) ...[
               Image.network(
                ApiService.getImageUrl(displayImage),
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ] else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00BCD4), Color(0xFF0D47A1)],
                  ),
                ),
              ),

            // Profile Info Overlay
            Positioned(
              left: 20,
              right: 20,
              bottom: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _contactUnlocked 
                                ? '${_user?.userProfile?.firstName ?? ''} ${_user?.userProfile?.lastName ?? ''}'.trim()
                                : '${_maskName(_user?.userProfile?.firstName)} ${_maskName(_user?.userProfile?.lastName)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              '${_user?.matrimonyId ?? 'User'}${_user?.userProfile?.age != null ? ', ${_user!.userProfile!.age} yrs' : ''}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_user?.userProfile?.isActiveVerified == true)
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF00BCD4), // Turquoise
                          size: 24,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Row 2: Height, Marital Status, Caste
                  Text(
                    '${_user?.userProfile?.height != null ? '${_user!.userProfile!.height} cm, ' : ''}${_user?.userProfile?.maritalStatus?.toLowerCase() == 'never_married' ? 'Single' : (_user?.userProfile?.maritalStatus ?? '').replaceAll('_', ' ').split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word).join(' ')}, ${_user?.userProfile?.caste ?? ''}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Row 3: Education, Occupation
                  if ((_user?.userProfile?.education ?? '').isNotEmpty || (_user?.userProfile?.occupation ?? '').isNotEmpty)
                    Text(
                      '${_user?.userProfile?.education ?? ''}${(_user?.userProfile?.education != null && (_user?.userProfile?.occupation ?? '').isNotEmpty) ? ', ' : ''}${_user?.userProfile?.occupation ?? ''}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Row 4: Location & Distance Badges
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (_user?.userProfile?.city != null)
                        _buildBadge(Icons.location_on, _user!.userProfile!.city!),
                      if (_user?.userProfile?.district != null)
                        _buildBadge(Icons.map, _user!.userProfile!.district!),
                      if (_user?.distance != null)
                        _buildBadge(Icons.near_me_rounded, '${_user!.distance!.toStringAsFixed(1)} KM', isDistance: true),
                    ],
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, {bool isDistance = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDistance 
            ? const Color(0xFF00BCD4).withOpacity(0.35) 
            : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 12, 
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery() {
    final photos = _user?.profilePhotos ?? [];
    if (photos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 30, 20, 15),
          child: Text(
            'Photo Gallery',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: photos.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showFullScreenImage(index, photos),
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF00BCD4).withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: DecorationImage(
                      image: NetworkImage(ApiService.getImageUrl(photos[index].photoUrl!)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showFullScreenImage(int initialIndex, List<ProfilePhoto> photos) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              PageView.builder(
                itemCount: photos.length,
                controller: PageController(initialPage: initialIndex),
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    child: Center(
                      child: Image.network(
                        ApiService.getImageUrl(photos[index].photoUrl!),
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator(color: Colors.white));
                        },
                      ),
                    ),
                  );
                },
              ),
              // Watermark
              Positioned(
                bottom: 40,
                right: 20,
                child: Opacity(
                  opacity: 0.5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Vivah4Ever',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          shadows: const [
                            Shadow(blurRadius: 10, color: Colors.black, offset: Offset(2, 2)),
                          ],
                        ),
                      ),
                      Text(
                        'Kerala Matrimony',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Back Button
              Positioned(
                top: 40,
                left: 20,
                child: CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStickyBottomActions() {
    if (_user == null) return const SizedBox.shrink();
    
    bool isMatched =
        (_interestReceived != null &&
            _interestReceived['status'] == 'accepted') ||
        (_interestSent != null && _interestSent['status'] == 'accepted');
    bool isPending =
        _interestReceived != null && _interestReceived['status'] == 'pending';
    bool isSent = _interestSent != null && !isMatched;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Pass (Close)
          GestureDetector(
            onTap: () => Navigator.pop(context),
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
              if (isMatched && _user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      otherUserId: _user!.id!,
                      otherUserName: '${_user!.matrimonyId ?? 'User'}',
                      otherUserImage: _user?.displayImage != null
                        ? ApiService.getImageUrl(_user!.displayImage!)
                        : null,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Match first to message!'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            child: _buildFloatingButton(
              icon: Icons.chat_bubble_rounded,
              color: const Color(0xFF00BCD4),
              iconColor: Colors.white,
              size: 50,
              shadowColor: const Color(0xFF00BCD4).withOpacity(0.3),
            ),
          ),

          // Star (Save)
          GestureDetector(
            onTap: () async {
              try {
                if (_shortlistedUserIds.contains(_user!.id!)) {
                  final response = await ShortlistService.removeFromShortlist(_user!.id!);
                  if (response.statusCode == 200) {
                    setState(() {
                      _shortlistedUserIds.remove(_user!.id!);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Removed from shortlist'),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                } else {
                  final response = await ShortlistService.addToShortlist(_user!.id!);
                  if (response.statusCode == 200 || response.statusCode == 201) {
                    setState(() {
                      _shortlistedUserIds.add(_user!.id!);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Added to shortlist'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                }
              } catch (e) {
                print('Error toggling shortlist: $e');
              }
            },
            child: _buildFloatingButton(
              icon: _shortlistedUserIds.contains(_user!.id) ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _shortlistedUserIds.contains(_user!.id) ? const Color(0xFFFFD700) : Colors.white,
              iconColor: _shortlistedUserIds.contains(_user!.id) ? Colors.white : const Color(0xFFFFD700),
              size: 50,
              shadowColor: _shortlistedUserIds.contains(_user!.id) ? const Color(0xFFFFD700).withOpacity(0.4) : null,
            ),
          ),

          // Like (Heart/Check)
          GestureDetector(
            onTap: () {
              if (_isActionLoading) return;
              if (isMatched) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You are already matched!')),
                );
              } else if (isPending) {
                _handleAcceptInterest();
              } else if (isSent) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Interest already sent!')),
                );
              } else {
                _handleSendInterest();
              }
            },
            child: _buildFloatingButton(
              icon: (isMatched || isSent) ? Icons.done_all_rounded : (isPending ? Icons.check_circle_rounded : Icons.favorite_rounded),
              color: (isMatched || isSent) ? const Color(0xFF42D368) : (isPending ? const Color(0xFF00BCD4) : const Color(0xFFFF2D55)),
              iconColor: Colors.white,
              size: 60,
              shadowColor: ((isMatched || isSent) ? const Color(0xFF42D368) : (isPending ? const Color(0xFF00BCD4) : const Color(0xFFFF2D55))).withOpacity(0.4),
            ),
          ),
        ],
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

  Widget _buildProfileDetails() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((_user?.userProfile?.bio ?? '').isNotEmpty) ...[
            _buildModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF00BCD4),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'About',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    _user?.userProfile?.bio ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],
          _buildInfoSection('Personal Details', Icons.person_outline, [
            if ((_user?.userProfile?.gender ?? '').isNotEmpty)
              _buildDetailRow('Gender', _user!.userProfile!.gender!),
            if (_user?.userProfile?.height != null)
              _buildDetailRow('Height', '${_user!.userProfile!.height} cm'),
            if (_user?.userProfile?.weight != null)
              _buildDetailRow('Weight', '${_user!.userProfile!.weight} kg'),
            if ((_user?.userProfile?.maritalStatus ?? '').isNotEmpty)
              _buildDetailRow(
                'Marital Status',
                _user!.userProfile!.maritalStatus!,
              ),
          ]),
          _buildInfoSection('Lifestyle & Habits', Icons.nightlife_outlined, [
            if (_user?.userProfile?.drugAddiction != null)
              _buildDetailRow(
                'Any Drug Addiction',
                _user!.userProfile!.drugAddiction! ? 'Yes' : 'None',
              ),
            if (_user?.userProfile?.drugAddiction == true) ...[
              if ((_user?.userProfile?.smoke ?? '').isNotEmpty)
                _buildDetailRow('Smoking', _user!.userProfile!.smoke!),
              if ((_user?.userProfile?.alcohol ?? '').isNotEmpty)
                _buildDetailRow('Alcohol', _user!.userProfile!.alcohol!),
            ],
          ]),
          _buildContactSection(),
          _buildInfoSection(
            'Religion & Community',
            Icons.temple_hindu_outlined,
            [
              if ((_user?.userProfile?.religion ?? '').isNotEmpty)
                _buildDetailRow('Religion', _user!.userProfile!.religion!),
              if ((_user?.userProfile?.caste ?? '').isNotEmpty)
                _buildDetailRow('Caste', _user!.userProfile!.caste!),
              if ((_user?.userProfile?.subCaste ?? '').isNotEmpty)
                _buildDetailRow('Sub-Caste', _user!.userProfile!.subCaste!),
              if ((_user?.userProfile?.motherTongue ?? '').isNotEmpty)
                _buildDetailRow(
                  'Mother Tongue',
                  _user!.userProfile!.motherTongue!,
                ),
            ],
          ),
          _buildInfoSection('Career & Education', Icons.work_outline, [
            if ((_user?.userProfile?.education ?? '').isNotEmpty)
              _buildDetailRow('Education', _user!.userProfile!.education!),
            if ((_user?.userProfile?.occupation ?? '').isNotEmpty)
              _buildDetailRow('Occupation', _user!.userProfile!.occupation!),
            if (_user?.userProfile?.annualIncome != null)
              _buildDetailRow(
                'Annual Income',
                '₹${_user!.userProfile!.annualIncome}',
              ),
          ]),
          _buildInfoSection('Family Details', Icons.family_restroom_outlined, [
            if (_user?.familyDetails?.fatherOccupation != null)
              _buildDetailRow('Father\'s Occupation', _user!.familyDetails!.fatherOccupation!),
            if (_user?.familyDetails?.motherOccupation != null)
              _buildDetailRow('Mother\'s Occupation', _user!.familyDetails!.motherOccupation!),
            if (_user?.familyDetails?.familyType != null)
              _buildDetailRow('Family Type', _user!.familyDetails!.familyType!),
            if (_user?.familyDetails?.familyStatus != null)
              _buildDetailRow('Family Status', _user!.familyDetails!.familyStatus!),
            if (_user?.familyDetails?.siblings != null)
              _buildDetailRow('Siblings', _user!.familyDetails!.siblings!.toString()),
          ]),
          _buildInfoSection('Location', Icons.location_on_outlined, [
            if ((_user?.userProfile?.city ?? '').isNotEmpty)
              _buildDetailRow('City', _user!.userProfile!.city!),
            if ((_user?.userProfile?.district ?? '').isNotEmpty)
              _buildDetailRow('District', _user!.userProfile!.district!),
          ]),
          _buildInfoSection('Partner Preferences', Icons.favorite_outline_rounded, [
            if (_user?.preferences?.minAge != null || _user?.preferences?.maxAge != null)
              _buildDetailRow('Age Range', '${_user?.preferences?.minAge ?? '-'}-${_user?.preferences?.maxAge ?? '-'} Years'),
            if (_user?.preferences?.minHeight != null || _user?.preferences?.maxHeight != null)
              _buildDetailRow('Height Range', '${_user?.preferences?.minHeight ?? '-'}-${_user?.preferences?.maxHeight ?? '-'} cm'),
            if ((_user?.preferences?.maritalStatus ?? '').isNotEmpty)
              _buildDetailRow('Marital Status', _user!.preferences!.maritalStatus!),
            if ((_user?.preferences?.religionName ?? _user?.preferences?.religion ?? '').isNotEmpty)
              _buildDetailRow('Religion', _user?.preferences?.religionName ?? _user!.preferences!.religion!),
            if (_user?.preferences?.casteNames != null && _user!.preferences!.casteNames!.isNotEmpty)
              _buildDetailRow('Caste', _user!.preferences!.casteNames!.join(', '))
            else if (_user?.preferences?.caste != null && _user!.preferences!.caste!.isNotEmpty)
              _buildDetailRow('Caste', _user!.preferences!.caste!.join(', ')),
            if (_user?.preferences?.subCasteNames != null && _user!.preferences!.subCasteNames!.isNotEmpty)
              _buildDetailRow('Sub-Caste', _user!.preferences!.subCasteNames!.join(', ')),
            if (_user?.preferences?.educationNames != null && _user!.preferences!.educationNames!.isNotEmpty)
              _buildDetailRow('Education', _user!.preferences!.educationNames!.join(', '))
            else if (_user?.preferences?.education != null)
              _buildDetailRow('Education', _user!.preferences!.education!.toString()),
            if (_user?.preferences?.occupationNames != null && _user!.preferences!.occupationNames!.isNotEmpty)
              _buildDetailRow('Occupation', _user!.preferences!.occupationNames!.join(', '))
            else if (_user?.preferences?.occupation != null)
              _buildDetailRow('Occupation', _user!.preferences!.occupation!.toString()),
            if (_user?.preferences?.preferredLocations != null && _user!.preferences!.preferredLocations!.isNotEmpty)
              _buildDetailRow('Locations', _user!.preferences!.preferredLocations!.join(', ')),
            if ((_user?.preferences?.drugAddiction ?? '').isNotEmpty)
              _buildDetailRow('Drug Habits', _user!.preferences!.drugAddiction!),
            if (_user?.preferences?.smoke != null && _user!.preferences!.smoke!.isNotEmpty)
              _buildDetailRow('Smoking', _user!.preferences!.smoke!.join(', ')),
            if (_user?.preferences?.alcohol != null && _user!.preferences!.alcohol!.isNotEmpty)
              _buildDetailRow('Alcohol', _user!.preferences!.alcohol!.join(', ')),
          ]),
          SizedBox(height: 24),
          if (_user?.interests != null && _user!.interests!.isNotEmpty)
            _buildChipsSection('Interests & Hobbies', Icons.auto_awesome_outlined, _user!.interests!, 'interest_name'),
          if (_user?.personalities != null && _user!.personalities!.isNotEmpty)
            _buildChipsSection('Personality Traits', Icons.psychology_outlined, _user!.personalities!, 'personality_name'),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildChipsSection(String title, IconData icon, List<dynamic> items, String nameKey) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildModernCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00BCD4).withOpacity(0.2),
                          const Color(0xFF0D47A1).withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: const Color(0xFF00BCD4), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items.map((item) {
                  final name = item[nameKey] ?? '';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BCD4).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00BCD4).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF00838F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDiscoveryNote() {
    return const SizedBox.shrink();
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    if (children.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildModernCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF00BCD4).withOpacity(0.2),
                          Color(0xFF0D47A1).withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Color(0xFF00BCD4), size: 20),
                  ),
                  SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    // Capitalize the value: replace underscores with spaces and capitalize words
    String formattedValue = value.toLowerCase() == 'never_married'
        ? 'Single'
        : value.replaceAll('_', ' ').split(' ').map((word) {
            if (word.isEmpty) return word;
            return word[0].toUpperCase() + word.substring(1).toLowerCase();
          }).join(' ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              formattedValue,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return _buildModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF00BCD4).withOpacity(0.2),
                      Color(0xFF4CD9A6).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.phone, color: Color(0xFF00BCD4), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (_contactUnlocked) ...[
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Color(0xFF4CD9A6).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_open, color: Color(0xFF4CD9A6), size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Unlocked',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF4CD9A6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 16),
          if (_contactUnlocked) ...[
            // Show View Contact Button when unlocked
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4CD9A6), Color(0xFF00BCD4)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF4CD9A6).withOpacity(0.3),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _showContactDetailsModal,
                icon: Icon(Icons.visibility_outlined, size: 22),
                label: Text(
                  'View Contact Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
          ] else ...[
            // Locked state - show masked phone
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, color: Colors.grey.shade500),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _maskPhone(_user?.phone),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF4CD9A6),
                          Color(0xFF4CD9A6).withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF4CD9A6).withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _checkVerificationAndProceed(_showPaymentOptions),
                      icon: Icon(Icons.account_balance_wallet, size: 18),
                      label: Text(
                        'Wallet',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF00BCD4), Color(0xFF0D47A1)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF00BCD4).withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _checkVerificationAndProceed(() => _unlockWithDirectPayment()),
                      icon: Icon(Icons.payment, size: 18),
                      label: Text(
                        'Pay Now',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildUnlockedContactRow(IconData icon, String label, String value, {Widget? trailing}) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(0xFF4CD9A6).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF4CD9A6).withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF4CD9A6).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Color(0xFF4CD9A6), size: 18),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Future<void> _showContactDetailsModal() async {
    if (_unlockedPhone == null) {
      setState(() => _isLoadingContactDetails = true);
      try {
        final response = await ApiService.makeRequest(
          '${ApiService.baseUrl}/profiles/${widget.userId}/contact-details',
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            _unlockedPhone = data['phone']?.toString();
            _unlockedFatherName = data['father_name']?.toString();
            _unlockedMotherName = data['mother_name']?.toString();
          });
        }
      } catch (e) {
        print('Error fetching contact details: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load contact details')),
        );
        return;
      } finally {
        setState(() => _isLoadingContactDetails = false);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Contact Details',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _isLoadingContactDetails
                  ? Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: Color(0xFF4CD9A6)),
                          SizedBox(height: 16),
                          Text('Fetching secure details...',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        _buildUnlockedContactRow(
                          Icons.person,
                          'Father\'s Name',
                          _unlockedFatherName ?? 'Not provided',
                        ),
                        SizedBox(height: 16),
                        _buildUnlockedContactRow(
                          Icons.person_outline,
                          'Mother\'s Name',
                          _unlockedMotherName ?? 'Not provided',
                        ),
                        SizedBox(height: 16),
                        _buildUnlockedContactRow(
                          Icons.phone_android,
                          'Contact Number',
                          _unlockedPhone ?? 'Not provided',
                          trailing: _unlockedPhone != null
                              ? IconButton(
                                  icon: Icon(Icons.copy,
                                      color: Color(0xFF4CD9A6), size: 20),
                                  onPressed: () {
                                    Clipboard.setData(
                                        ClipboardData(text: _unlockedPhone!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Number copied to clipboard'),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                    );
                                  },
                                )
                              : null,
                        ),
                      ],
                    ),
            ),
            SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFF5F5F5),
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _maskName(String? name) {
    if (name == null || name.isEmpty) return '-';
    if (name.length <= 1) return '*';
    return '${name[0]}${'*' * (name.length - 1)}';
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00BCD4).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Color(0xFF00BCD4),
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Vivah4Ever',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Trusted Kerala Matrimony Services',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFooterSocialIcon(Icons.facebook),
              const SizedBox(width: 20),
              _buildFooterSocialIcon(Icons.camera_alt_outlined),
              const SizedBox(width: 20),
              _buildFooterSocialIcon(Icons.language),
            ],
          ),
          const SizedBox(height: 30),
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            '© 2026 Vivah4Ever. All Rights Reserved.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Made with ❤️ in Kerala',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade400,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSocialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.grey.shade700, size: 20),
    );
  }

  Widget _buildModernCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Future<void> _checkContactUnlock() async {
    try {
      final response = await PaymentService.checkContactUnlock(widget.userId);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _contactUnlocked = data['unlocked'] ?? false;
          });
        }
      }
    } catch (e) {
      print('Error checking contact unlock: $e');
    }
  }

  Future<void> _loadWalletBalance() async {
    try {
      final response = await PaymentService.getWalletBalance();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _walletBalance = double.tryParse(data['balance'].toString()) ?? 0.0;
          });
        }
      }
    } catch (e) {
      print('Error loading wallet: $e');
    }
  }

  Future<void> _loadTodayUnlockCount() async {
    try {
      final response = await PaymentService.getTodayUnlockCount();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _todayUnlockCount = data['count'] ?? 0;
          });
        }
      }
    } catch (e) {
      print('Error loading today unlock count: $e');
    }
  }

  String _maskPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '••••••••••';
    if (phone.length < 4) return phone;
    final start = phone.substring(0, phone.length >= 6 ? 3 : 2);
    final end = phone.substring(phone.length - 2);
    return '$start••••••$end';
  }

  void _checkVerificationAndProceed(VoidCallback onSuccess) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isVerified = authProvider.user?.verification?.status == 'verified';

    // Check if user has exceeded daily limit
    if (_todayUnlockCount >= _dailyUnlockLimit) {
      // User has exceeded daily limit, check verification
      if (isVerified) {
        onSuccess();
      } else {
        _showVerificationDialog();
      }
    } else {
      // User is within daily limit, allow without verification
      onSuccess();
    }
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.verified_user_outlined, color: Colors.orange),
            SizedBox(width: 8),
            Text('Verification Required'),
          ],
        ),
        content: Text(
          'You have exceeded your daily limit of $_dailyUnlockLimit contact unlock${_dailyUnlockLimit > 1 ? 's' : ''}. Please verify your account to unlock more contacts.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VerificationScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00BCD4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Verify Now'),
          ),
        ],
      ),
    );
  }

  void _showPaymentOptions() {
    if (_walletBalance >= 49) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.help_outline_rounded, color: Color(0xFF00BCD4)),
              SizedBox(width: 8),
              Text('Confirm Unlock'),
            ],
          ),
          content: Text(
            'Are you sure you want to unlock this contact? ₹49 will be deducted from your wallet.',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _unlockWithWallet();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CD9A6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Confirm & Unlock'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Insufficient Balance'),
            ],
          ),
          content: Text(
            'Your wallet balance is ₹${_walletBalance.toStringAsFixed(0)}. Would you like to recharge your wallet?',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _rechargeWallet();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00BCD4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Recharge'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _unlockWithWallet() async {
    try {
      final response = await PaymentService.unlockContactWithWallet(
        widget.userId,
      );
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _contactUnlocked = true;
          });
        }
        _loadWalletBalance();
        _loadTodayUnlockCount(); // Refresh count after unlock
        _loadUserProfile();      // Reload to get fresh contact_info from API
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Contact unlocked successfully!'),
              ],
            ),
            backgroundColor: Color(0xFF4CD9A6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to unlock contact')));
    }
  }

  Future<void> _unlockWithDirectPayment() async {
    try {
      final response = await PaymentService.createOrder(
        amount: 49,
        type: 'contact_unlock',
        unlockedUserId: widget.userId,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _openRazorpay(data);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create payment order')));
    }
  }

  Future<void> _rechargeWallet() async {
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Recharge Wallet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRechargeOption(100.0, context),
            _buildRechargeOption(500.0, context),
            _buildRechargeOption(1000.0, context),
            _buildRechargeOption(2000.0, context),
          ],
        ),
      ),
    );

    if (amount != null) {
      try {
        final response = await PaymentService.createOrder(
          amount: amount,
          type: 'wallet_recharge',
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _openRazorpay(data);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create recharge order')),
        );
      }
    }
  }

  Widget _buildRechargeOption(double amount, BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF00BCD4).withOpacity(0.1),
            Color(0xFF0D47A1).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF00BCD4).withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Icon(Icons.account_balance_wallet, color: Color(0xFF00BCD4)),
        title: Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Color(0xFF00BCD4),
        ),
        onTap: () => Navigator.pop(context, amount),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openRazorpay(Map<String, dynamic> orderData) {
    setState(() {
      _currentTransactionId = orderData['transaction_id'];
    });

    final options = {
      'key': orderData['key'],
      'amount': (orderData['amount'] * 100).toInt(),
      'currency': 'INR',
      'name': 'Matrimony App',
      'description': 'Payment',
      'order_id': orderData['order_id'],
      'prefill': {'contact': _user?.phone ?? '', 'email': _user?.email ?? ''},
      'theme': {'color': '#00BCD4'},
    };

    _razorpay.open(options);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final razorpayOrderId = response.orderId;
      final razorpayPaymentId = response.paymentId;
      final razorpaySignature = response.signature;

      if (razorpayOrderId == null || razorpayPaymentId == null || razorpaySignature == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid payment response')),
        );
        return;
      }

      final verifyResponse = await PaymentService.verifyPayment(
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
        transactionId: _currentTransactionId ?? 0,
        unlockedUserId: widget.userId,
      );

      if (verifyResponse.statusCode == 200) {
        final data = json.decode(verifyResponse.body);
        final String type = data['type'] ?? '';

        if (type == 'contact_unlock') {
          if (mounted) {
            setState(() {
              _contactUnlocked = true;
            });
          }
          _loadUserProfile();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Contact unlocked successfully!'),
                ],
              ),
              backgroundColor: Color(0xFF4CD9A6),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Wallet recharged successfully!'),
                ],
              ),
              backgroundColor: Color(0xFF4CD9A6),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        _loadWalletBalance();
      }
    } catch (e) {
      print('Verification error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Payment verification failed')));
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message}'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet selected: ${response.walletName}'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    _animationController.dispose();
    super.dispose();
  }
}