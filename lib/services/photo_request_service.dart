import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class PhotoRequestService {
  static Future<http.Response> sendRequest(int receiverId) async {
    return ApiService.makeRequest(
      '${ApiService.baseUrl}/photo-requests/$receiverId',
      method: 'POST',
    );
  }

  static Future<http.Response> getPendingRequests() async {
    return ApiService.makeRequest(
      '${ApiService.baseUrl}/photo-requests/pending',
    );
  }

  static Future<http.Response> acceptRequest(int requestId) async {
    return ApiService.makeRequest(
      '${ApiService.baseUrl}/photo-requests/$requestId/accept',
      method: 'PUT',
    );
  }

  static Future<http.Response> rejectRequest(int requestId) async {
    return ApiService.makeRequest(
      '${ApiService.baseUrl}/photo-requests/$requestId/reject',
      method: 'PUT',
    );
  }
}
