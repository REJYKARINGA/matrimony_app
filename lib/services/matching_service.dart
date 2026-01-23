import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class MatchingService {
  static Future<http.Response> getSuggestions({int page = 1}) async {
    return await ApiService.makeRequest('${ApiService.baseUrl}/matching/suggestions?page=$page');
  }

  static Future<http.Response> sendInterest(int userId, {String? message}) async {
    return await ApiService.makeRequest(
      '${ApiService.baseUrl}/matching/interest/$userId',
      method: 'POST',
      body: message != null ? {'message': message} : {},
    );
  }

  static Future<http.Response> getMatches({int page = 1}) async {
    return await ApiService.makeRequest('${ApiService.baseUrl}/matching/matches?page=$page');
  }

  static Future<http.Response> getSentInterests({int page = 1}) async {
    return await ApiService.makeRequest('${ApiService.baseUrl}/matching/interests/sent?page=$page');
  }

  static Future<http.Response> getReceivedInterests({int page = 1}) async {
    return await ApiService.makeRequest('${ApiService.baseUrl}/matching/interests/received?page=$page');
  }
}