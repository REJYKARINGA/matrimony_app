import '../../../../../../utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../widgets/watermark_overlay.dart';
import '../models/user_model.dart';
import '../services/location_service.dart';
import '../services/profile_service.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/date_formatter.dart';
import '../services/profile_share_service.dart';
import 'family_details_screen.dart';
import 'preferences_screen.dart';
import 'profile_photos_screen.dart';
import 'verification_screen.dart';
import 'photo_requests_screen.dart';
import 'map_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/app_colors.dart';

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
    // Check if user already has 5 photos
    if (_user?.profilePhotos != null && _user!.profilePhotos!.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo limit reached. Redirecting to Manage Photos...'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Wait a moment for snackbar to be seen, then navigate
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pushNamed(context, '/profile-photos');
        }
      });
      return;
    }

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
        backgroundColor: AppColors.offWhite,
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.deepEmerald,
            strokeWidth: 3,
          ),
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
              colors: [AppColors.deepEmerald, AppColors.deepEmerald],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.cardDark),
                const SizedBox(height: 16),
                 Text(
                   _errorMessage!,
                   style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
                   textAlign: TextAlign.center,
                 ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.offWhite,
                    foregroundColor: AppColors.deepEmerald,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 10,
                    shadowColor: AppColors.deepEmerald.withOpacity(0.3),
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
                    _buildSection('Location Details', [
                      _buildGrid([
                        _buildCompactInfo(Icons.home_outlined, 'Home City', _user?.userProfile?.city),
                        _buildCompactInfo(Icons.map_outlined, 'District', _user?.userProfile?.district),
                        _buildCompactInfo(Icons.location_city_outlined, 'Present City', _user?.userProfile?.presentCity),
                        _buildCompactInfo(Icons.public_outlined, 'Present Country', _user?.userProfile?.presentCountry),
                        _buildCompactInfo(Icons.flag_outlined, 'State', _user?.userProfile?.state),
                        _buildCompactInfo(Icons.public_outlined, 'Country', _user?.userProfile?.country),
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
                      const SizedBox(height: 12),
                      _buildGrid([
                        _buildCompactInfo(Icons.medical_services_outlined, 'Drug Habits', _user?.preferences?.drugAddiction),
                        _buildCompactInfo(Icons.smoke_free_rounded, 'Smoking', _user?.preferences?.smoke?.join(', ')),
                        _buildCompactInfo(Icons.local_bar_rounded, 'Alcohol', _user?.preferences?.alcohol?.join(', ')),
                      ]),
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
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.deepEmerald.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.photo_library_rounded, color: AppColors.deepEmerald, size: 20),
                        ),
                        title: const Text('Photo Requests', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Manage who can access your photos', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PhotoRequestsScreen())),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    if (_user?.interests != null && _user!.interests!.isNotEmpty)
                      _buildChipsSectionProfile('Interests & Hobbies', Icons.auto_awesome_outlined, _user!.interests!, 'interest_name'),
                    if (_user?.personalities != null && _user!.personalities!.isNotEmpty)
                      _buildChipsSectionProfile('Personality Traits', Icons.psychology_outlined, _user!.personalities!, 'personality_name'),
                    const SizedBox(height: 24),
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
      backgroundColor: AppColors.deepEmerald,
      iconTheme: const IconThemeData(color: AppColors.cardDark),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: AppColors.cardDark, size: 24),
          onPressed: () {
            if (_user != null) {
              ProfileShareService.shareProfile(context, _user!);
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: AppColors.cardDark, size: 24),
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
                  colors: [AppColors.deepEmerald, AppColors.deepEmerald],
                ),
              ),
            ),
            if (_user?.displayImage != null)
              Image.network(
                ApiService.getImageUrl(_user!.displayImage!),
                fit: BoxFit.cover,
                 color: Colors.black54,
                colorBlendMode: BlendMode.darken,
              ),
            // No watermark on own profile
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
                          color: AppColors.cardDark.withOpacity(0.2),
                        ),
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 55,
                              backgroundColor: AppColors.offWhite,
                              backgroundImage: _user?.displayImage != null
                                  ? NetworkImage(ApiService.getImageUrl(_user!.displayImage!))
                                  : null,
                              child: _user?.displayImage == null
                                  ? const Icon(Icons.person, size: 55, color: AppColors.deepEmerald)
                                  : null,
                            ),
                            // No watermark on own profile avatar
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.cardDark,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.white70, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt, size: 16, color: AppColors.deepEmerald),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                   Text(
                     '${_user?.userProfile?.firstName ?? ''} ${_user?.userProfile?.lastName ?? ''}',
                     style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: 0.5),
                   ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_user?.verification?.status == 'verified') ...[
                        const Icon(Icons.verified, color: AppColors.cardDark, size: 16),
                        const SizedBox(width: 4),
                      ],
                       Text(
                         _user?.matrimonyId != null ? 'ID: ${_user!.matrimonyId}' : '',
                         style: TextStyle(color: Colors.black87.withOpacity(0.9), fontSize: 13),
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
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.white70.withOpacity(0.05),
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
        Icon(icon, color: AppColors.deepEmerald, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.bodyText),
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
                color: AppColors.bodyText,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.white70.withOpacity(0.02),
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
            color: AppColors.deepEmerald.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.deepEmerald),
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
                  color: AppColors.bodyText,
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

  Widget _buildChipsSectionProfile(String title, IconData icon, List<dynamic> items, String nameKey) {
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
                color: AppColors.bodyText,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.white70.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                final name = item[nameKey] ?? '';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.deepEmerald.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.deepEmerald.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.deepEmerald,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
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
          const SizedBox(height: 12),
          _buildPrimaryButton(
            Icons.share_outlined, 
            'Share My Profile to Family', 
            AppColors.deepEmerald, 
            () {
              if (_user != null) {
                ProfileShareService.shareProfile(context, _user!);
              }
            }
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(IconData icon, String label, Color color, VoidCallback onPressed, {bool isOutlined = false}) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: isOutlined ? null : const LinearGradient(colors: [AppColors.deepEmerald, AppColors.deepEmerald]),
        color: isOutlined ? const Color(0xFFE0F7FA) : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isOutlined ? AppColors.deepEmerald : AppColors.deepEmerald).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6)
          )
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: isOutlined ? AppColors.deepEmerald : AppColors.cardDark),
        label: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isOutlined ? AppColors.deepEmerald : AppColors.cardDark)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: isOutlined ? AppColors.deepEmerald : AppColors.cardDark,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    List<ProfilePhoto> photos = [];
    if (_user?.profilePhotos != null) {
      photos = List<ProfilePhoto>.from(_user!.profilePhotos!);
      // Filter out rejected photos
      photos = photos.where((p) => 
        p.isRejected != true && 
        p.isRejected != 1 && 
        p.isRejected != "1"
      ).toList();
      // Sort so primary is first
      photos.sort((a, b) {
        if (a.isPrimary == true) return -1;
        if (b.isPrimary == true) return 1;
        return 0;
      });
    }
    
    if (photos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Profile Photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.bodyText)),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/profile-photos'),
                child: const Text('Manage', style: TextStyle(color: AppColors.deepEmerald, fontWeight: FontWeight.w800)),
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
                      boxShadow: [BoxShadow(color: AppColors.deepEmerald.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 6))],
                    ),
                    child: const SizedBox.shrink(), // No watermark on own photos
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
          backgroundColor: Colors.white70,
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
                          return const Center(child: CircularProgressIndicator(color: AppColors.cardDark));
                        },
                      ),
                    ),
                  );
                },
              ),
             // No watermark in own full-screen photo viewer
              // Back Button
              Positioned(
                top: 40,
                left: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.cardDark, size: 30),
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
                      color: Colors.white70.withOpacity(0.5),
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
  late TextEditingController _presentCityController;
  late TextEditingController _presentCountryController;
  late TextEditingController _districtController;
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
  bool _isPersonalitiesExpanded = false;
  bool _isInterestsExpanded = false;
  double? _latitude;
  double? _longitude;

  // Master data for searchable selects
  List<dynamic> _religions = [];
  List<dynamic> _availableCastes = [];
  List<dynamic> _availableSubCastes = [];
  List<dynamic> _educations = [];
  List<dynamic> _occupations = [];
  List<dynamic> _personalities = [];
  List<dynamic> _interests = [];

  // Selected IDs for foreign relationships
  int? _selectedReligionId;
  int? _selectedCasteId;
  int? _selectedSubCasteId;
  int? _selectedEducationId;
  int? _selectedOccupationId;
  List<int> _selectedPersonalityIds = [];
  List<int> _selectedInterestIds = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final response = await ProfileService.getPreferenceOptions();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _religions = data['data']['religions'] ?? [];
            _educations = data['data']['educations'] ?? [];
            _occupations = data['data']['occupations'] ?? [];
            _personalities = data['data']['personalities'] ?? [];
            _interests = data['data']['interests'] ?? [];
          });
          
          // Auto-select Muslim ID if available
          final muslim = _religions.firstWhere(
            (r) => r['name'].toString().toLowerCase() == 'muslim',
            orElse: () => null,
          );
          if (muslim != null) {
            _selectedReligionId = muslim['id'];
            _religionController.text = 'Muslim';
          }
          
          // Initialize available castes/sub-castes based on current values
          _updateAvailableCastes(_religionController.text);
          _updateAvailableSubCastes(_casteController.text);
        }
      }
    } catch (e) {
      debugPrint('Error loading options: $e');
    }
  }

  void _updateAvailableCastes(String religionName) {
    if (religionName.isEmpty) {
      setState(() => _availableCastes = []);
      return;
    }
    
    final religion = _religions.firstWhere(
      (r) => r['name'] == religionName,
      orElse: () => null,
    );
    
    setState(() {
      _availableCastes = religion != null ? religion['castes'] : [];
    });
  }

  void _updateAvailableSubCastes(String casteName) {
    if (casteName.isEmpty) {
      setState(() => _availableSubCastes = []);
      return;
    }
    
    final caste = _availableCastes.firstWhere(
      (c) => c['name'] == casteName,
      orElse: () => null,
    );
    
    setState(() {
      _availableSubCastes = caste != null ? caste['sub_castes'] : [];
    });
  }

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
      text: 'Muslim',
    );
    _selectedReligionId = widget.user?.userProfile?.religionId;
    _casteController = TextEditingController(
      text: widget.user?.userProfile?.caste ?? '',
    );
    _selectedCasteId = widget.user?.userProfile?.casteId;
    _subCasteController = TextEditingController(
      text: widget.user?.userProfile?.subCaste ?? '',
    );
    _selectedSubCasteId = widget.user?.userProfile?.subCasteId;
    _motherTongueController = TextEditingController(
      text: widget.user?.userProfile?.motherTongue ?? '',
    );
    _educationController = TextEditingController(
      text: widget.user?.userProfile?.education ?? '',
    );
    _selectedEducationId = widget.user?.userProfile?.educationId;
    _occupationController = TextEditingController(
      text: widget.user?.userProfile?.occupation ?? '',
    );
    _selectedOccupationId = widget.user?.userProfile?.occupationId;
    _annualIncomeController = TextEditingController(
      text: widget.user?.userProfile?.annualIncome?.toString() ?? '',
    );
    _cityController = TextEditingController(
      text: widget.user?.userProfile?.city ?? '',
    );
    _presentCityController = TextEditingController(
      text: widget.user?.userProfile?.presentCity ?? '',
    );
    _presentCountryController = TextEditingController(
      text: widget.user?.userProfile?.presentCountry ?? '',
    );
    _selectedDistrict = widget.user?.userProfile?.district;
    _districtController = TextEditingController(text: _selectedDistrict ?? '');
    _stateController = TextEditingController(
      text: (widget.user?.userProfile?.state == null || widget.user!.userProfile!.state!.isEmpty) ? 'Kerala' : widget.user!.userProfile!.state!,
    );
    _countryController = TextEditingController(
      text: (widget.user?.userProfile?.country == null || widget.user!.userProfile!.country!.isEmpty) ? 'India' : widget.user!.userProfile!.country!,
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
    if (widget.user?.personalities != null) {
      _selectedPersonalityIds = widget.user!.personalities!.map<int>((p) => int.parse(p['id'].toString())).toList();
    }
    if (widget.user?.interests != null) {
      _selectedInterestIds = widget.user!.interests!.map<int>((i) => int.parse(i['id'].toString())).toList();
    }
    _latitude = widget.user?.userProfile?.latitude;
    _longitude = widget.user?.userProfile?.longitude;
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
        religionId: _selectedReligionId,
        casteId: _selectedCasteId,
        subCasteId: _selectedSubCasteId,
        motherTongue: _motherTongueController.text,
        educationId: _selectedEducationId,
        occupationId: _selectedOccupationId,
        annualIncome: double.tryParse(_annualIncomeController.text),
        city: _cityController.text,
        presentCity: _presentCityController.text,
        presentCountry: _presentCountryController.text,
        district: _districtController.text,
        county: _countyController.text,
        state: _stateController.text,
        country: _countryController.text,
        postalCode: _postalCodeController.text,
        bio: _bioController.text,
        drugAddiction: _drugAddiction,
        smoke: _selectedSmoke,
        alcohol: _selectedAlcohol,
        personalityIds: _selectedPersonalityIds,
        interestIds: _selectedInterestIds,
        latitude: _latitude,
        longitude: _longitude,
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
              final matchedDistrict = _keralaDistricts.firstWhere(
                (d) => d.toLowerCase() == detDistrict!.toLowerCase(),
                orElse: () => _selectedDistrict ?? _keralaDistricts.first,
              );
              _selectedDistrict = matchedDistrict;
              _districtController.text = matchedDistrict;
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



  void _openSearchablePicker({
    required String title,
    required List<dynamic> items,
    required TextEditingController controller,
    Function(dynamic)? onSelected,
  }) {
    String searchText = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => StatefulBuilder(
          builder: (context, setModalState) => Container(
            decoration: const BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cardDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search $title...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.deepEmerald),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        searchText = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _buildPickerList(
                    controller: scrollController,
                    items: items,
                    searchText: searchText,
                    onSelected: (selectedItem) {
                      final name = selectedItem is String ? selectedItem : (selectedItem['name'] ?? '').toString();
                      controller.text = name;
                      if (onSelected != null) onSelected(selectedItem);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickerList({
    required ScrollController controller,
    required List<dynamic> items,
    required Function(dynamic) onSelected,
    required String searchText,
  }) {
    final filteredItems = items.where((item) {
      final name = item is String ? item : (item['name'] ?? '').toString();
      return name.toLowerCase().contains(searchText.toLowerCase());
    }).toList();

    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: filteredItems.length,
      separatorBuilder: (_, __) => Divider(color: Colors.grey[100]),
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        final name = item is String ? item : (item['name'] ?? '').toString();

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          title: Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.bodyText,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          onTap: () {
            onSelected(item);
            Navigator.pop(context);
          },
        );
      },
    );
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
      prefixIcon: Icon(icon, color: AppColors.deepEmerald, size: 22),
      suffixIcon: suffixIcon,
      labelStyle: TextStyle(
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      floatingLabelStyle: const TextStyle(
        color: AppColors.deepEmerald,
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
        borderSide: const BorderSide(color: AppColors.deepEmerald, width: 1.5),
      ),
      filled: true,
      fillColor: AppColors.softMint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.deepEmerald.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.deepEmerald),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.bodyText,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          // Custom Gradient Header (Similar to Landing/Preferences)
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 4,
              bottom: 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1.5,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white70.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.darkGreen, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Edit Profile',
                    textAlign: TextAlign.center,
                     style: TextStyle(color: Colors.black87,
                       fontSize: 20,
                       fontWeight: FontWeight.bold,
                       letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
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
                        DropdownMenuItem(value: 'never_married', child: Text('Single')),
                        DropdownMenuItem(value: 'nikkah_divorced', child: Text('Nikkah Divorced')),
                        DropdownMenuItem(value: 'divorced', child: Text('Divorced')),
                        DropdownMenuItem(value: 'widowed', child: Text('Widowed')),
                      ],
                      onChanged: (value) => setState(() => _selectedMaritalStatus = value),
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader('Religion & Community', Icons.church_outlined),
                    
                    TextFormField(
                      controller: _religionController,
                      readOnly: true,
                      onTap: () => _openSearchablePicker(
                        title: 'Religion',
                        items: _religions,
                        controller: _religionController,
                        onSelected: (item) {
                          setState(() {
                            _selectedReligionId = item['id'];
                            _casteController.clear();
                            _selectedCasteId = null;
                            _subCasteController.clear();
                            _selectedSubCasteId = null;
                            _updateAvailableCastes(_religionController.text);
                            _availableSubCastes = [];
                          });
                        },
                      ),
                      decoration: _buildModernInputDecoration(
                        label: 'Religion',
                        icon: Icons.auto_awesome_rounded,
                        suffixIcon: null, // No dropdown for disabled field
                      ),
                      enabled: false, // Disabled as per requirement
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _casteController,
                      readOnly: true,
                      onTap: () {
                        if (_religionController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select religion first')),
                          );
                          return;
                        }
                        _openSearchablePicker(
                          title: 'Caste',
                          items: _availableCastes,
                          controller: _casteController,
                          onSelected: (item) {
                            setState(() {
                              _selectedCasteId = item['id'];
                              _subCasteController.clear();
                              _selectedSubCasteId = null;
                              _updateAvailableSubCastes(_casteController.text);
                            });
                          },
                        );
                      },
                      decoration: _buildModernInputDecoration(
                        label: 'Caste',
                        icon: Icons.groups_rounded,
                        suffixIcon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.deepEmerald),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _subCasteController,
                      readOnly: true,
                      onTap: () {
                        if (_casteController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select caste first')),
                          );
                          return;
                        }
                        _openSearchablePicker(
                          title: 'Sub-Caste',
                          items: _availableSubCastes,
                          controller: _subCasteController,
                          onSelected: (item) {
                            setState(() {
                              _selectedSubCasteId = item['id'];
                            });
                          },
                        );
                      },
                      decoration: _buildModernInputDecoration(
                        label: 'Sub-Caste',
                        icon: Icons.group_work_rounded,
                        suffixIcon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.deepEmerald),
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
                      readOnly: true,
                      onTap: () => _openSearchablePicker(
                        title: 'Education',
                        items: _educations,
                        controller: _educationController,
                        onSelected: (item) {
                          setState(() {
                            _selectedEducationId = item['id'];
                          });
                        },
                      ),
                      decoration: _buildModernInputDecoration(
                        label: 'Education',
                        icon: Icons.school_rounded,
                        suffixIcon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.deepEmerald),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _occupationController,
                      readOnly: true,
                      onTap: () => _openSearchablePicker(
                        title: 'Occupation',
                        items: _occupations,
                        controller: _occupationController,
                        onSelected: (item) {
                          setState(() {
                            _selectedOccupationId = item['id'];
                          });
                        },
                      ),
                      decoration: _buildModernInputDecoration(
                        label: 'Occupation',
                        icon: Icons.business_center_rounded,
                        suffixIcon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.deepEmerald),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Location', Icons.location_on_outlined),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            _buildCompactActionButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MapPickerScreen(
                                      initialLat: _latitude,
                                      initialLng: _longitude,
                                    ),
                                  ),
                                );

                                if (result != null && result['location'] != null && result['address'] != null) {
                                  LatLng loc = result['location'];
                                  Map<String, String> address = result['address'];
                                  setState(() {
                                    _latitude = loc.latitude;
                                    _longitude = loc.longitude;
                                    _cityController.text = (address['city'] ?? address['town'] ?? address['village'] ?? address['suburb'] ?? '').toString();
                                    _stateController.text = (address['state'] ?? address['province'] ?? '').toString();
                                    _countryController.text = (address['country'] ?? '').toString();
                                    _countyController.text = (address['county'] ?? '').toString();
                                    _postalCodeController.text = (address['postcode'] ?? address['postal_code'] ?? '').toString();
                                    
                                    String? detDistrict = (address['state_district'] ?? address['district'] ?? address['county'] ?? '').toString();
                                    if (detDistrict != null && detDistrict.isNotEmpty) {
                                      detDistrict = detDistrict.replaceAll(' District', '').trim();
                                      try {
                                        final matched = _keralaDistricts.firstWhere(
                                          (d) => d.toLowerCase() == detDistrict!.toLowerCase(),
                                          orElse: () => _selectedDistrict ?? _keralaDistricts.first,
                                        );
                                        _selectedDistrict = matched;
                                        _districtController.text = matched;
                                      } catch (_) {}
                                    }
                                  });
                                }
                              },
                              icon: Icons.map_rounded,
                              label: 'Pick on Map',
                              colors: [const Color(0xFF009688), const Color(0xFF00695C)],
                            ),
                            _buildCompactActionButton(
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
                                        _latitude = position.latitude;
                                        _longitude = position.longitude;
                                        _cityController.text = (address['city'] ?? address['town'] ?? address['village'] ?? address['suburb'] ?? '').toString();
                                        _stateController.text = (address['state'] ?? address['province'] ?? '').toString();
                                        _countryController.text = (address['country'] ?? '').toString();
                                        _countyController.text = (address['county'] ?? '').toString();
                                        _postalCodeController.text = (address['postcode'] ?? address['postal_code'] ?? '').toString();
                                        
                                        String? detDistrict = (address['state_district'] ?? address['district'] ?? address['county'] ?? '').toString();
                                        if (detDistrict != null && detDistrict.isNotEmpty) {
                                          detDistrict = detDistrict.replaceAll(' District', '').trim();
                                          try {
                                            final matched = _keralaDistricts.firstWhere(
                                              (d) => d.toLowerCase() == detDistrict!.toLowerCase(),
                                              orElse: () => _selectedDistrict ?? _keralaDistricts.first,
                                            );
                                            _selectedDistrict = matched;
                                            _districtController.text = matched;
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
                              icon: Icons.gps_fixed_rounded,
                              label: 'Detect GPS',
                              colors: [AppColors.deepEmerald, AppColors.deepEmerald],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                    
                    TextFormField(
                      controller: _cityController,
                      textInputAction: TextInputAction.search,
                      onFieldSubmitted: (_) => _triggerCityLookup(),
                      decoration: _buildModernInputDecoration(
                        label: 'Home City',
                        icon: Icons.home_rounded,
                        helperText: 'Tap icon to auto-fill location details',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.travel_explore, color: AppColors.deepEmerald),
                          onPressed: _triggerCityLookup,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _presentCityController,
                      decoration: _buildModernInputDecoration(
                        label: 'Present City (if different)',
                        icon: Icons.location_city_rounded,
                        hint: 'e.g. Dubai, London etc.',
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _presentCountryController,
                      decoration: _buildModernInputDecoration(
                        label: 'Present Country (if different)',
                        icon: Icons.public_rounded,
                        hint: 'e.g. UAE, UK etc.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _districtController,
                      readOnly: true,
                      onTap: () => _openSearchablePicker(
                        title: 'District',
                        items: _keralaDistricts,
                        controller: _districtController,
                        onSelected: (item) {
                          setState(() {
                            _selectedDistrict = item.toString();
                          });
                        },
                      ),
                      decoration: _buildModernInputDecoration(
                        label: 'District',
                        icon: Icons.map_rounded,
                        suffixIcon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.deepEmerald),
                      ),
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
                      readOnly: true,
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
                            readOnly: true,
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
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppColors.divider),
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
                        activeColor: AppColors.deepEmerald,
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
                    if (_personalities.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      InkWell(
                        onTap: () => setState(() => _isPersonalitiesExpanded = !_isPersonalitiesExpanded),
                        borderRadius: BorderRadius.circular(10),
                        child: _buildSectionHeader(
                          'User Personality', 
                          Icons.psychology_rounded,
                          trailing: Icon(
                            _isPersonalitiesExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                            color: AppColors.deepEmerald,
                          ),
                        ),
                      ),
                      if (_isPersonalitiesExpanded) _buildPersonalityMultiSelect(),
                    ],
                    if (_interests.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      InkWell(
                        onTap: () => setState(() => _isInterestsExpanded = !_isInterestsExpanded),
                        borderRadius: BorderRadius.circular(10),
                        child: _buildSectionHeader(
                          'Interests & Hobbies', 
                          Icons.sports_tennis_rounded,
                          trailing: Icon(
                            _isInterestsExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                            color: AppColors.deepEmerald,
                          ),
                        ),
                      ),
                      if (_isInterestsExpanded) _buildInterestMultiSelect(),
                    ],

                    const SizedBox(height: 40),
                    _buildSectionHeader('Profile Links', Icons.link_rounded),
                    
                    _buildActionButton(
                      label: 'Family Details',
                      icon: Icons.family_restroom_rounded,
                      gradient: const [AppColors.deepEmerald, AppColors.deepEmerald],
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FamilyDetailsScreen())),
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      label: 'Edit Preferences',
                      icon: Icons.settings_rounded,
                      gradient: const [AppColors.deepEmerald, AppColors.deepEmerald],
                      onPressed: () => Navigator.pushNamed(context, '/preferences'),
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      label: 'Manage Photos',
                      icon: Icons.photo_library_rounded,
                      gradient: const [AppColors.primaryGreen, AppColors.darkGreen],
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.white70.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [AppColors.deepEmerald, AppColors.deepEmerald],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.deepEmerald.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: AppColors.cardDark, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Update Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ),
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
        icon: Icon(icon, color: AppColors.cardDark, size: 20),
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

  Widget _buildPersonalityMultiSelect() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _personalities.map((dynamic p) {
              final int pId = int.parse(p['id'].toString());
              final isSelected = _selectedPersonalityIds.contains(pId);
              return FilterChip(
                label: Text(
                  p['personality_name'].toString(),
                  style: TextStyle(
                    color: isSelected ? AppColors.deepEmerald : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _selectedPersonalityIds.add(pId);
                    } else {
                      _selectedPersonalityIds.remove(pId);
                    }
                  });
                },
                selectedColor: AppColors.deepEmerald.withOpacity(0.1),
                checkmarkColor: AppColors.deepEmerald,
                backgroundColor: AppColors.offWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? AppColors.deepEmerald : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestMultiSelect() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _interests.map((dynamic i) {
              final int iId = int.parse(i['id'].toString());
              final isSelected = _selectedInterestIds.contains(iId);
              return FilterChip(
                label: Text(
                  i['interest_name'].toString(),
                  style: TextStyle(
                    color: isSelected ? AppColors.deepEmerald : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _selectedInterestIds.add(iId);
                    } else {
                      _selectedInterestIds.remove(iId);
                    }
                  });
                },
                selectedColor: AppColors.deepEmerald.withOpacity(0.1),
                checkmarkColor: AppColors.deepEmerald,
                backgroundColor: AppColors.offWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? AppColors.deepEmerald : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required List<Color> colors,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ],
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














