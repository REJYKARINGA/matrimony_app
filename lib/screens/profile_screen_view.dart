import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/location_service.dart';
import '../services/profile_service.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/date_formatter.dart';
import 'family_details_screen.dart';
import 'preferences_screen.dart';
import 'profile_photos_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ProfileService.getMyProfile();
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
    final size = MediaQuery.of(context).size;

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
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
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
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(fontSize: 16, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFFB47FFF),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Gradient header section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFB47FFF),
                    Color(0xFF5CB3FF),
                    Color(0xFF4CD9A6),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: Column(
                children: [
                  // App bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'My Profile',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditProfileScreen(user: _user),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Profile picture section
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30.0, top: 10.0),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.white,
                                backgroundImage:
                                    _user?.userProfile?.profilePicture != null
                                    ? NetworkImage(
                                        ApiService.getImageUrl(_user!.userProfile!.profilePicture!),
                                      )
                                    : null,
                                child:
                                    _user?.userProfile?.profilePicture == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Color(0xFFB47FFF),
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                height: 36,
                                width: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: Color(0xFFB47FFF),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${_user?.userProfile?.firstName ?? ''} ${_user?.userProfile?.lastName ?? ''}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (_user?.email != null)
                          Text(
                            _user!.email!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content section
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Information
                      _buildSectionTitle('Personal Information'),
                      const SizedBox(height: 12),
                      _buildInfoCard([
                        if (_user?.userProfile?.dateOfBirth != null)
                          _buildInfoRow(
                            Icons.cake,
                            'Date of Birth',
                            DateFormatter.formatDate(
                              _user!.userProfile!.dateOfBirth!,
                            ),
                          ),
                        _buildInfoRow(
                          Icons.person_outline,
                          'Gender',
                          _user?.userProfile?.gender ?? '',
                        ),
                        _buildInfoRow(
                          Icons.height,
                          'Height',
                          _user?.userProfile?.height != null
                              ? '${_user!.userProfile!.height} cm'
                              : '',
                        ),
                        _buildInfoRow(
                          Icons.monitor_weight_outlined,
                          'Weight',
                          _user?.userProfile?.weight != null
                              ? '${_user!.userProfile!.weight} kg'
                              : '',
                        ),
                        _buildInfoRow(
                          Icons.favorite_outline,
                          'Marital Status',
                          _user?.userProfile?.maritalStatus ?? '',
                        ),
                      ]),

                      const SizedBox(height: 20),

                      // Contact Information
                      _buildSectionTitle('Contact Information'),
                      const SizedBox(height: 12),
                      _buildInfoCard([
                        _buildInfoRow(
                          Icons.email_outlined,
                          'Email',
                          _user?.email ?? '',
                        ),
                        _buildInfoRow(
                          Icons.phone_outlined,
                          'Phone',
                          _user?.phone ?? '',
                        ),
                      ]),

                      const SizedBox(height: 20),

                      // Religion & Community
                      _buildSectionTitle('Religion & Community'),
                      const SizedBox(height: 12),
                      _buildInfoCard([
                        _buildInfoRow(
                          Icons.temple_hindu,
                          'Religion',
                          _user?.userProfile?.religion ?? '',
                        ),
                        _buildInfoRow(
                          Icons.groups_outlined,
                          'Caste',
                          _user?.userProfile?.caste ?? '',
                        ),
                        _buildInfoRow(
                          Icons.group_outlined,
                          'Sub-Caste',
                          _user?.userProfile?.subCaste ?? '',
                        ),
                        _buildInfoRow(
                          Icons.language,
                          'Mother Tongue',
                          _user?.userProfile?.motherTongue ?? '',
                        ),
                      ]),

                      const SizedBox(height: 20),

                      // Education & Career
                      _buildSectionTitle('Education & Career'),
                      const SizedBox(height: 12),
                      _buildInfoCard([
                        _buildInfoRow(
                          Icons.school_outlined,
                          'Education',
                          _user?.userProfile?.education ?? '',
                        ),
                        _buildInfoRow(
                          Icons.work_outline,
                          'Occupation',
                          _user?.userProfile?.occupation ?? '',
                        ),
                        _buildInfoRow(
                          Icons.currency_rupee,
                          'Annual Income',
                          _user?.userProfile?.annualIncome != null
                              ? '₹${_user!.userProfile!.annualIncome}'
                              : '',
                        ),
                      ]),

                      const SizedBox(height: 20),

                      // Location
                      _buildSectionTitle('Location'),
                      const SizedBox(height: 12),
                      _buildInfoCard([
                        _buildInfoRow(
                          Icons.location_city,
                          'City',
                          _user?.userProfile?.city ?? '',
                        ),
                        if (_user?.userProfile?.district != null)
                          _buildInfoRow(
                            Icons.map_outlined,
                            'District',
                            _user!.userProfile!.district!,
                          ),
                        _buildInfoRow(
                          Icons.map,
                          'State',
                          _user?.userProfile?.state ?? '',
                        ),
                        _buildInfoRow(
                          Icons.public,
                          'Country',
                          _user?.userProfile?.country ?? '',
                        ),
                      ]),

                      // Bio
                      if ((_user?.userProfile?.bio ?? '').isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildSectionTitle('About Me'),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
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
                      ],

                      const SizedBox(height: 24),

                      // Action Buttons
                      _buildActionButton(
                        icon: Icons.family_restroom,
                        label: 'Family Details',
                        color: Color(0xFFB47FFF),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FamilyDetailsScreen(),
                            ),
                          );
                          if (result == true) {
                            _loadProfile();
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      _buildActionButton(
                        icon: Icons.settings,
                        label: 'Edit Preferences',
                        color: Color(0xFF5CB3FF),
                        onPressed: () {
                          Navigator.pushNamed(context, '/preferences');
                        },
                      ),

                      const SizedBox(height: 12),

                      _buildActionButton(
                        icon: Icons.photo_camera,
                        label: 'Manage Photos',
                        color: Color(0xFF4CD9A6),
                        onPressed: () {
                          Navigator.pushNamed(context, '/profile-photos');
                        },
                      ),

                      const SizedBox(height: 20),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFB47FFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Color(0xFFB47FFF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
    );
  }
}

// EditProfileScreen remains the same as in your original code
class EditProfileScreen extends StatefulWidget {
  final User? user;

  const EditProfileScreen({Key? key, this.user}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _dateOfBirthController;
  late String? _selectedGender;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late String? _selectedMaritalStatus;
  late TextEditingController _religionController;
  late TextEditingController _casteController;
  late TextEditingController _subCasteController;
  late TextEditingController _motherTongueController;
  late TextEditingController _educationController;
  late TextEditingController _occupationController;
  late TextEditingController _annualIncomeController;
  late TextEditingController _cityController;
  String? _selectedDistrict;
  late TextEditingController _stateController;
  late TextEditingController _countryController;
  late TextEditingController _countyController;
  late TextEditingController _postalCodeController;
  late TextEditingController _bioController;
  bool _isLoading = false;

  final List<String> _keralaDistricts = [
    'Thiruvananthapuram',
    'Kollam',
    'Pathanamthitta',
    'Alappuzha',
    'Kottayam',
    'Idukki',
    'Ernakulam',
    'Thrissur',
    'Palakkad',
    'Malappuram',
    'Kozhikode',
    'Wayanad',
    'Kannur',
    'Kasaragod',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController(
      text: widget.user?.userProfile?.firstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.user?.userProfile?.lastName ?? '',
    );
    _dateOfBirthController = TextEditingController(
      text: widget.user?.userProfile?.dateOfBirth != null
          ? DateFormatter.formatDate(widget.user!.userProfile!.dateOfBirth!)
          : '',
    );
    _selectedGender = widget.user?.userProfile?.gender;
    _heightController = TextEditingController(
      text: widget.user?.userProfile?.height?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: widget.user?.userProfile?.weight?.toString() ?? '',
    );
    _selectedMaritalStatus = widget.user?.userProfile?.maritalStatus;
    _religionController = TextEditingController(
      text: widget.user?.userProfile?.religion ?? '',
    );
    _casteController = TextEditingController(
      text: widget.user?.userProfile?.caste ?? '',
    );
    _subCasteController = TextEditingController(
      text: widget.user?.userProfile?.subCaste ?? '',
    );
    _motherTongueController = TextEditingController(
      text: widget.user?.userProfile?.motherTongue ?? '',
    );
    _educationController = TextEditingController(
      text: widget.user?.userProfile?.education ?? '',
    );
    _occupationController = TextEditingController(
      text: widget.user?.userProfile?.occupation ?? '',
    );
    _annualIncomeController = TextEditingController(
      text: widget.user?.userProfile?.annualIncome?.toString() ?? '',
    );
    _cityController = TextEditingController(
      text: widget.user?.userProfile?.city ?? '',
    );
    _selectedDistrict = widget.user?.userProfile?.district;
    _stateController = TextEditingController(
      text: widget.user?.userProfile?.state ?? '',
    );
    _countryController = TextEditingController(
      text: widget.user?.userProfile?.country ?? '',
    );
    _countyController = TextEditingController(
      text: widget.user?.userProfile?.county ?? '',
    );
    _postalCodeController = TextEditingController(
      text: widget.user?.userProfile?.postalCode ?? '',
    );
    _bioController = TextEditingController(
      text: widget.user?.userProfile?.bio ?? '',
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ProfileService.updateMyProfile(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        dateOfBirth: DateFormatter.parseDate(_dateOfBirthController.text),
        gender: _selectedGender,
        height: int.tryParse(_heightController.text),
        weight: int.tryParse(_weightController.text),
        maritalStatus: _selectedMaritalStatus,
        religion: _religionController.text,
        caste: _casteController.text,
        subCaste: _subCasteController.text,
        motherTongue: _motherTongueController.text,
        education: _educationController.text,
        occupation: _occupationController.text,
        annualIncome: double.tryParse(_annualIncomeController.text),
        city: _cityController.text,
        district: _selectedDistrict,
        county: _countyController.text,
        state: _stateController.text,
        country: _countryController.text,
        postalCode: _postalCodeController.text,
        bio: _bioController.text,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      } else {
        final data = json.decode(response.body);
        String message = data['error'] ?? 'Failed to update profile';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerCityLookup() async {
    if (_cityController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final data = await LocationService.searchAddressByCity(_cityController.text);
      if (data != null) {
        setState(() {
          _cityController.text = data['city'] ?? _cityController.text;
          _stateController.text = data['state'] ?? '';
          _countryController.text = data['country'] ?? '';
          _countyController.text = data['county'] ?? '';
          _postalCodeController.text = data['postal_code'] ?? '';

          String? detDistrict = data['district'];
          if (detDistrict != null) {
            detDistrict = detDistrict.replaceAll(' District', '').trim();
            try {
              _selectedDistrict = _keralaDistricts.firstWhere(
                (d) => d.toLowerCase() == detDistrict!.toLowerCase(),
                orElse: () => _selectedDistrict ?? _keralaDistricts.first,
              );
            } catch (_) {}
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location details auto-filled!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find location details.')),
        );
      }
    } catch (e) {
      print('Lookup error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Color(0xFFB47FFF),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personal Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _dateOfBirthController,
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _dateOfBirthController.text.isNotEmpty
                          ? DateFormatter.parseDate(
                                  _dateOfBirthController.text,
                                ) ??
                                DateTime.now()
                          : DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _dateOfBirthController.text = DateFormatter.formatDate(
                          pickedDate,
                        );
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Height (cm)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedMaritalStatus,
                  decoration: const InputDecoration(
                    labelText: 'Marital Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'never_married',
                      child: Text('Never Married'),
                    ),
                    DropdownMenuItem(
                      value: 'divorced',
                      child: Text('Divorced'),
                    ),
                    DropdownMenuItem(value: 'widowed', child: Text('Widowed')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedMaritalStatus = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Religion & Community',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _religionController,
                  decoration: const InputDecoration(
                    labelText: 'Religion',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _casteController,
                  decoration: const InputDecoration(
                    labelText: 'Caste',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _subCasteController,
                  decoration: const InputDecoration(
                    labelText: 'Sub-Caste',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _motherTongueController,
                  decoration: const InputDecoration(
                    labelText: 'Mother Tongue',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Education & Career',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _educationController,
                  decoration: const InputDecoration(
                    labelText: 'Education',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _occupationController,
                  decoration: const InputDecoration(
                    labelText: 'Occupation',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _annualIncomeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Annual Income',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Location',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        setState(() => _isLoading = true);
                        try {
                          final position = await LocationService.getCurrentLocation();
                          if (position != null) {
                            await LocationService.updateLocationToServer(position);
                            
                            // Get address from coordinates
                            final address = await LocationService.getAddressFromCoordinates(
                              position.latitude, 
                              position.longitude
                            );

                            if (address != null) {
                              setState(() {
                                _cityController.text = (address['city'] ?? address['town'] ?? address['village'] ?? address['suburb'] ?? '').toString();
                                _stateController.text = (address['state'] ?? '').toString();
                                _countryController.text = (address['country'] ?? '').toString();
                                _countyController.text = (address['county'] ?? '').toString();
                                _postalCodeController.text = (address['postcode'] ?? address['postal_code'] ?? '').toString();
                                
                                // Handle district mapping
                                String? detDistrict = (address['state_district'] ?? address['district'] ?? address['county'] ?? '').toString();
                                if (detDistrict != null) {
                                  detDistrict = detDistrict.replaceAll(' District', '').trim();
                                  try {
                                    _selectedDistrict = _keralaDistricts.firstWhere(
                                      (d) => d.toLowerCase() == detDistrict!.toLowerCase(),
                                      orElse: () => _selectedDistrict ?? _keralaDistricts.first,
                                    );
                                  } catch (_) {}
                                }
                              });
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Location detected and fields updated!')),
                            );
                          }
                        } finally {
                          setState(() => _isLoading = false);
                        }
                      },
                      icon: const Icon(Icons.my_location, size: 18),
                      label: const Text('Detect GPS'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _cityController,
                  textInputAction: TextInputAction.search,
                  onFieldSubmitted: (_) => _triggerCityLookup(),
                  decoration: InputDecoration(
                    labelText: 'City',
                    border: const OutlineInputBorder(),
                    helperText: 'Enter city and tap icon or enter to auto-fill',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.travel_explore, color: Color(0xFFB47FFF)),
                      onPressed: _triggerCityLookup,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedDistrict,
                  decoration: const InputDecoration(
                    labelText: 'District',
                    border: OutlineInputBorder(),
                  ),
                  items: _keralaDistricts.map((district) {
                    return DropdownMenuItem(
                      value: district,
                      child: Text(district),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDistrict = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _countyController,
                  decoration: const InputDecoration(
                    labelText: 'County / Taluk',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _stateController,
                  decoration: const InputDecoration(
                    labelText: 'State',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _countryController,
                        decoration: const InputDecoration(
                          labelText: 'Country',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _postalCodeController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: 'Postal Code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'About Me',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _bioController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Family Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FamilyDetailsScreen(),
                        ),
                      );
                      if (result == true) {
                        // Profile updated
                      }
                    },
                    icon: const Icon(Icons.family_restroom),
                    label: const Text('Add/Edit Family Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFB47FFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/preferences');
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Edit Preferences'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF5CB3FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/profile-photos');
                    },
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Manage Photos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4CD9A6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dateOfBirthController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _religionController.dispose();
    _casteController.dispose();
    _subCasteController.dispose();
    _motherTongueController.dispose();
    _educationController.dispose();
    _occupationController.dispose();
    _annualIncomeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _countyController.dispose();
    _postalCodeController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
