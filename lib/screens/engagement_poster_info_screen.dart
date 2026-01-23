import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
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

  File? _posterImage;
  DateTime? _engagementDate;
  DateTime? _displayExpireAt;
  bool _isActive = true;
  bool _softDelete = false;
  bool _isVerified = false;

  final ImagePicker _picker = ImagePicker();

  // Gradient colors from login page
  static const Color gradientPurple = Color(0xFFB47FFF);
  static const Color gradientBlue = Color(0xFF5CB3FF);
  static const Color gradientGreen = Color(0xFF4CD9A6);

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
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
                    _posterImage = File(image.path);
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
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
                    _posterImage = File(image.path);
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
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.light(primary: gradientBlue)),
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_posterImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload an engagement poster image'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_engagementDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your engagement date'),
            backgroundColor: Colors.red,
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
            return const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Uploading engagement poster..."),
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
          'is_active': _isActive,
          'display_expire_at': _displayExpireAt?.toIso8601String(),
        };

        // Call the API to create engagement poster
        final response = await ApiService.createEngagementPoster(
          formData,
          _posterImage!,
        );

        // Close loading dialog
        Navigator.of(context).pop();

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Engagement poster uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Clear form
          _titleController.clear();
          _messageController.clear();
          setState(() {
            _posterImage = null;
            _engagementDate = null;
            _displayExpireAt = null;
            _isActive = true;
          });
        } else {
          String errorMessage = 'Failed to upload engagement poster';
          try {
            final data = json.decode(response.body);
            errorMessage =
                data['message'] ??
                data['error'] ??
                'Failed to upload engagement poster';
          } catch (e) {
            // If parsing fails, use default message
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading engagement poster: $e'),
            backgroundColor: Colors.red,
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
              color: gradientPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: gradientPurple, size: 24),
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
                    const Text(
                      'Upload Engagement Poster',
                      style: TextStyle(
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
                                        Image.file(
                                          _posterImage!,
                                          fit: BoxFit.cover,
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: CircleAvatar(
                                            backgroundColor: Colors.black54,
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
                          onTap: () => _selectDate(context, true),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: gradientBlue),
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
                              borderSide: BorderSide(
                                color: gradientBlue,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(Icons.title, color: gradientBlue),
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
                              borderSide: BorderSide(
                                color: gradientBlue,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.message,
                              color: gradientBlue,
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
                          onTap: () {
                            _selectDate(context, false);
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
                                Icon(Icons.event_busy, color: gradientBlue),
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
                                activeColor: gradientBlue,
                                onChanged: (value) {
                                  setModalState(() {
                                    _isActive = value;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Submit Button with gradient
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [gradientPurple, gradientBlue],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Upload Engagement Poster',
                              style: TextStyle(
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
      body: CustomScrollView(
        slivers: [
          // Hero Header with login gradient
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: gradientPurple,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Engagement Posters',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient background matching login
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [gradientPurple, gradientBlue, gradientGreen],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  // Decorative pattern
                  Positioned(
                    right: -50,
                    top: 50,
                    child: Icon(
                      Icons.favorite,
                      size: 200,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: 30,
                    child: Icon(
                      Icons.favorite,
                      size: 120,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  // Centered icon
                  Center(
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Icon(
                        Icons.celebration,
                        size: 80,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
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
                      gradient: LinearGradient(
                        colors: [
                          gradientPurple.withOpacity(0.15),
                          gradientBlue.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: gradientPurple.withOpacity(0.3),
                      ),
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
                    padding: const EdgeInsets.all(20),
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

                  // Upload Button with gradient
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [gradientPurple, gradientBlue],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: gradientPurple.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
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
                gradient: const LinearGradient(
                  colors: [gradientPurple, gradientBlue],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.white,
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
        color: gradientPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gradientPurple.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: gradientPurple),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: gradientPurple,
            ),
          ),
        ],
      ),
    );
  }
}
