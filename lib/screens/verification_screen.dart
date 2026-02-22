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
      imageQuality: 70,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verify Account', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: NotificationListener<UserScrollNotification>(
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
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 30),
                  if (_verificationStatus == null || _verificationStatus!['status'] == 'rejected') ...[
                    const Text(
                      'Account Verification',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload your identity proof to verify your account and build trust with others.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
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
        color = const Color(0xFF00BCD4); // Turquoise from main theme
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
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
          const Text('Select ID Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedIdType,
                isExpanded: true,
                items: _idTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) => setState(() => _selectedIdType = val!),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('ID Number (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _idNumberController,
            decoration: InputDecoration(
              hintText: 'Enter ID Number',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4), // Turquoise from main theme
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
        Text(isFront ? 'Front Side' : 'Back Side', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _pickImage(isFront),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
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
                      Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade400, size: 32),
                      const SizedBox(height: 8),
                      Text('Upload Photo', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
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
          Icon(Icons.access_time_filled_rounded, color: const Color(0xFF00BCD4).withOpacity(0.3), size: 100), // Turquoise from main theme
          const SizedBox(height: 24),
          const Text('Checking Documents', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            'We are reviewing your documents. This usually takes 24-48 hours. We will notify you once verified.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
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
          const Text('Verified Account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            'Your account is verified. You now have a verification badge on your profile.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
        ],
      ),
    );
  }
}