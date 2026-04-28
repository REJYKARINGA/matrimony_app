import '../../../../../../utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // For kIsWeb
import '../services/profile_service.dart';
import '../services/api_service.dart';
import '../widgets/watermark_overlay.dart';
import '../utils/app_colors.dart';

class ProfilePhotosScreen extends StatefulWidget {
  const ProfilePhotosScreen({Key? key}) : super(key: key);

  @override
  State<ProfilePhotosScreen> createState() => _ProfilePhotosScreenState();
}

class _ProfilePhotosScreenState extends State<ProfilePhotosScreen> {
  List<dynamic> _photos = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isUploading = false;
  bool _hidePhotos = false;
  bool _isUpdatingPrivacy = false;

  @override
  void initState() {
    super.initState();
    _loadProfilePhotos();
  }

  Future<void> _loadProfilePhotos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ProfileService.getMyProfile();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final profilePhotos = data['user']['profile_photos'] as List?;

        if (profilePhotos != null) {
          // Sort photos so that primary is first
          List sortedPhotos = List.from(profilePhotos);
          sortedPhotos.sort((a, b) {
            if (a['is_primary'] == true) return -1;
            if (b['is_primary'] == true) return 1;
            return 0; // Keep original order for others
          });

          setState(() {
            _photos = sortedPhotos;
            _hidePhotos = data['user']['user_profile']['hide_photos'] == true || data['user']['user_profile']['hide_photos'] == 1;
            _isLoading = false;
          });
        } else {
          setState(() {
            _photos = [];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load profile photos';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading profile photos: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadPhoto() async {
    if (_photos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only upload a maximum of 5 photos. Please delete a photo to upload a new one.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _isUploading = true;
      });

      try {
        final response = await ProfileService.uploadProfilePhoto(image);

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadProfilePhotos();
        } else {
          final data = json.decode(response.body);
          String message = data['error'] ?? 'Failed to upload photo';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _setAsPrimary(int photoId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/profiles/photos/$photoId/primary'),
        headers: {
          'Authorization': 'Bearer ${await ApiService.getToken()}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Primary photo updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadProfilePhotos();
      } else {
        final data = json.decode(response.body);
        String message = data['error'] ?? 'Failed to set as primary photo';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePhoto(int photoId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Delete Photo'),
          content: const Text('Are you sure you want to delete this photo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    ).then((confirmed) async {
      if (confirmed == true) {
        setState(() {
          _isLoading = true;
        });

        try {
          final response = await http.delete(
            Uri.parse('${ApiService.baseUrl}/profiles/photos/$photoId'),
            headers: {
              'Authorization': 'Bearer ${await ApiService.getToken()}',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          );

          if (response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo deleted successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            _loadProfilePhotos();
          } else {
            final data = json.decode(response.body);
            String message = data['error'] ?? 'Failed to delete photo';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.red),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  Future<void> _toggleHidePhotos(bool value) async {
    setState(() {
      _isUpdatingPrivacy = true;
    });

    try {
      final response = await ProfileService.updateMyProfile(hidePhotos: value);

      if (response.statusCode == 200) {
        setState(() {
          _hidePhotos = value;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'Photos are now hidden' : 'Photos are now visible'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update privacy settings'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isUpdatingPrivacy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_isLoading && _photos.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.midnightEmerald,
        body: SafeArea(
          child: Column(
            children: [
              _buildGradientHeader(size, context),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.deepEmerald),
                      const SizedBox(height: 16),
                      const Text('Loading profile photos...'),
                    ],
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
        backgroundColor: AppColors.midnightEmerald,
        body: SafeArea(
          child: Column(
            children: [
              _buildGradientHeader(size, context),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.deepEmerald, AppColors.deepEmerald],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: _loadProfilePhotos,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: AppColors.cardDark,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Retry'),
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
      backgroundColor: AppColors.midnightEmerald,
      body: SafeArea(
        child: Column(
          children: [
            _buildGradientHeader(size, context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadProfilePhotos,
                color: AppColors.deepEmerald,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Manage your profile photos',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),

                      // Upload button with gradient
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.deepEmerald, AppColors.deepEmerald],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _uploadPhoto,
                          icon: _isUploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.cardDark,
                                  ),
                                )
                              : const Icon(Icons.add_a_photo),
                          label: _isUploading
                              ? const Text('Uploading...')
                              : const Text('Upload New Photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: AppColors.cardDark,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Privacy Settings
                      Card(
                        elevation: 0,
                        color: AppColors.midnightEmerald,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: AppColors.midnightEmerald),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.deepEmerald.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _hidePhotos ? Icons.visibility_off : Icons.visibility,
                                  color: AppColors.deepEmerald,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Hide My Photos',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Only matched or requested users can see',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isUpdatingPrivacy)
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
                                Switch(
                                  value: _hidePhotos,
                                  onChanged: _toggleHidePhotos,
                                  activeColor: AppColors.deepEmerald,
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Photos grid
                      if (_photos.isNotEmpty)
                        Expanded(
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1,
                                ),
                            itemCount: _photos.length,
                            itemBuilder: (context, index) {
                              final photo = _photos[index];
                              final isPrimary = photo['is_primary'] == true;

                              return Card(
                                elevation: 2,
                                color: AppColors.cardDark,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: AppColors.midnightEmerald,
                                    width: 1,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          (photo['photo_url'] != null)
                                              ? Image.network(
                                                  ApiService.getImageUrl(photo['photo_url'] ?? photo['full_photo_url']),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return const Icon(Icons.broken_image, size: 50);
                                                  },
                                                )
                                              : const Icon(Icons.image, size: 50),
                                          if (photo['photo_url'] != null || photo['full_photo_url'] != null) const WatermarkOverlay(),
                                        ],
                                      ),
                                    ),
                                    
                                    // Rejected Overlay
                                    if (photo['is_rejected'] == true || photo['is_rejected'] == 1 || photo['is_rejected'] == "1")
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white70.withOpacity(0.75),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.report_problem, color: Colors.redAccent, size: 36),
                                              const SizedBox(height: 8),
                                              const Text(
                                                'REJECTED',
                                                style: TextStyle(color: Colors.white,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 14,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                                child: Text(
                                                  photo['rejection_reason'] ?? 'This photo does not meet our guidelines',
                                                  style: const TextStyle(color: Colors.white70,
                                                    fontSize: 11,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.yellow.shade700,
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: const Text(
                                                  'Invisible to others',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                    // Pending Badge
                                    if (photo['is_verified'] != true && photo['is_verified'] != 1 && photo['is_verified'] != "1" && 
                                        photo['is_rejected'] != true && photo['is_rejected'] != 1 && photo['is_rejected'] != "1")
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.9),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(Icons.hourglass_empty, color: AppColors.cardDark, size: 12),
                                              SizedBox(width: 4),
                                              Text(
                                                'Pending',
                                                style: TextStyle(color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                    if (isPrimary)
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppColors.deepEmerald,
                                                AppColors.deepEmerald,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.white70.withOpacity(
                                                  0.2,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(
                                                Icons.star,
                                                color: AppColors.cardDark,
                                                size: 14,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Primary',
                                                style: TextStyle(color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(16),
                                            bottomRight: Radius.circular(16),
                                          ),
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.7),
                                            ],
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              if (!isPrimary && 
                                                  photo['is_rejected'] != true && 
                                                  photo['is_rejected'] != 1 && 
                                                  photo['is_rejected'] != "1")
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: Color(
                                                      0xFF00A87D,
                                                    ).withOpacity(0.9),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: IconButton(
                                                    icon: const Icon(
                                                      Icons.star_border,
                                                      color: AppColors.cardDark,
                                                      size: 20,
                                                    ),
                                                    tooltip: 'Set as Primary',
                                                    onPressed: () =>
                                                        _setAsPrimary(
                                                          photo['id'],
                                                        ),
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(
                                                          minWidth: 40,
                                                          minHeight: 40,
                                                        ),
                                                  ),
                                                ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withOpacity(
                                                    0.9,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: AppColors.cardDark,
                                                    size: 20,
                                                  ),
                                                  tooltip: 'Delete',
                                                  onPressed: () =>
                                                      _deletePhoto(photo['id']),
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(
                                                        minWidth: 40,
                                                        minHeight: 40,
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
                              );
                            },
                          ),
                        )
                      else
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.deepEmerald.withOpacity(0.2),
                                        AppColors.deepEmerald.withOpacity(0.2),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.photo_library,
                                    size: 50,
                                    color: AppColors.deepEmerald,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No photos uploaded yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Upload your first profile photo',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
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

  Widget _buildGradientHeader(Size size, BuildContext context) {
    // Find primary photo url
    String? primaryUrl;
    if (_photos.isNotEmpty) {
      final primaryPhoto = _photos.firstWhere(
        (p) => p['is_primary'] == true,
        orElse: () => null,
      );
      if (primaryPhoto != null) {
        primaryUrl = primaryPhoto['photo_url'] ?? primaryPhoto['full_photo_url'];
      }
    }

    return Container(
      width: double.infinity,
      height: size.height * 0.28, // Slightly taller for the background effect
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image with Blur/Overlay
          if (primaryUrl != null)
            Image.network(
              ApiService.getImageUrl(primaryUrl),
              fit: BoxFit.cover,
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.deepEmerald, AppColors.deepEmerald],
                ),
              ),
            ),
          if (primaryUrl != null) const WatermarkOverlay(),
            
          // Dark Gradient Overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),

          // Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardDark, width: 3), // White border
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white70.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(
                    child: Stack(
                      children: [
                        if (primaryUrl != null)
                          Image.network(
                            ApiService.getImageUrl(primaryUrl),
                            fit: BoxFit.cover,
                          ),
                        if (primaryUrl != null) const WatermarkOverlay(),
                      ],
                    ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Profile Photos',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cardDark,
                  letterSpacing: -0.5,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 2),
                      blurRadius: 4,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Show your best moments',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.cardDark.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          // Back Button
          Positioned(
            top: 10,
            left: 10,
            child: CircleAvatar(
              backgroundColor: Colors.white70.withOpacity(0.2),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.cardDark),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}














