import 'package:http/http.dart' as http;
import 'api_service.dart';

class NotificationService {
  static String get notificationsUrl => '${ApiService.baseUrl}/notifications';

  static Future<http.Response> getNotifications() async {
    return await ApiService.makeRequest(notificationsUrl);
  }

  static Future<http.Response> getUnreadCount() async {
    return await ApiService.makeRequest('$notificationsUrl/unread-count');
  }

  static Future<http.Response> markAsRead(int notificationId) async {
    return await ApiService.makeRequest(
      '$notificationsUrl/$notificationId/read',
      method: 'PUT',
    );
  }

  static Future<http.Response> markAllAsRead() async {
    return await ApiService.makeRequest(
      '$notificationsUrl/read-all',
      method: 'POST',
    );
  }

  static Future<http.Response> deleteNotification(int notificationId) async {
    return await ApiService.makeRequest(
      '$notificationsUrl/$notificationId',
      method: 'DELETE',
    );
  }
}
