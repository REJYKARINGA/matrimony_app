import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    
    // Show dialog to choose source
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      setState(() => _isLoading = true);
      
      try {
        // 1. Upload photo via ProfileService
        final response = await ProfileService.uploadProfilePhoto(image);
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          final uploadData = json.decode(response.body);
          final String photoUrl = uploadData['photo']['photo_url']; 
          
          // 2. Update user profile with new photo URL
          final updateResponse = await ProfileService.updateMyProfile(
            profilePicture: photoUrl
          );

          if (updateResponse.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile picture updated successfully')),
            );
            _loadProfile(); // Reload to refresh UI
          } else {
            throw Exception('Failed to update profile picture link');
          }
        } else {
          throw Exception('Failed to upload image');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile picture: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFB47FFF), Color(0xFF5CB3FF), Color(0xFF4CD9A6)],
            ),
          ),
          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFB47FFF), Color(0xFF5CB3FF), Color(0xFF4CD9A6)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFB47FFF),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickStats(),
                _buildSection('Personal Information', [
                  _buildGrid([
                    _buildCompactInfo(Icons.cake_outlined, 'DOB', DateFormatter.formatDate(_user?.userProfile?.dateOfBirth)),
                    _buildCompactInfo(Icons.wc_outlined, 'Gender', _user?.userProfile?.gender),
                    _buildCompactInfo(Icons.height, 'Height', '${_user?.userProfile?.height ?? '-'} cm'),
                    _buildCompactInfo(Icons.monitor_weight_outlined, 'Weight', '${_user?.userProfile?.weight ?? '-'} kg'),
                    _buildCompactInfo(Icons.favorite_border, 'Status', _user?.userProfile?.maritalStatus?.replaceAll('_', ' ')),
                    _buildCompactInfo(Icons.language_outlined, 'Tongue', _user?.userProfile?.motherTongue),
                  ]),
                ]),
                _buildSection('Religion & Community', [
                  _buildGrid([
                    _buildCompactInfo(Icons.church_outlined, 'Religion', _user?.userProfile?.religion),
                    _buildCompactInfo(Icons.people_outline, 'Caste', _user?.userProfile?.caste),
                    _buildCompactInfo(Icons.group_work_outlined, 'Sub-Caste', _user?.userProfile?.subCaste),
                  ]),
                ]),
                _buildSection('Education & Occupation', [
                  _buildCompactInfo(Icons.school_outlined, 'Education', _user?.userProfile?.education, isFullWidth: true),
                  const SizedBox(height: 12),
                  _buildGrid([
                    _buildCompactInfo(Icons.work_outline, 'Occupation', _user?.userProfile?.occupation),
                    _buildCompactInfo(Icons.currency_rupee, 'Income', _user?.userProfile?.annualIncome != null ? '₹${_user!.userProfile!.annualIncome}' : null),
                  ]),
                ]),
                _buildSection('Family Details', [
                  _buildGrid([
                    _buildCompactInfo(Icons.person_outline, 'Father', _user?.familyDetails?.fatherName),
                    _buildCompactInfo(Icons.work_outline, 'Occupation', _user?.familyDetails?.fatherOccupation),
                    _buildCompactInfo(Icons.person_outline, 'Mother', _user?.familyDetails?.motherName),
                    _buildCompactInfo(Icons.work_outline, 'Occupation', _user?.familyDetails?.motherOccupation),
                  ]),
                  const SizedBox(height: 12),
                  _buildGrid([
                    _buildCompactInfo(Icons.people_alt_outlined, 'Siblings', _user?.familyDetails?.siblings?.toString()),
                    _buildCompactInfo(Icons.home_outlined, 'Family Type', _user?.familyDetails?.familyType),
                  ]),
                  if (_user?.familyDetails?.elderBrother != null || _user?.familyDetails?.youngerBrother != null) ...[
                    const SizedBox(height: 12),
                    _buildCompactInfo(Icons.person_pin_outlined, 'Brothers', '${_user?.familyDetails?.elderBrother ?? 0} Elder, ${_user?.familyDetails?.youngerBrother ?? 0} Younger', isFullWidth: true),
                  ],
                  if (_user?.familyDetails?.elderSister != null || _user?.familyDetails?.youngerSister != null) ...[
                    const SizedBox(height: 12),
                    _buildCompactInfo(Icons.person_pin_outlined, 'Sisters', '${_user?.familyDetails?.elderSister ?? 0} Elder, ${_user?.familyDetails?.youngerSister ?? 0} Younger', isFullWidth: true),
                  ],
                ]),
                _buildSection('Partner Preferences', [
                  _buildGrid([
                    _buildCompactInfo(Icons.calendar_today_outlined, 'Age', '${_user?.preferences?.minAge ?? '-'}-${_user?.preferences?.maxAge ?? '-'} yrs'),
                    _buildCompactInfo(Icons.height, 'Height', '${_user?.preferences?.minHeight ?? '-'}-${_user?.preferences?.maxHeight ?? '-'} cm'),
                  ]),
                  const SizedBox(height: 12),
                  _buildCompactInfo(Icons.favorite_border, 'Marital Status', _user?.preferences?.maritalStatus, isFullWidth: true),
                  const SizedBox(height: 12),
                  _buildCompactInfo(Icons.map_outlined, 'Locations', _user?.preferences?.preferredLocations?.join(', '), isFullWidth: true),
                ]),
                _buildPhotosSection(),
                if ((_user?.userProfile?.bio ?? '').isNotEmpty)
                  _buildSection('About Me', [
                    Text(
                      _user!.userProfile!.bio!,
                      style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.5),
                    ),
                  ]),
                const SizedBox(height: 32),
                _buildActionButtons(),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      elevation: 0,
      stretch: true,
      backgroundColor: const Color(0xFF5CB3FF),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFB47FFF), Color(0xFF5CB3FF), Color(0xFF4CD9A6)],
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.white,
                        backgroundImage: _user?.userProfile?.profilePicture != null
                            ? NetworkImage(ApiService.getImageUrl(_user!.userProfile!.profilePicture!))
                            : null,
                        child: _user?.userProfile?.profilePicture == null
                            ? const Icon(Icons.person, size: 70, color: Color(0xFFB47FFF))
                            : null,
                      ),
                    ),
                    GestureDetector(
                      onTap: _pickAndUploadImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, size: 20, color: Color(0xFFB47FFF)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${_user?.userProfile?.firstName ?? ''} ${_user?.userProfile?.lastName ?? ''}',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user, color: Colors.white.withOpacity(0.8), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _user?.email ?? '',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_note, color: Colors.white, size: 28),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen(user: _user))),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.location_on_outlined, _user?.userProfile?.city ?? 'City'),
          _buildStatDivider(),
          _buildStatItem(Icons.cake_outlined, '${_user?.userProfile?.age ?? '-'} Years'),
          _buildStatDivider(),
          _buildStatItem(Icons.height, '${_user?.userProfile?.height ?? '-'} cm'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF5CB3FF), size: 22),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 30, width: 1, color: Colors.grey[200]);
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildGrid(List<Widget> children) {
    return LayoutBuilder(builder: (context, constraints) {
      final itemWidth = (constraints.maxWidth - 12) / 2;
      List<Widget> rows = [];
      for (var i = 0; i < children.length; i += 2) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: itemWidth, child: children[i]),
                const SizedBox(width: 12),
                if (i + 1 < children.length)
                  SizedBox(width: itemWidth, child: children[i + 1]),
              ],
            ),
          ),
        );
      }
      return Column(children: rows);
    });
  }

  Widget _buildCompactInfo(IconData icon, String label, String? value, {bool isFullWidth = false}) {
    if (value == null || value.isEmpty || value == 'null') return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: const Color(0xFFB47FFF).withOpacity(0.8)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildPrimaryButton(Icons.family_restroom, 'Family Details', const Color(0xFFB47FFF), () async {
              if (await Navigator.push(context, MaterialPageRoute(builder: (context) => const FamilyDetailsScreen())) == true) _loadProfile();
            }),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildPrimaryButton(Icons.settings, 'Preferences', const Color(0xFF5CB3FF), () => Navigator.pushNamed(context, '/preferences')),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(IconData icon, String label, Color color, VoidCallback onPressed) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    final photos = _user?.profilePhotos ?? [];
    if (photos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Profile Photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/profile-photos'),
                child: const Text('Manage', style: TextStyle(color: Color(0xFFB47FFF), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _showFullScreenImage(index, photos),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(image: NetworkImage(ApiService.getImageUrl(photos[index].photoUrl)), fit: BoxFit.cover),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
                        ApiService.getImageUrl(photos[index].photoUrl),
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
                          shadows: [
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
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              // Image Index Indicator
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Swipe to see more',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
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
