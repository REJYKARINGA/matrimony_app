import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui';
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
import 'verification_screen.dart';

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
        if (!mounted) return;
        setState(() {
          _user = user;
          _isLoading = false;
        });
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
        if (mounted) {
          setState(() => _isLoading = false);
        }
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
              colors: [Color(0xFF00BCD4), Color(0xFF0D47A1)],
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
              colors: [Color(0xFF00BCD4), Color(0xFF0D47A1)],
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
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF00BCD4),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 10,
                    shadowColor: const Color(0xFF00BCD4).withOpacity(0.3),
                  ),
                  child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: Stack(
        children: [
          _buildBackgroundBlobs(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickStats(),
                    _buildSection('Personal Information', [
                      _buildGrid([

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
                      _buildCompactInfo(Icons.person_outline, 'Father', _maskName(_user?.familyDetails?.fatherName)),
                      const SizedBox(height: 12),
                      _buildCompactInfo(Icons.work_outline, 'Father\'s Occupation', _user?.familyDetails?.fatherOccupation),
                      const SizedBox(height: 12),
                      _buildCompactInfo(Icons.person_outline, 'Mother', _maskName(_user?.familyDetails?.motherName)),
                      const SizedBox(height: 12),
                      _buildCompactInfo(Icons.work_outline, 'Mother\'s Occupation', _user?.familyDetails?.motherOccupation),
                      const SizedBox(height: 12),
                      _buildCompactInfo(Icons.people_alt_outlined, 'Siblings', _user?.familyDetails?.siblings?.toString()),
                      const SizedBox(height: 12),
                      _buildCompactInfo(Icons.home_outlined, 'Family Type', _user?.familyDetails?.familyType),
                      
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
                        _buildCompactInfo(
                          Icons.calendar_today_outlined,
                          'Age',
                          (_user?.preferences?.minAge == null && _user?.preferences?.maxAge == null)
                              ? 'Not Specified'
                              : '${_user?.preferences?.minAge ?? 18} - ${_user?.preferences?.maxAge ?? 70} Years',
                        ),
                        _buildCompactInfo(
                          Icons.height,
                          'Height',
                          (_user?.preferences?.minHeight == null && _user?.preferences?.maxHeight == null)
                              ? 'Not Specified'
                              : '${_user?.preferences?.minHeight ?? 140} - ${_user?.preferences?.maxHeight ?? 220} cm',
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _buildCompactInfo(Icons.favorite_border, 'Marital Status', _user?.preferences?.maritalStatus, isFullWidth: true),
                      const SizedBox(height: 12),
                      _buildCompactInfo(Icons.map_outlined, 'Locations', _user?.preferences?.preferredLocations?.join(', '), isFullWidth: true),
                    ]),
                    _buildPhotosSection(),
                    _buildSection('About Me', [
                      if ((_user?.userProfile?.bio ?? '').isNotEmpty) ...[
                        Text(
                          _user!.userProfile!.bio!,
                          style: const TextStyle(fontSize: 15, color: Color(0xFF757575), height: 1.6, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                      ],
                      _buildGrid([
                        _buildCompactInfo(
                          Icons.medical_services_outlined, 
                          'Drug Addiction', 
                          _user?.userProfile?.drugAddiction == true ? 'Yes' : 'No'
                        ),
                        _buildCompactInfo(
                          Icons.smoke_free_rounded, 
                          'Smoking', 
                          _user?.userProfile?.smoke
                        ),
                        _buildCompactInfo(
                          Icons.local_bar_rounded, 
                          'Drinking', 
                          _user?.userProfile?.alcohol
                        ),
                      ]),
                    ]),
                    _buildSection('Trust & Safety', [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.verified_user_outlined, color: Colors.green, size: 20),
                        ),
                        title: const Text('Account Verification', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Verify your identity to get a verification badge', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VerificationScreen())),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      elevation: 0,
      stretch: true,
      backgroundColor: const Color(0xFF00BCD4),
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 24),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen(user: _user))),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF00BCD4), Color(0xFF00838F)],
                ),
              ),
            ),
            if (_user?.displayImage != null)
              Image.network(
                ApiService.getImageUrl(_user!.displayImage!),
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.3),
                colorBlendMode: BlendMode.darken,
              ),
            Positioned(
              bottom: -1,
              left: 0,
              right: 0,
              child: Container(
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F7FF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white,
                          backgroundImage: _user?.displayImage != null
                              ? NetworkImage(ApiService.getImageUrl(_user!.displayImage!))
                              : null,
                          child: _user?.displayImage == null
                              ? const Icon(Icons.person, size: 55, color: Color(0xFF00BCD4))
                              : null,
                        ),
                      ),
                      GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt, size: 16, color: Color(0xFF00BCD4)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_user?.userProfile?.firstName ?? ''} ${_user?.userProfile?.lastName ?? ''}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_user?.verification?.status == 'verified') ...[
                        const Icon(Icons.verified, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        _user?.email ?? '',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                      ),
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

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(Icons.location_on_outlined, _user?.userProfile?.city ?? 'City'),
              _buildStatDivider(),
              _buildStatItem(Icons.cake_outlined, '${_user?.userProfile?.age ?? '-'} Years'),
              _buildStatDivider(),
              _buildStatItem(Icons.height, '${_user?.userProfile?.height ?? '-'} cm'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00BCD4), size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 30, width: 1, color: Colors.grey[200]);
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
                letterSpacing: 0.3,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Widget> children) {
    return LayoutBuilder(builder: (context, constraints) {
      final itemWidth = (constraints.maxWidth - 16) / 2;
      return Wrap(
        spacing: 16,
        runSpacing: 20,
        children: children.map((child) {
          return SizedBox(
            width: itemWidth,
            child: child,
          );
        }).toList(),
      );
    });
  }

  Widget _buildCompactInfo(IconData icon, String label, String? value, {bool isFullWidth = false}) {
    if (value == null || value.isEmpty || value == 'null') return const SizedBox.shrink();

    String formattedValue = value.toLowerCase() == 'never_married'
        ? 'Single'
        : value.replaceAll('_', ' ').split(' ').map((word) {
            if (word.isEmpty) return word;
            return word[0].toUpperCase() + word.substring(1).toLowerCase();
          }).join(' ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00BCD4).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF00BCD4)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formattedValue,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildPrimaryButton(Icons.family_restroom, 'Family Details', const Color(0xFFF0E6FF), () async {
              if (await Navigator.push(context, MaterialPageRoute(builder: (context) => const FamilyDetailsScreen())) == true) _loadProfile();
            }, isOutlined: true),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildPrimaryButton(Icons.settings, 'Preferences', const Color(0xFFF0E6FF), () => Navigator.pushNamed(context, '/preferences'), isOutlined: true),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(IconData icon, String label, Color color, VoidCallback onPressed, {bool isOutlined = false}) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: isOutlined ? null : const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF0D47A1)]),
        color: isOutlined ? const Color(0xFFE0F7FA) : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isOutlined ? const Color(0xFF00BCD4) : const Color(0xFF00BCD4)).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6)
          )
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: isOutlined ? const Color(0xFF00BCD4) : Colors.white),
        label: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isOutlined ? const Color(0xFF00BCD4) : Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: isOutlined ? const Color(0xFF00BCD4) : Colors.white,
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
              const Text('Profile Photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/profile-photos'),
                child: const Text('Manage', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.w800)),
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
                      boxShadow: [BoxShadow(color: const Color(0xFF00BCD4).withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 6))],
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

  String _maskName(String? name) {
    if (name == null || name.isEmpty) return '-';
    if (name.length <= 1) return '*';
    return '${name[0]}${'*' * (name.length - 1)}';
  }

  Widget _buildBackgroundBlobs() {
    return Container(color: const Color(0xFFF8F7FF));
  }

}

// EditProfileScreen with updated colors
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
  bool _drugAddiction = false;
  String? _selectedSmoke;
  String? _selectedAlcohol;
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
    _drugAddiction = widget.user?.userProfile?.drugAddiction ?? false;
    _selectedSmoke = widget.user?.userProfile?.smoke;
    _selectedAlcohol = widget.user?.userProfile?.alcohol;
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
        drugAddiction: _drugAddiction,
        smoke: _selectedSmoke,
        alcohol: _selectedAlcohol,
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
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
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
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }

  InputDecoration _buildModernInputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffixIcon,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helperText,
      prefixIcon: Icon(icon, color: const Color(0xFF00BCD4), size: 22),
      suffixIcon: suffixIcon,
      labelStyle: TextStyle(
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF00BCD4),
        fontWeight: FontWeight.w600,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00BCD4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF0D47A1)),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Custom Gradient Header (Similar to Landing/Preferences)
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: 20,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF00BCD4), Color(0xFF0D47A1)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00BCD4).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Edit Profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
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
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Personal Information', Icons.person_outline),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: _buildModernInputDecoration(
                              label: 'First Name',
                              icon: Icons.person_rounded,
                            ),
                            validator: (value) => value?.isEmpty == true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: _buildModernInputDecoration(
                              label: 'Last Name',
                              icon: Icons.person_rounded,
                            ),
                            validator: (value) => value?.isEmpty == true ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _dateOfBirthController,
                      decoration: _buildModernInputDecoration(
                        label: 'Date of Birth',
                        icon: Icons.calendar_today_rounded,
                      ),
                      readOnly: true,
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _dateOfBirthController.text.isNotEmpty
                              ? DateFormatter.parseDate(_dateOfBirthController.text) ?? DateTime.now()
                              : DateTime.now(),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            _dateOfBirthController.text = DateFormatter.formatDate(pickedDate);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: _buildModernInputDecoration(
                        label: 'Gender',
                        icon: Icons.transgender_rounded,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(value: 'female', child: Text('Female')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) => setState(() => _selectedGender = value),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            decoration: _buildModernInputDecoration(
                              label: 'Height (cm)',
                              icon: Icons.height_rounded,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            decoration: _buildModernInputDecoration(
                              label: 'Weight (kg)',
                              icon: Icons.scale_rounded,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedMaritalStatus,
                      decoration: _buildModernInputDecoration(
                        label: 'Marital Status',
                        icon: Icons.favorite_border_rounded,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'never_married', child: Text('Never Married')),
                        DropdownMenuItem(value: 'divorced', child: Text('Divorced')),
                        DropdownMenuItem(value: 'widowed', child: Text('Widowed')),
                      ],
                      onChanged: (value) => setState(() => _selectedMaritalStatus = value),
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader('Religion & Community', Icons.church_outlined),
                    
                    TextFormField(
                      controller: _religionController,
                      decoration: _buildModernInputDecoration(
                        label: 'Religion',
                        icon: Icons.auto_awesome_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _casteController,
                      decoration: _buildModernInputDecoration(
                        label: 'Caste',
                        icon: Icons.groups_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _subCasteController,
                      decoration: _buildModernInputDecoration(
                        label: 'Sub-Caste',
                        icon: Icons.group_work_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _motherTongueController,
                      decoration: _buildModernInputDecoration(
                        label: 'Mother Tongue',
                        icon: Icons.translate_rounded,
                      ),
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader('Education & Career', Icons.work_outline),
                    
                    TextFormField(
                      controller: _educationController,
                      decoration: _buildModernInputDecoration(
                        label: 'Education',
                        icon: Icons.school_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _occupationController,
                      decoration: _buildModernInputDecoration(
                        label: 'Occupation',
                        icon: Icons.business_center_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _annualIncomeController,
                      keyboardType: TextInputType.number,
                      decoration: _buildModernInputDecoration(
                        label: 'Annual Income',
                        icon: Icons.payments_rounded,
                      ),
                    ),

                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader('Location', Icons.location_on_outlined),
                        TextButton.icon(
                          onPressed: () async {
                            setState(() => _isLoading = true);
                            try {
                              final position = await LocationService.getCurrentLocation();
                              if (position != null) {
                                await LocationService.updateLocationToServer(position);
                                final address = await LocationService.getAddressFromCoordinates(
                                  position.latitude, 
                                  position.longitude
                                );

                                if (address != null && mounted) {
                                  setState(() {
                                    _cityController.text = (address['city'] ?? address['town'] ?? address['village'] ?? address['suburb'] ?? '').toString();
                                    _stateController.text = (address['state'] ?? '').toString();
                                    _countryController.text = (address['country'] ?? '').toString();
                                    _countyController.text = (address['county'] ?? '').toString();
                                    _postalCodeController.text = (address['postcode'] ?? address['postal_code'] ?? '').toString();
                                    
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
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Location detected!')),
                                  );
                                }
                              }
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                          icon: const Icon(Icons.my_location_rounded, size: 18, color: Color(0xFF0D47A1)),
                          label: const Text(
                            'Detect GPS',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                          ),
                        ),
                      ],
                    ),
                    
                    TextFormField(
                      controller: _cityController,
                      textInputAction: TextInputAction.search,
                      onFieldSubmitted: (_) => _triggerCityLookup(),
                      decoration: _buildModernInputDecoration(
                        label: 'City',
                        icon: Icons.location_city_rounded,
                        helperText: 'Tap icon to auto-fill location details',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.travel_explore, color: Color(0xFF00BCD4)),
                          onPressed: _triggerCityLookup,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedDistrict,
                      decoration: _buildModernInputDecoration(
                        label: 'District',
                        icon: Icons.map_rounded,
                      ),
                      items: _keralaDistricts.map((district) {
                        return DropdownMenuItem(value: district, child: Text(district));
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedDistrict = value),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _countyController,
                      decoration: _buildModernInputDecoration(
                        label: 'County / Taluk',
                        icon: Icons.landscape_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _stateController,
                      decoration: _buildModernInputDecoration(
                        label: 'State',
                        icon: Icons.flag_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _countryController,
                            decoration: _buildModernInputDecoration(
                              label: 'Country',
                              icon: Icons.public_rounded,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _postalCodeController,
                            decoration: _buildModernInputDecoration(
                              label: 'Postal Code',
                              icon: Icons.pin_drop_rounded,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader('About Me', Icons.description_outlined),
                    
                    TextFormField(
                      controller: _bioController,
                      maxLines: 4,
                      decoration: _buildModernInputDecoration(
                        label: 'Bio',
                        icon: Icons.auto_awesome_outlined,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'Drug Addiction',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Includes any substance abuse beyond tobacco/alcohol',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _drugAddiction,
                        activeColor: const Color(0xFF00BCD4),
                        onChanged: (val) => setState(() => _drugAddiction = val),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedSmoke,
                      decoration: _buildModernInputDecoration(
                        label: 'Smoking Habit',
                        icon: Icons.smoke_free_rounded,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'never', child: Text('Never')),
                        DropdownMenuItem(value: 'occasionally', child: Text('Occasionally')),
                        DropdownMenuItem(value: 'regularly', child: Text('Regularly')),
                      ],
                      onChanged: (val) => setState(() => _selectedSmoke = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedAlcohol,
                      decoration: _buildModernInputDecoration(
                        label: 'Drinking Habit',
                        icon: Icons.local_bar_rounded,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'never', child: Text('Never')),
                        DropdownMenuItem(value: 'occasionally', child: Text('Occasionally')),
                        DropdownMenuItem(value: 'regularly', child: Text('Regularly')),
                      ],
                      onChanged: (val) => setState(() => _selectedAlcohol = val),
                    ),

                    const SizedBox(height: 40),
                    _buildSectionHeader('Profile Links', Icons.link_rounded),
                    
                    _buildActionButton(
                      label: 'Family Details',
                      icon: Icons.family_restroom_rounded,
                      gradient: const [Color(0xFF00BCD4), Color(0xFF0097A7)],
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FamilyDetailsScreen())),
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      label: 'Edit Preferences',
                      icon: Icons.settings_rounded,
                      gradient: const [Color(0xFF0D47A1), Color(0xFF1565C0)],
                      onPressed: () => Navigator.pushNamed(context, '/preferences'),
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      label: 'Manage Photos',
                      icon: Icons.photo_library_rounded,
                      gradient: const [Color(0xFF4CD9A6), Color(0xFF388E3C)],
                      onPressed: () => Navigator.pushNamed(context, '/profile-photos'),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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