import 'package:http/http.dart' as http;
import 'api_service.dart';

class ProfileViewService {
  static String get visitorsUrl => '${ApiService.baseUrl}/profiles/visitors';
  static String get visitedUrl => '${ApiService.baseUrl}/profiles/visited';
  static String get contactViewedUrl => '${ApiService.baseUrl}/profiles/contact-viewed';
  
  static Future<http.Response> getVisitors() async {
    return await ApiService.makeRequest(visitorsUrl);
  }

  static Future<http.Response> getVisitedProfiles() async {
    return await ApiService.makeRequest(visitedUrl);
  }

  static Future<http.Response> getContactViewedProfiles() async {
    return await ApiService.makeRequest(contactViewedUrl);
  }

  static Future<http.Response> recordView(int profileId) async {
    return await ApiService.makeRequest(
      '${ApiService.baseUrl}/profiles/$profileId/view',
      method: 'POST',
    );
  }
}
