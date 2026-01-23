import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../utils/date_formatter.dart';

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('User Profile'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('User Profile'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile picture section
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _user?.userProfile?.profilePicture != null
                      ? NetworkImage(ApiService.getImageUrl(_user!.userProfile!.profilePicture!))
                      : null,
                  child: _user?.userProfile?.profilePicture == null
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              
              // Name
              Center(
                child: Text(
                  '${_user?.userProfile?.firstName ?? ''} ${_user?.userProfile?.lastName ?? ''}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              
              // Personal Information
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              _user?.userProfile?.dateOfBirth != null
                  ? _buildInfoRow('Date of Birth', DateFormatter.formatDate(_user!.userProfile!.dateOfBirth!))
                  : const SizedBox.shrink(),
              _buildInfoRow('Gender', _user?.userProfile?.gender ?? ''),
              _buildInfoRow('Height', _user?.userProfile?.height != null ? '${_user!.userProfile!.height} cm' : ''),
              _buildInfoRow('Weight', _user?.userProfile?.weight != null ? '${_user!.userProfile!.weight} kg' : ''),
              _buildInfoRow('Marital Status', _user?.userProfile?.maritalStatus ?? ''),
              
              const SizedBox(height: 20),
              
              // Religion & Community
              const Text(
                'Religion & Community',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              _buildInfoRow('Religion', _user?.userProfile?.religion ?? ''),
              _buildInfoRow('Caste', _user?.userProfile?.caste ?? ''),
              _buildInfoRow('Sub-Caste', _user?.userProfile?.subCaste ?? ''),
              _buildInfoRow('Mother Tongue', _user?.userProfile?.motherTongue ?? ''),
              
              const SizedBox(height: 20),
              
              // Education & Career
              const Text(
                'Education & Career',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              _buildInfoRow('Education', _user?.userProfile?.education ?? ''),
              _buildInfoRow('Occupation', _user?.userProfile?.occupation ?? ''),
              _buildInfoRow('Annual Income', _user?.userProfile?.annualIncome != null ? '₹${_user!.userProfile!.annualIncome}' : ''),
              
              const SizedBox(height: 20),
              
              // Location
              const Text(
                'Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              _buildInfoRow('City', _user?.userProfile?.city ?? ''),
              _user?.userProfile?.district != null
                  ? _buildInfoRow('District', _user!.userProfile!.district!)
                  : const SizedBox.shrink(),
              _buildInfoRow('State', _user?.userProfile?.state ?? ''),
              _buildInfoRow('Country', _user?.userProfile?.country ?? ''),
              
              const SizedBox(height: 20),
              
              // Bio
              if ((_user?.userProfile?.bio ?? '').isNotEmpty) ...[
                const Text(
                  'About Me',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                Text(
                  _user?.userProfile?.bio ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
              
              const SizedBox(height: 30),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement sending interest
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Interest sent!')),
                        );
                      },
                      icon: const Icon(Icons.favorite),
                      label: const Text('Send Interest'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implement messaging
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Messaging feature coming soon!')),
                        );
                      },
                      icon: const Icon(Icons.message),
                      label: const Text('Message'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}