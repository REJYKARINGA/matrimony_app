import '../../../../../../utils/app_colors.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../services/verification_service.dart';
import '../services/api_service.dart';

import '../widgets/common_footer.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../services/navigation_provider.dart';
import '../utils/app_colors.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {

  final _formKey = GlobalKey<FormState>();
  String _selectedIdType = 'Aadhar Card';
  final _idNumberController = TextEditingController();
  XFile? _frontImage;
  XFile? _backImage;
  bool _isLoading = false;
  Map<String, dynamic>? _verificationStatus;

  final List<String> _idTypes = [
    'Aadhar Card',
    'Voter ID',
    'Driving License',
    'Passport',
    'PAN Card',
  ];

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    setState(() => _isLoading = true);
    try {
      final response = await VerificationService.getVerificationStatus();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _verificationStatus = data['verification'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching verification status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(bool isFront) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 1200,
      maxHeight: 1200,
    );

    if (image != null) {
      setState(() {
        if (isFront) {
          _frontImage = image;
        } else {
          _backImage = image;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_frontImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload front side of ID proof')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await VerificationService.submitVerification(
        idProofType: _selectedIdType,
        idProofNumber: _idNumberController.text,
        frontImage: _frontImage!,
        backImage: _backImage,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID proof submitted for verification')),
        );
        _fetchStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission failed. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Verify Account', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Design
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(
                'assets/images/splash_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, st) => Container(),
              ),
            ),
          ),
          NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              final navProvider = Provider.of<NavigationProvider>(context, listen: false);
              if (notification.direction == ScrollDirection.reverse) {
                navProvider.setFooterVisible(false);
              } else if (notification.direction == ScrollDirection.forward) {
                navProvider.setFooterVisible(true);
              }
              return true;
            },
            child: _isLoading && _verificationStatus == null
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 30),
                      if (_verificationStatus == null || _verificationStatus!['status'] == 'rejected') ...[
                        const Text(
                          'Account Verification',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textDark, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Upload your identity proof to verify your account and build trust with others in our community.',
                          style: TextStyle(color: AppColors.mutedText, fontSize: 16, height: 1.5),
                        ),
                        const SizedBox(height: 30),
                        _buildForm(),
                      ] else if (_verificationStatus!['status'] == 'pending') ...[
                         _buildPendingView(),
                      ] else if (_verificationStatus!['status'] == 'verified') ...[
                         _buildVerifiedView(),
                      ],
                    ],
                ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Consumer<NavigationProvider>(
        builder: (context, navProvider, child) => AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          offset: navProvider.isFooterVisible ? Offset.zero : const Offset(0, 2),
          child: const CommonFooter(),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    if (_verificationStatus == null) return const SizedBox.shrink();

    final status = _verificationStatus!['status'];
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case 'verified':
        color = Colors.green;
        icon = Icons.verified_rounded;
        text = 'Account Verified';
        break;
      case 'pending':
        color = AppColors.deepEmerald; // Turquoise from main theme
        icon = Icons.hourglass_empty_rounded;
        text = 'Verification Pending';
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel_rounded;
        text = 'Verification Rejected';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
                if (status == 'rejected' && _verificationStatus!['rejection_reason'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Reason: ${_verificationStatus!['rejection_reason']}', style: TextStyle(color: color.withOpacity(0.8), fontSize: 13)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select ID Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textDark)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.deepEmerald.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.deepEmerald.withOpacity(0.1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedIdType,
                isExpanded: true,
                dropdownColor: Colors.white,
                style: const TextStyle(color: AppColors.textDark, fontSize: 15),
                items: _idTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) => setState(() => _selectedIdType = val!),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('ID Number (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textDark)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _idNumberController,
            style: const TextStyle(color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: 'Enter ID Number',
              hintStyle: const TextStyle(color: AppColors.mutedText),
              filled: true,
              fillColor: AppColors.deepEmerald.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.deepEmerald.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.deepEmerald),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(child: _buildImagePicker(true)),
              const SizedBox(width: 16),
              Expanded(child: _buildImagePicker(false)),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [AppColors.primaryCyan, AppColors.primaryBlue],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryCyan.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: AppColors.cardDark)
                    : const Text('Submit Verification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.cardDark)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker(bool isFront) {
    XFile? image = isFront ? _frontImage : _backImage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isFront ? 'Front Side' : 'Back Side', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textDark)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _pickImage(isFront),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider.withOpacity(0.8), style: BorderStyle.solid),
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.network(image.path, fit: BoxFit.cover, width: double.infinity)
                        : Image.network(image.path, fit: BoxFit.cover, width: double.infinity),
                        // Note: For real app use FileImage on mobile
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: AppColors.deepEmerald.withOpacity(0.5), size: 32),
                      const SizedBox(height: 8),
                      const Text('Upload Photo', style: TextStyle(color: AppColors.deepEmerald, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingView() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.access_time_filled_rounded, color: AppColors.deepEmerald.withOpacity(0.3), size: 100),
          const SizedBox(height: 24),
          const Text('Checking Documents', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 12),
          const Text(
            'We are reviewing your documents. This usually takes 24-48 hours. We will notify you once verified.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedText, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedView() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.verified_user_rounded, color: Colors.green, size: 100),
          const SizedBox(height: 24),
          const Text('Verified Account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 12),
          const Text(
            'Your account is verified. You now have a verification badge on your profile.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedText, fontSize: 15),
          ),
        ],
      ),
    );
  }
}














