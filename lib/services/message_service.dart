import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class MessageService {
  static Future<http.Response> getConversations({int page = 1}) async {
    return await ApiService.makeRequest('${ApiService.baseUrl}/messages?page=$page');
  }

  static Future<http.Response> getMessagesWithUser(int userId) async {
    return await ApiService.makeRequest('${ApiService.baseUrl}/messages/$userId');
  }

  static Future<http.Response> sendMessage(int receiverId, String message) async {
    return await ApiService.makeRequest(
      '${ApiService.baseUrl}/messages',
      method: 'POST',
      body: {
        'receiver_id': receiverId,
        'message': message,
      },
    );
  }

  static Future<http.Response> markMessageAsRead(int messageId) async {
    return await ApiService.makeRequest(
      '${ApiService.baseUrl}/messages/$messageId/read',
      method: 'PUT',
    );
  }
}