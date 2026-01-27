import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/matching_service.dart';
import '../services/payment_service.dart';
import '../utils/date_formatter.dart';
import 'messages_screen.dart';
import 'dart:js' as js;
import 'dart:html' as html;

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
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

    _loadUserProfile();
    _checkContactUnlock();
    _loadWalletBalance();
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
        setState(() {
          _user = user;
          _interestSent = data['interest_sent'];
          _interestReceived = data['interest_received'];
          _isLoading = false;
        });
        _animationController.forward();
      } else {
        setState(() {
          _errorMessage = 'Failed to load profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
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
        setState(() {
          _isActionLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to accept interest')),
        );
      }
    } catch (e) {
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
        setState(() {
          _interestSent = data['interest'];
          _isActionLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Interest sent!'),
            backgroundColor: Color(0xFF5CB3FF),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        setState(() {
          _isActionLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send interest')),
        );
      }
    } catch (e) {
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
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFB47FFF), Color(0xFF5CB3FF), Color(0xFF4CD9A6)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFB47FFF), Color(0xFF5CB3FF), Color(0xFF4CD9A6)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
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
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
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
                              backgroundColor: Color(0xFFB47FFF),
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
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB47FFF), Color(0xFF5CB3FF), Color(0xFF4CD9A6)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: SingleChildScrollView(
                        physics: BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            _buildProfileHeader(),
                            _buildActionButtons(),
                            _buildProfileDetails(),
                            SizedBox(height: 20),
                          ],
                        ),
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(height: 10),
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFB47FFF),
                      Color(0xFF5CB3FF),
                      Color(0xFF4CD9A6),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFB47FFF).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: ClipOval(
                    child: _user?.userProfile?.profilePicture != null
                        ? Image.network(
                            ApiService.getImageUrl(
                              _user!.userProfile!.profilePicture!,
                            ),
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFB47FFF).withOpacity(0.2),
                                        Color(0xFF5CB3FF).withOpacity(0.2),
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    size: 70,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                          )
                        : Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFB47FFF).withOpacity(0.2),
                                  Color(0xFF5CB3FF).withOpacity(0.2),
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.person,
                              size: 70,
                              color: Colors.grey.shade400,
                            ),
                          ),
                  ),
                ),
              ),
              if ((_interestReceived != null &&
                      _interestReceived['status'] == 'accepted') ||
                  (_interestSent != null &&
                      _interestSent['status'] == 'accepted'))
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF4CD9A6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF4CD9A6).withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(Icons.favorite, color: Colors.white, size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '${_user?.userProfile?.firstName ?? ''} ${_user?.userProfile?.lastName ?? ''}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_user?.userProfile?.age != null) ...[
                _buildQuickInfo(
                  Icons.cake_outlined,
                  '${_user!.userProfile!.age} years',
                ),
                SizedBox(width: 20),
              ],
              if ((_user?.userProfile?.city ?? '').isNotEmpty)
                _buildQuickInfo(
                  Icons.location_on_outlined,
                  _user!.userProfile!.city!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfo(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFFB47FFF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Color(0xFFB47FFF)),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFB47FFF),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildInterestButton()),
          const SizedBox(width: 12),
          Expanded(child: _buildMessageButton()),
        ],
      ),
    );
  }

  Widget _buildInterestButton() {
    bool isMatched =
        (_interestReceived != null &&
            _interestReceived['status'] == 'accepted') ||
        (_interestSent != null && _interestSent['status'] == 'accepted');
    bool isPending =
        _interestReceived != null && _interestReceived['status'] == 'pending';
    bool isSent = _interestSent != null && !isMatched;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMatched
              ? [Color(0xFF4CD9A6), Color(0xFF4CD9A6)]
              : [Color(0xFFB47FFF), Color(0xFF5CB3FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isMatched ? Color(0xFF4CD9A6) : Color(0xFFB47FFF))
                .withOpacity(0.4),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isActionLoading
            ? null
            : (isMatched
                  ? null
                  : (isPending
                        ? _handleAcceptInterest
                        : (isSent ? null : _handleSendInterest))),
        icon: _isActionLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                isMatched
                    ? Icons.favorite
                    : (isPending
                          ? Icons.check_circle
                          : (isSent ? Icons.favorite : Icons.favorite_border)),
                size: 22,
              ),
        label: Text(
          _isActionLoading
              ? 'Processing...'
              : (isMatched
                    ? 'Matched'
                    : (isPending
                          ? 'Accept'
                          : (isSent ? 'Sent' : 'Send Interest'))),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildMessageButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFB47FFF), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          bool isMatched =
              (_interestSent != null &&
                  _interestSent['status'] == 'accepted') ||
              (_interestReceived != null &&
                  _interestReceived['status'] == 'accepted');

          if (isMatched && _user != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  otherUserId: _user!.id!,
                  otherUserName:
                      '${_user!.userProfile?.firstName} ${_user!.userProfile?.lastName}',
                  otherUserImage: _user!.userProfile?.profilePicture != null
                      ? ApiService.getImageUrl(
                          _user!.userProfile!.profilePicture!,
                        )
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
        child: Icon(Icons.message_rounded, color: Color(0xFFB47FFF)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
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
                        color: Color(0xFFB47FFF),
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
            if (_user?.userProfile?.dateOfBirth != null)
              _buildDetailRow(
                'Date of Birth',
                DateFormatter.formatDate(_user?.userProfile?.dateOfBirth),
              ),
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
          _buildInfoSection('Location', Icons.location_on_outlined, [
            if ((_user?.userProfile?.city ?? '').isNotEmpty)
              _buildDetailRow('City', _user!.userProfile!.city!),
            if ((_user?.userProfile?.district ?? '').isNotEmpty)
              _buildDetailRow('District', _user!.userProfile!.district!),
            if ((_user?.userProfile?.state ?? '').isNotEmpty)
              _buildDetailRow('State', _user!.userProfile!.state!),
            if ((_user?.userProfile?.country ?? '').isNotEmpty)
              _buildDetailRow('Country', _user!.userProfile!.country!),
          ]),
          _buildContactSection(),
        ],
      ),
    );
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
                          Color(0xFFB47FFF).withOpacity(0.2),
                          Color(0xFF5CB3FF).withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Color(0xFFB47FFF), size: 20),
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
              value,
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
                      Color(0xFF5CB3FF).withOpacity(0.2),
                      Color(0xFF4CD9A6).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.phone, color: Color(0xFF5CB3FF), size: 20),
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
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _contactUnlocked
                  ? Color(0xFF4CD9A6).withOpacity(0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _contactUnlocked
                    ? Color(0xFF4CD9A6).withOpacity(0.3)
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _contactUnlocked ? Icons.lock_open : Icons.lock,
                  color: _contactUnlocked
                      ? Color(0xFF4CD9A6)
                      : Colors.grey.shade500,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _contactUnlocked
                        ? (_user?.phone ?? 'Not provided')
                        : _maskPhone(_user?.phone),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _contactUnlocked
                          ? Colors.black87
                          : Colors.grey.shade600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!_contactUnlocked) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Unlock contact details for ₹49',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                      onPressed: () => _showPaymentOptions(),
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
                        colors: [Color(0xFF5CB3FF), Color(0xFFB47FFF)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF5CB3FF).withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _unlockWithDirectPayment(),
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
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _walletBalance < 49
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 14,
                      color: _walletBalance < 49 ? Colors.red : Colors.green,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Balance: ₹${_walletBalance.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _walletBalance < 49
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
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
        setState(() {
          _contactUnlocked = data['unlocked'] ?? false;
        });
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
        setState(() {
          _walletBalance = double.tryParse(data['balance'].toString()) ?? 0.0;
        });
      }
    } catch (e) {
      print('Error loading wallet: $e');
    }
  }

  String _maskPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '••••••••••';
    if (phone.length < 4) return phone;
    final start = phone.substring(0, phone.length >= 6 ? 3 : 2);
    final end = phone.substring(phone.length - 2);
    return '$start••••••$end';
  }

  void _showPaymentOptions() {
    if (_walletBalance >= 49) {
      _unlockWithWallet();
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
                backgroundColor: Color(0xFFB47FFF),
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
        setState(() {
          _contactUnlocked = true;
        });
        _loadWalletBalance();
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
            Color(0xFFB47FFF).withOpacity(0.1),
            Color(0xFF5CB3FF).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFB47FFF).withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Icon(Icons.account_balance_wallet, color: Color(0xFFB47FFF)),
        title: Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Color(0xFFB47FFF),
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

    final script = html.ScriptElement()
      ..src = 'https://checkout.razorpay.com/v1/checkout.js'
      ..async = true;
    html.document.head?.append(script);

    script.onLoad.listen((event) {
      final options = js.JsObject.jsify({
        'key': orderData['key'],
        'amount': (orderData['amount'] * 100).toInt(),
        'currency': 'INR',
        'name': 'Matrimony App',
        'description': 'Payment',
        'order_id': orderData['order_id'],
        'handler': js.allowInterop((response) {
          _handleWebPaymentSuccess(response);
        }),
        'modal': {
          'ondismiss': js.allowInterop(() {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment cancelled'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }),
        },
        'prefill': {'contact': _user?.phone ?? '', 'email': _user?.email ?? ''},
        'theme': {'color': '#5CB3FF'},
      });

      final razorpay = js.JsObject(js.context['Razorpay'], [options]);
      razorpay.callMethod('open');
    });
  }

  void _handleWebPaymentSuccess(dynamic response) async {
    try {
      final razorpayOrderId = js.JsObject.fromBrowserObject(
        response,
      )['razorpay_order_id'];
      final razorpayPaymentId = js.JsObject.fromBrowserObject(
        response,
      )['razorpay_payment_id'];
      final razorpaySignature = js.JsObject.fromBrowserObject(
        response,
      )['razorpay_signature'];

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
          setState(() {
            _contactUnlocked = true;
          });
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
