import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';

class EngagementPosterInfoScreen extends StatefulWidget {
  const EngagementPosterInfoScreen({super.key});

  @override
  State<EngagementPosterInfoScreen> createState() =>
      _EngagementPosterInfoScreenState();
}

class _EngagementPosterInfoScreenState
    extends State<EngagementPosterInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _partnerMatrimonyIdController = TextEditingController();
  
  Map<String, dynamic>? _existingPoster;
  bool _isLoading = true;

  XFile? _posterImage;
  DateTime? _engagementDate;
  DateTime? _displayExpireAt;
  bool _isActive = true;
  bool _softDelete = false;
  bool _isVerified = false;
  String? _partnerPhotoUrl;
  String? _ownPhotoUrl;
  bool _isOwner = true;

  final ImagePicker _picker = ImagePicker();

  // Design Tokens - Matching the Gray-White premium theme
  static const Color primaryCyan = Color(0xFF00BCD4);
  static const Color backgroundGray = Color(0xFFF5F7F9);
  static const Color cardGray = Color(0xFFF9FAFB);
  static const Color textBlack = Color(0xFF1A1A1A);
  static const Color accentGreen = Color(0xFF4CD9A6);

  @override
  void initState() {
    super.initState();
    _fetchMyPoster();
  }

  Future<void> _fetchMyPoster() async {
    try {
      final response = await ApiService.getMyEngagementPoster();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _existingPoster = data['engagement_poster'];
          _partnerPhotoUrl = data['partner_primary_photo'];
          _ownPhotoUrl = data['user_primary_photo'];
          _isOwner = data['is_owner'] ?? true;
        });
      }
    } catch (e) {
      debugPrint('Error fetching my poster: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _partnerMatrimonyIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: primaryCyan),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 1920,
                  maxHeight: 1920,
                  imageQuality: 85,
                );
                if (image != null) {
                  setState(() {
                    _posterImage = image;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: primaryCyan),
              title: const Text('Take a Photo'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 1920,
                  maxHeight: 1920,
                  imageQuality: 85,
                );
                if (image != null) {
                  setState(() {
                    _posterImage = image;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isEngagement) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: isEngagement ? DateTime(2000) : DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryCyan,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isEngagement) {
          _engagementDate = picked;
        } else {
          _displayExpireAt = picked;
        }
      });
    }
  }

  Future<void> _submitForm(BuildContext context) async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    final bool isUpdate = _existingPoster != null;

    if (_formKey.currentState!.validate()) {
      // Only require image if creating a new poster (when updating, existing image is kept)
      if (!isUpdate && _posterImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload an engagement poster image'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (_engagementDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your engagement date'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Row(
                children: [
                  const CircularProgressIndicator(color: primaryCyan),
                  const SizedBox(width: 20),
                  Text(isUpdate ? 'Updating engagement poster...' : 'Uploading engagement poster...'),
                ],
              ),
            );
          },
        );

        // Prepare form data for API
        final formData = {
          'engagement_date': _engagementDate!.toIso8601String(),
          'announcement_title': _titleController.text,
          'announcement_message': _messageController.text,
          'partner_matrimony_id': _partnerMatrimonyIdController.text,
          'is_active': _isActive,
          'display_expire_at': _displayExpireAt?.toIso8601String(),
        };

        http.Response response;

        if (isUpdate) {
          // Update existing poster - image is optional
          response = await ApiService.updateEngagementPoster(
            _existingPoster!['id'],
            formData,
            imageBytes: _posterImage != null ? await _posterImage!.readAsBytes() : null,
            fileName: _posterImage?.name,
          );
        } else {
          // Create new poster - image is required (already validated above)
          response = await ApiService.createEngagementPoster(
            formData,
            await _posterImage!.readAsBytes(),
            _posterImage!.name,
          );
        }

        // Close loading dialog
        Navigator.of(context).pop();

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Close the bottom sheet
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isUpdate ? 'Engagement poster updated successfully!' : 'Engagement poster uploaded successfully!'),
              backgroundColor: accentGreen,
            ),
          );

          // Clear form
          _titleController.clear();
          _messageController.clear();
          _partnerMatrimonyIdController.clear();
          setState(() {
            _posterImage = null;
            _engagementDate = null;
            _displayExpireAt = null;
            _isActive = true;
          });
          
          // Refresh the page data
          _fetchMyPoster();
        } else {
          String errorMessage = isUpdate ? 'Failed to update engagement poster' : 'Failed to upload engagement poster';
          try {
            final data = json.decode(response.body);
            // Handle Laravel validation errors object
            if (data['errors'] != null && data['errors'] is Map) {
              final Map<String, dynamic> errors = data['errors'];
              if (errors.isNotEmpty) {
                final firstError = errors.values.first;
                if (firstError is List && firstError.isNotEmpty) {
                  errorMessage = firstError[0].toString();
                } else {
                  errorMessage = firstError.toString();
                }
              }
            } else {
              // Show 'reason' if present (partner already confirmed), otherwise fall back to 'message' or 'error'
              errorMessage = data['reason'] ?? data['message'] ?? data['error'] ?? errorMessage;
            }
          } catch (e) {
            // If parsing fails, use default message
          }

          // Show error in a dialog instead of SnackBar because SnackBar appears behind the bottom sheet
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Validation Error', style: TextStyle(color: Colors.red)),
              content: Text(errorMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK', style: TextStyle(color: primaryCyan)),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Error', style: TextStyle(color: Colors.red)),
            content: Text('Error: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK', style: TextStyle(color: primaryCyan)),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildInfoCard(IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryCyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryCyan, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadForm() {
    final bool isUpdate = _existingPoster != null;

    // Pre-fill controllers with existing values when updating
    if (isUpdate) {
      _titleController.text = _existingPoster!['announcement_title'] ?? '';
      _messageController.text = _existingPoster!['announcement_message'] ?? '';
      _partnerMatrimonyIdController.text = _existingPoster!['partner_matrimony_id'] ?? '';
      // Pre-fill engagement date
      final engagementDateStr = _existingPoster!['engagement_date'];
      if (engagementDateStr != null) {
        _engagementDate = DateTime.tryParse(engagementDateStr);
      }
      // Pre-fill expire date
      final expireDateStr = _existingPoster!['display_expire_at'];
      if (expireDateStr != null) {
        _displayExpireAt = DateTime.tryParse(expireDateStr);
      }
      _isActive = _existingPoster!['is_active'] == true;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      isUpdate ? 'Update Engagement Poster' : 'Upload Engagement Poster',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Form content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Image Upload Section
                        GestureDetector(
                          onTap: () async {
                            await _pickImage();
                            setModalState(() {});
                          },
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: _posterImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        kIsWeb
                                            ? Image.network(
                                                _posterImage!.path,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.file(
                                                File(_posterImage!.path),
                                                fit: BoxFit.cover,
                                              ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: CircleAvatar(
                                            backgroundColor: primaryCyan,
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              onPressed: () async {
                                                await _pickImage();
                                                setModalState(() {});
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : (isUpdate && _existingPoster!['poster_image'] != null)
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.network(
                                              ApiService.getImageUrl(_existingPoster!['poster_image']),
                                              fit: BoxFit.cover,
                                              errorBuilder: (ctx, err, st) => Container(
                                                color: Colors.grey[200],
                                                child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                              ),
                                            ),
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: CircleAvatar(
                                                backgroundColor: primaryCyan,
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  onPressed: () async {
                                                    await _pickImage();
                                                    setModalState(() {});
                                                  },
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 8,
                                              left: 8,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'Tap ✏️ to change photo',
                                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Upload Engagement Poster',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Tap to select or capture',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Engagement Date
                        Text(
                          'Engagement Date *',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            await _selectDate(context, true);
                            setModalState(() {});
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: primaryCyan),
                                const SizedBox(width: 12),
                                Text(
                                  _engagementDate != null
                                      ? '${_engagementDate!.day}/${_engagementDate!.month}/${_engagementDate!.year}'
                                      : 'Select engagement date',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _engagementDate != null
                                        ? Colors.black87
                                        : Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Announcement Title
                        Text(
                          'Announcement Title *',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            hintText: 'e.g., We\'re Engaged!',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: primaryCyan,
                                width: 2,
                              ),
                            ),
                            prefixIcon: const Icon(Icons.title, color: primaryCyan),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter announcement title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Announcement Message
                        Text(
                          'Announcement Message *',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Share your joy with everyone...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: primaryCyan,
                                width: 2,
                              ),
                            ),
                            prefixIcon: const Icon(
                              Icons.message,
                              color: primaryCyan,
                            ),
                          ),
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter announcement message';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Partner Matrimony ID
                        Text(
                          'Partner Matrimony ID *',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _partnerMatrimonyIdController,
                          decoration: InputDecoration(
                            hintText: 'e.g., VE123456',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: primaryCyan,
                                width: 2,
                              ),
                            ),
                            prefixIcon: const Icon(
                              Icons.favorite,
                              color: primaryCyan,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter partner Matrimony ID';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Display Expire Date
                        Text(
                          'Display Until (Optional)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            await _selectDate(context, false);
                            setModalState(() {});
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event_busy, color: primaryCyan),
                                const SizedBox(width: 12),
                                Text(
                                  _displayExpireAt != null
                                      ? '${_displayExpireAt!.day}/${_displayExpireAt!.month}/${_displayExpireAt!.year}'
                                      : 'Select expiry date (optional)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _displayExpireAt != null
                                        ? Colors.black87
                                        : Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Switches
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              SwitchListTile(
                                title: const Text(
                                  'Active Status',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: const Text(
                                  'Enable to make poster visible',
                                  style: TextStyle(fontSize: 13),
                                ),
                                value: _isActive,
                                activeColor: primaryCyan,
                                onChanged: (value) {
                                  setState(() {
                                    _isActive = value;
                                  });
                                  setModalState(() {});
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: primaryCyan,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: () => _submitForm(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isUpdate ? 'Update Engagement Poster' : 'Upload Engagement Poster',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGray,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: backgroundGray,
            centerTitle: true,
            elevation: 0,
            titleTextStyle: const TextStyle(
              color: textBlack,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            iconTheme: const IconThemeData(color: textBlack),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Engagement Posters'),
              background: Container(
                color: backgroundGray,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryCyan.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.celebration_rounded,
                      size: 48,
                      color: primaryCyan,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Introduction Card with gradient
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardGray,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Celebrate Your Love Story',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Share the beautiful moment of your engagement with friends, family, and your community. Create lasting memories and announce your special journey together.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Why Add a Poster Section
                  Text(
                    'Why Add an Engagement Poster?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildInfoCard(
                    Icons.celebration,
                    'Celebrate Together',
                    'Share the joy of your engagement with your community and let everyone celebrate this beautiful milestone with you.',
                  ),
                  _buildInfoCard(
                    Icons.notifications_active,
                    'Official Announcement',
                    'Make a formal announcement of your engagement and upcoming wedding plans to friends and family.',
                  ),
                  _buildInfoCard(
                    Icons.people,
                    'Community Connection',
                    'Stay connected with well-wishers and receive blessings and congratulations from your community.',
                  ),
                  _buildInfoCard(
                    Icons.photo_camera,
                    'Preserve Memories',
                    'Create a beautiful digital keepsake of this special time that you can cherish forever.',
                  ),
                  _buildInfoCard(
                    Icons.event,
                    'Share Details',
                    'Inform others about your engagement celebration, wedding dates, and other important details.',
                  ),
                  _buildInfoCard(
                    Icons.verified,
                    'Professional Display',
                    'Present your announcement professionally with active status indicators.',
                  ),

                  const SizedBox(height: 32),

                  // How It Works Section
                  Text(
                    'How It Works',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardGray,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildStep(
                          1,
                          'Upload Your Poster',
                          'Select a beautiful photo from your gallery or capture a new one',
                        ),
                        _buildStep(
                          2,
                          'Add Details',
                          'Fill in your engagement date, title, and announcement message',
                        ),
                        _buildStep(
                          3,
                          'Set Preferences',
                          'Choose visibility options and expiry date if needed',
                        ),
                        _buildStep(
                          4,
                          'Publish',
                          'Submit your poster for verification and sharing',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Features Section
                  Text(
                    'Poster Features',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildFeatureChip(Icons.visibility, 'Visibility Control'),
                      _buildFeatureChip(Icons.timer, 'Custom Expiry'),
                      _buildFeatureChip(Icons.edit, 'Easy Updates'),
                      _buildFeatureChip(Icons.share, 'Social Sharing'),
                      _buildFeatureChip(Icons.lock, 'Privacy Options'),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Show loader, existing poster, or upload button
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator(color: primaryCyan))
                  else if (_existingPoster != null)
                    _buildExistingPosterCard()
                  else
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: primaryCyan,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryCyan.withOpacity(0.25),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _showUploadForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.cloud_upload, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Upload Engagement Poster',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(
    int number,
    String title,
    String description, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primaryCyan.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: primaryCyan.withOpacity(0.2), width: 1.5),
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: primaryCyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 15, top: 8, bottom: 8),
            child: Container(width: 2, height: 30, color: Colors.grey[300]),
          ),
      ],
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: primaryCyan.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryCyan.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: primaryCyan),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primaryCyan,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagedProfiles() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 100,
            width: 160,
            child: Stack(
              children: [
                // User Photo (Left)
                Positioned(
                  left: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: primaryCyan.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _ownPhotoUrl != null ? NetworkImage(_ownPhotoUrl!) : null,
                      child: _ownPhotoUrl == null ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
                    ),
                  ),
                ),
                // Partner Photo (Right)
                Positioned(
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: primaryCyan.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _partnerPhotoUrl != null ? NetworkImage(_partnerPhotoUrl!) : null,
                      child: _partnerPhotoUrl == null ? const Icon(Icons.favorite_border, size: 40, color: Colors.grey) : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Ring/Heart badge in middle
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
                ],
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.redAccent,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingPosterCard() {
    final posterImageUrl = _existingPoster?['poster_image'];
    final partnerId = _existingPoster?['partner_matrimony_id'] ?? 'N/A';
    final partnerStatus = _existingPoster?['partner_status'] ?? 'pending';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (posterImageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                ApiService.getImageUrl(posterImageUrl),
                fit: BoxFit.cover,
                height: 250,
                errorBuilder: (context, error, stackTrace) =>
                    Container(height: 200, color: Colors.grey[200]),
              ),
            ),
          
          // New Engaged Design
          _buildEngagedProfiles(),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _existingPoster?['announcement_title'] ?? 'Engagement Announcement',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _existingPoster?['announcement_message'] ?? '',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Partner ID:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Row(
                      children: [
                        if (_partnerPhotoUrl != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundImage: NetworkImage(_partnerPhotoUrl!),
                            ),
                          ),
                        Text(
                          partnerId,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryCyan,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Partner Confirmation:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: partnerStatus == 'confirmed'
                            ? Colors.green[100]
                            : partnerStatus == 'rejected'
                                ? Colors.red[100]
                                : Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        partnerStatus.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: partnerStatus == 'confirmed'
                              ? Colors.green[800]
                              : partnerStatus == 'rejected'
                                  ? Colors.red[800]
                                  : Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Verification Status:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (_existingPoster?['is_verified'] == true || _existingPoster?['is_verified'] == 1)
                            ? primaryCyan.withOpacity(0.15)
                            : Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_existingPoster?['is_verified'] == true || _existingPoster?['is_verified'] == 1)
                            const Icon(Icons.verified, size: 14, color: primaryCyan),
                          if (_existingPoster?['is_verified'] == true || _existingPoster?['is_verified'] == 1)
                            const SizedBox(width: 4),
                          Text(
                            (_existingPoster?['is_verified'] == true || _existingPoster?['is_verified'] == 1) ? 'VERIFIED' : 'PENDING',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: (_existingPoster?['is_verified'] == true || _existingPoster?['is_verified'] == 1)
                                  ? primaryCyan
                                  : Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Add Edit/Update button conditionally if not confirmed and not verified
                if (_isOwner && partnerStatus != 'confirmed' && !(_existingPoster?['is_verified'] == true || _existingPoster?['is_verified'] == 1)) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: partnerStatus == 'rejected' ? Colors.red[600] : primaryCyan,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: _showUploadForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(partnerStatus == 'rejected' ? Icons.refresh : Icons.edit, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            partnerStatus == 'rejected' ? 'Re-upload Poster' : 'Update Poster',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Partner Accept/Reject buttons
                if (!_isOwner && partnerStatus == 'pending') ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _respondToPoster('confirmed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Accept Engagement', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _respondToPoster('rejected'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _respondToPoster(String status) async {
    final posterId = _existingPoster?['id'];
    if (posterId == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.respondToEngagementPoster(posterId, status);
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Engagement $status successfully')),
          );
          _fetchMyPoster();
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to $status engagement. Please try again.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
              ],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error responding to poster: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}