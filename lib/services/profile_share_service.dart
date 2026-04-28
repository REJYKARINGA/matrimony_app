import 'dart:io' if (dart.library.html) 'package:matrimony_app/services/io_stub.dart' as io;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class ProfileShareService {
  static final ScreenshotController screenshotController = ScreenshotController();

  static Future<void> shareProfile(BuildContext context, User user) async {
    final profile = user.userProfile;
    if (profile == null) return;

    final String name = '${profile.firstName ?? ''} ${profile.lastName ?? ''}'.trim();
    final String matrimonyId = user.matrimonyId ?? 'N/A';
    final String age = '${profile.age ?? 'N/A'} yrs';
    final String height = profile.height != null ? '${profile.height} cm' : 'N/A';
    final String location = '${profile.city ?? ''}, ${profile.state ?? ''}'.trim();
    final String job = profile.occupation ?? 'N/A';
    final String education = profile.education ?? 'N/A';
    final String religion = profile.religion ?? 'N/A';
    final String caste = profile.caste ?? 'N/A';

    // 1. Prepare Text Summary for WhatsApp
    final String shareText = """
🌟 *Profile from Vivah Matrimony* 🌟

*Name:* $name ($matrimonyId)
*Age/Height:* $age, $height
*Community:* $religion, $caste
*Education:* $education
*Profession:* $job
*Location:* $location

Check out this profile on Vivah Matrimony app!
""";

    try {
      // 2. Generate Image (Using a hidden widget)
      final Uint8List? imageBytes = await screenshotController.captureFromWidget(
        Material(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00A87D), Color(0xFF00A87D)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    const Text(
                      'VIVAH MATRIMONY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                
                // Profile Photo & Name
                Row(
                  children: [
                    Container(
                      width: 100,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: user.displayImage != null
                            ? Image.network(
                                ApiService.getImageUrl(user.displayImage!),
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  color: Colors.white.withOpacity(0.1),
                                  child: const Icon(Icons.person, color: Colors.white, size: 50),
                                ),
                              )
                            : Container(
                                color: Colors.white.withOpacity(0.1),
                                child: const Icon(Icons.person, color: Colors.white, size: 50),
                              ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              matrimonyId,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                
                // Details Grid
                _buildInfoRow(Icons.calendar_today, 'Age & Height', '$age, $height'),
                _buildInfoRow(Icons.groups, 'Religion & Caste', '$religion, $caste'),
                _buildInfoRow(Icons.school, 'Education', education),
                _buildInfoRow(Icons.work, 'Profession', job),
                _buildInfoRow(Icons.location_on, 'Location', location),
                
                const SizedBox(height: 30),
                const Divider(color: Colors.white54),
                const SizedBox(height: 10),
                const Text(
                  'Contact Vivah Matrimony to connect!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
        delay: const Duration(milliseconds: 200), // Increased delay for image loading
      );

      if (imageBytes != null && !kIsWeb) {
        final directory = await getTemporaryDirectory();
        final imageFile = io.File('${directory.path}/shared_profile_${DateTime.now().millisecondsSinceEpoch}.png');
        await imageFile.writeAsBytes(imageBytes);

        // 3. Share Image + Text
        await Share.shareXFiles(
          [XFile(imageFile.path)],
          text: shareText,
        );
      } else {
        // Fallback to text only if image generation fails or on Web
        await Share.share(shareText);
      }
    } catch (e) {
      print('Error sharing profile: $e');
      // Fallback to text only
      await Share.share(shareText);
    }
  }

  static Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white60, 
                    fontSize: 10, 
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 14, 
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



