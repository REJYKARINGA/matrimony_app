import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/matching_service.dart';
import '../utils/date_formatter.dart';
import 'messages_screen.dart';

class ViewProfileScreen extends StatefulWidget {
  final int userId;

  const ViewProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  User? _user;
  bool _isLoading = true;
  String? _errorMessage;
  dynamic _interestSent;
  dynamic _interestReceived;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
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
          const SnackBar(
            content: Text('Interest accepted! You are now matched.'),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Interest sent!')));
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
    final size = MediaQuery.of(context).size;

    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
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
          child: SafeArea(
            child: Column(
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'User Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
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
                // App bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'User Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadUserProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFB47FFF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Retry'),
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
            colors: [
              Color(0xFFB47FFF), // Purple
              Color(0xFF5CB3FF), // Blue
              Color(0xFF4CD9A6), // Green
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'User Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Profile Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile picture section with gradient border
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFB47FFF),
                                    Color(0xFF5CB3FF),
                                  ],
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 56,
                              child: ClipOval(
                                child: _user?.userProfile?.profilePicture != null
                                    ? Image.network(
                                        ApiService.getImageUrl(_user!.userProfile!.profilePicture!),
                                        width: 112,
                                        height: 112,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          color: Colors.grey.shade100,
                                          child: Icon(Icons.person, size: 60, color: Colors.grey.shade400),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.grey.shade100,
                                        width: 112,
                                        height: 112,
                                        child: Icon(Icons.person, size: 60, color: Colors.grey.shade400),
                                      ),
                              ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Name
                          Center(
                            child: Text(
                              '${_user?.userProfile?.firstName ?? ''} ${_user?.userProfile?.lastName ?? ''}',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Personal Information
                          _buildSectionHeader('Personal Information'),
                          const SizedBox(height: 12),
                          _buildInfoCard([
                            if (_user?.userProfile?.dateOfBirth != null)
                              _buildInfoRow(
                                'Date of Birth',
                                DateFormatter.formatDate(
                                  _user!.userProfile!.dateOfBirth!,
                                ),
                              ),
                            if ((_user?.userProfile?.gender ?? '').isNotEmpty)
                              _buildInfoRow(
                                'Gender',
                                _user!.userProfile!.gender!,
                              ),
                            if (_user?.userProfile?.height != null)
                              _buildInfoRow(
                                'Height',
                                '${_user!.userProfile!.height} cm',
                              ),
                            if (_user?.userProfile?.weight != null)
                              _buildInfoRow(
                                'Weight',
                                '${_user!.userProfile!.weight} kg',
                              ),
                            if ((_user?.userProfile?.maritalStatus ?? '')
                                .isNotEmpty)
                              _buildInfoRow(
                                'Marital Status',
                                _user!.userProfile!.maritalStatus!,
                              ),
                          ]),

                          const SizedBox(height: 24),

                          // Religion & Community
                          _buildSectionHeader('Religion & Community'),
                          const SizedBox(height: 12),
                          _buildInfoCard([
                            if ((_user?.userProfile?.religion ?? '').isNotEmpty)
                              _buildInfoRow(
                                'Religion',
                                _user!.userProfile!.religion!,
                              ),
                            if ((_user?.userProfile?.caste ?? '').isNotEmpty)
                              _buildInfoRow(
                                'Caste',
                                _user!.userProfile!.caste!,
                              ),
                            if ((_user?.userProfile?.subCaste ?? '').isNotEmpty)
                              _buildInfoRow(
                                'Sub-Caste',
                                _user!.userProfile!.subCaste!,
                              ),
                            if ((_user?.userProfile?.motherTongue ?? '')
                                .isNotEmpty)
                              _buildInfoRow(
                                'Mother Tongue',
                                _user!.userProfile!.motherTongue!,
                              ),
                          ]),

                          const SizedBox(height: 24),

                          // Education & Career
                          _buildSectionHeader('Education & Career'),
                          const SizedBox(height: 12),
                          _buildInfoCard([
                            if ((_user?.userProfile?.education ?? '')
                                .isNotEmpty)
                              _buildInfoRow(
                                'Education',
                                _user!.userProfile!.education!,
                              ),
                            if ((_user?.userProfile?.occupation ?? '')
                                .isNotEmpty)
                              _buildInfoRow(
                                'Occupation',
                                _user!.userProfile!.occupation!,
                              ),
                            if (_user?.userProfile?.annualIncome != null)
                              _buildInfoRow(
                                'Annual Income',
                                '₹${_user!.userProfile!.annualIncome}',
                              ),
                          ]),

                          const SizedBox(height: 24),

                          // Location
                          _buildSectionHeader('Location'),
                          const SizedBox(height: 12),
                          _buildInfoCard([
                            if ((_user?.userProfile?.city ?? '').isNotEmpty)
                              _buildInfoRow('City', _user!.userProfile!.city!),
                            if ((_user?.userProfile?.district ?? '').isNotEmpty)
                              _buildInfoRow(
                                'District',
                                _user!.userProfile!.district!,
                              ),
                            if ((_user?.userProfile?.state ?? '').isNotEmpty)
                              _buildInfoRow(
                                'State',
                                _user!.userProfile!.state!,
                              ),
                            if ((_user?.userProfile?.country ?? '').isNotEmpty)
                              _buildInfoRow(
                                'Country',
                                _user!.userProfile!.country!,
                              ),
                          ]),

                          const SizedBox(height: 24),

                          // Bio
                          if ((_user?.userProfile?.bio ?? '').isNotEmpty) ...[
                            _buildSectionHeader('About Me'),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Text(
                                _user?.userProfile?.bio ?? '',
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          const SizedBox(height: 10),

                          // Action buttons with gradient
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 54,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFB47FFF),
                                        Color(0xFF5CB3FF),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: _isActionLoading
                                        ? null
                                        : ((_interestReceived != null && _interestReceived['status'] == 'accepted') ||
                                           (_interestSent != null && _interestSent['status'] == 'accepted')
                                            ? null
                                            : (_interestReceived != null && _interestReceived['status'] == 'pending'
                                                ? _handleAcceptInterest
                                                : (_interestSent != null
                                                    ? null
                                                    : _handleSendInterest))),
                                    icon: _isActionLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            (_interestReceived != null && _interestReceived['status'] == 'accepted') ||
                                            (_interestSent != null && _interestSent['status'] == 'accepted')
                                                ? Icons.favorite
                                                : (_interestReceived != null && _interestReceived['status'] == 'pending'
                                                    ? Icons.check_circle
                                                    : (_interestSent != null
                                                        ? Icons.favorite
                                                        : Icons.favorite_border)),
                                            size: 20,
                                          ),
                                    label: Text(
                                      _isActionLoading
                                          ? 'Processing...'
                                          : ((_interestReceived != null && _interestReceived['status'] == 'accepted') ||
                                             (_interestSent != null && _interestSent['status'] == 'accepted')
                                              ? 'Matched'
                                              : (_interestReceived != null && _interestReceived['status'] == 'pending'
                                                  ? 'Accept Interest'
                                                  : (_interestSent != null
                                                      ? (_interestSent['status'] == 'accepted'
                                                          ? 'Matched'
                                                          : 'Interest Sent')
                                                      : 'Send Interest'))),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  height: 54,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Color(0xFFB47FFF),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      bool isMatched = false;
                                      if (_interestSent != null &&
                                          _interestSent['status'] == 'accepted')
                                        isMatched = true;
                                      if (_interestReceived != null &&
                                          _interestReceived['status'] ==
                                              'accepted')
                                        isMatched = true;

                                      if (isMatched && _user != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChatScreen(
                                              otherUserId: _user!.id!,
                                              otherUserName:
                                                  '${_user!.userProfile?.firstName} ${_user!.userProfile?.lastName}',
                                              otherUserImage:
                                                  _user!
                                                          .userProfile
                                                          ?.profilePicture !=
                                                      null
                                                  ? ApiService.getImageUrl(
                                                      _user!
                                                          .userProfile!
                                                          .profilePicture!,
                                                    )
                                                  : null,
                                            ),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'You can only message matched users!',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    icon: Icon(
                                      Icons.message,
                                      size: 20,
                                      color: Color(0xFFB47FFF),
                                    ),
                                    label: Text(
                                      'Message',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFB47FFF),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
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

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFB47FFF), Color(0xFF5CB3FF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
