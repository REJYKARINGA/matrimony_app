import 'package:http/http.dart' as http;
import 'api_service.dart';

class ProfileViewService {
  static String get visitorsUrl => '${ApiService.baseUrl}/profiles/visitors';
  
  static Future<http.Response> getVisitors() async {
    return await ApiService.makeRequest(visitorsUrl);
  }

  static Future<http.Response> recordView(int profileId) async {
    return await ApiService.makeRequest(
      '${ApiService.baseUrl}/profiles/$profileId/view',
      method: 'POST',
    );
  }
}
