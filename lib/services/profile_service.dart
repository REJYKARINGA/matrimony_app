import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../models/user_model.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class ProfileService {
  static Future<http.Response> getMyProfile() async {
    return await ApiService.makeRequest('${ApiService.baseUrl}/profiles/my');
  }

  static Future<http.Response> updateMyProfile({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? gender,
    int? height,
    int? weight,
    String? maritalStatus,
    int? religionId,
    int? casteId,
    int? subCasteId,
    String? motherTongue,
    String? profilePicture,
    String? bio,
    int? educationId,
    int? occupationId,
    double? annualIncome,
    String? city,
    String? district,
    String? county,
    String? state,
    String? country,
    String? postalCode,
    bool? drugAddiction,
    String? smoke,
    String? alcohol,
    List<int>? personalityIds,
  }) async {
    final body = {
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
      if (gender != null) 'gender': gender,
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (drugAddiction != null) 'drug_addiction': drugAddiction,
      if (smoke != null) 'smoke': smoke,
      if (alcohol != null) 'alcohol': alcohol,
      if (maritalStatus != null) 'marital_status': maritalStatus,
      if (religionId != null) 'religion_id': religionId,
      if (casteId != null) 'caste_id': casteId,
      if (subCasteId != null) 'sub_caste_id': subCasteId,
      if (motherTongue != null) 'mother_tongue': motherTongue,
      if (profilePicture != null) 'profile_picture': profilePicture,
      if (bio != null) 'bio': bio,
      if (educationId != null) 'education_id': educationId,
      if (occupationId != null) 'occupation_id': occupationId,
      if (annualIncome != null) 'annual_income': annualIncome,
      if (city != null) 'city': city,
      if (district != null) 'district': district,
      if (county != null) 'county': county,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (postalCode != null) 'postal_code': postalCode,
      if (personalityIds != null) 'personality_ids': personalityIds,
    };

    return await ApiService.makeRequest(
      '${ApiService.baseUrl}/profiles/my',
      method: 'PUT',
      body: body,
    );
  }

  static Future<http.Response> getUserProfile(int userId) async {
    return await ApiService.makeRequest('${ApiService.baseUrl}/profiles/$userId');
  }

  static Future<http.Response> getAllProfiles({int? page = 1}) async {
    return await ApiService.makeRequest('${ApiService.baseUrl}/profiles?page=$page');
  }

  static Future<http.Response> getFamilyDetails() async {
    // Use the existing myProfile endpoint which includes family details
    final response = await ApiService.makeRequest('${ApiService.baseUrl}/profiles/my');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final familyDetails = data['user']['family_details'];

      // Return a custom response with family details
      return http.Response(
        json.encode({'family_details': familyDetails}),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    return response;
  }

  static Future<http.Response> updateFamilyDetails({
    String? fatherName,
    String? fatherOccupation,
    String? motherName,
    String? motherOccupation,
    int? siblings,
    String? familyType,
    String? familyStatus,
    String? familyLocation,
    int? elderSister,
    int? elderBrother,
    int? youngerSister,
    int? youngerBrother,
    bool? fatherAlive,
    bool? motherAlive,
    bool? isDisabled,
    String? guardian,
    bool? show,
  }) async {
    final body = {
      if (fatherName != null) 'father_name': fatherName,
      if (fatherOccupation != null) 'father_occupation': fatherOccupation,
      if (motherName != null) 'mother_name': motherName,
      if (motherOccupation != null) 'mother_occupation': motherOccupation,
      if (siblings != null) 'siblings': siblings,
      if (familyType != null) 'family_type': familyType,
      if (familyStatus != null) 'family_status': familyStatus,
      if (familyLocation != null) 'family_location': familyLocation,
      if (elderSister != null) 'elder_sister': elderSister,
      if (elderBrother != null) 'elder_brother': elderBrother,
      if (youngerSister != null) 'younger_sister': youngerSister,
      if (youngerBrother != null) 'younger_brother': youngerBrother,
      if (fatherAlive != null) 'father_alive': fatherAlive,
      if (motherAlive != null) 'mother_alive': motherAlive,
      if (isDisabled != null) 'is_disabled': isDisabled,
      if (guardian != null) 'guardian': guardian,
      if (show != null) 'show': show,
    };

    return await ApiService.makeRequest(
      '${ApiService.baseUrl}/profiles/family',
      method: 'PUT',
      body: body,
    );
  }

  static Future<http.Response> updatePreferences({
    int? minAge,
    int? maxAge,
    int? minHeight,
    int? maxHeight,
    String? maritalStatus,
    int? religionId,
    List<int>? casteIds,
    List<int>? subCasteIds,
    List<int>? educationIds,
    List<int>? occupationIds,
    double? minIncome,
    double? maxIncome,
    int? maxDistance,
    List<String>? preferredLocations,
    String? drugAddiction,
    List<String>? smoke,
    List<String>? alcohol,
  }) async {
    final body = {
      if (minAge != null) 'min_age': minAge,
      if (maxAge != null) 'max_age': maxAge,
      if (minHeight != null) 'min_height': minHeight,
      if (maxHeight != null) 'max_height': maxHeight,
      if (maritalStatus != null) 'marital_status': maritalStatus,
      if (religionId != null) 'religion_id': religionId,
      if (casteIds != null) 'caste_ids': casteIds,
      if (subCasteIds != null) 'sub_caste_ids': subCasteIds,
      if (educationIds != null) 'education_ids': educationIds,
      if (occupationIds != null) 'occupation_ids': occupationIds,
      if (minIncome != null) 'min_income': minIncome,
      if (maxIncome != null) 'max_income': maxIncome,
      if (maxDistance != null) 'max_distance': maxDistance,
      if (preferredLocations != null) 'preferred_locations': preferredLocations,
      if (drugAddiction != null) 'drug_addiction': drugAddiction,
      if (smoke != null) 'smoke': smoke,
      if (alcohol != null) 'alcohol': alcohol,
    };

    return await ApiService.makeRequest(
      '${ApiService.baseUrl}/profiles/preferences',
      method: 'PUT',
      body: body,
    );
  }

  static Future<http.Response> getPreferenceOptions() async {
    return await ApiService.makeRequest('${ApiService.baseUrl}/preferences/all-options');
  }

  static Future<http.Response> uploadProfilePhoto(XFile image) async {
    String? token = await ApiService.getToken();
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiService.baseUrl}/profiles/photos'),
    );

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    if (kIsWeb) {
      List<int> imageBytes = await image.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          imageBytes,
          filename: image.name,
        ),
      );
    } else {
      request.files.add(await http.MultipartFile.fromPath('photo', image.path));
    }

    var streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }
}