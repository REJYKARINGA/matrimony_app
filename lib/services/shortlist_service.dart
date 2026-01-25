import 'package:http/http.dart' as http;
import 'api_service.dart';

class ShortlistService {
  static String get shortlistUrl => '${ApiService.baseUrl}/shortlist';

  static Future<http.Response> getShortlistedProfiles() async {
    return await ApiService.makeRequest(shortlistUrl);
  }

  static Future<http.Response> addToShortlist(int shortlistedUserId, {String? notes}) async {
    return await ApiService.makeRequest(
      shortlistUrl,
      method: 'POST',
      body: {
        'shortlisted_user_id': shortlistedUserId,
        'notes': notes,
      },
    );
  }

  static Future<http.Response> removeFromShortlist(int shortlistedUserId) async {
    return await ApiService.makeRequest(
      '$shortlistUrl/$shortlistedUserId',
      method: 'DELETE',
    );
  }

  static Future<http.Response> checkIsShortlisted(int shortlistedUserId) async {
    return await ApiService.makeRequest('$shortlistUrl/check/$shortlistedUserId');
  }
}
