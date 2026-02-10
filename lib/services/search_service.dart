import 'package:http/http.dart' as http;
import 'api_service.dart';

class SearchService {
  static Future<http.Response> getPreferenceMatches() async {
    return await ApiService.makeRequest('${ApiService.baseUrl}/search/preference-matches');
  }

  static Future<http.Response> searchProfiles({
    String? religion,
    String? caste,
    String? occupation,
    String? education,
    String? maritalStatus,
    int? minAge,
    int? maxAge,
    String? location,
    String? field,
    String? matrimonyId,
    int page = 1,
  }) async {
    Map<String, String> queryParams = {'page': page.toString()};
    if (matrimonyId != null) queryParams['matrimony_id'] = matrimonyId;
    if (religion != null) queryParams['religion'] = religion;
    if (caste != null) queryParams['caste'] = caste;
    if (occupation != null) queryParams['occupation'] = occupation;
    if (education != null) queryParams['education'] = education;
    if (maritalStatus != null) queryParams['marital_status'] = maritalStatus;
    if (minAge != null) queryParams['min_age'] = minAge.toString();
    if (maxAge != null) queryParams['max_age'] = maxAge.toString();
    if (location != null) queryParams['location'] = location;
    if (field != null) queryParams['field'] = field;

    String queryString = Uri(queryParameters: queryParams).query;
    return await ApiService.makeRequest('${ApiService.baseUrl}/search?$queryString');
  }

  static Future<http.Response> getNearbyProfiles({double radius = 50, int page = 1}) async {
    return await ApiService.makeRequest('${ApiService.baseUrl}/location/nearby?radius=$radius&page=$page');
  }

  static Future<http.Response> logDiscoveryClick(String category) async {
    return await ApiService.makeRequest(
      '${ApiService.baseUrl}/search/log-click',
      method: 'POST',
      body: {'category': category},
    );
  }
}
