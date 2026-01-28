import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class VerificationService {
  static String get verificationUrl => '${ApiService.baseUrl}/verification';

  static Future<http.Response> submitVerification({
    required String idProofType,
    String? idProofNumber,
    required XFile frontImage,
    XFile? backImage,
  }) async {
    String? token = await ApiService.getToken();

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$verificationUrl/submit'),
    );

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['id_proof_type'] = idProofType;
    if (idProofNumber != null) {
      request.fields['id_proof_number'] = idProofNumber;
    }

    // Add front image
    final frontBytes = await frontImage.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes(
        'id_proof_front',
        frontBytes,
        filename: frontImage.name,
      ),
    );

    // Add back image if exists
    if (backImage != null) {
      final backBytes = await backImage.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'id_proof_back',
          backBytes,
          filename: backImage.name,
        ),
      );
    }

    var streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  static Future<http.Response> getVerificationStatus() async {
    return await ApiService.makeRequest('$verificationUrl/status');
  }
}
