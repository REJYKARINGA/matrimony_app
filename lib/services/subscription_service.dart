import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class SubscriptionService {
  static Future<http.Response> getPlans() async {
    return await ApiService.makeRequest('${ApiService.baseUrl}/subscriptions');
  }

  static Future<http.Response> subscribe(int planId) async {
    return await ApiService.makeRequest(
      '${ApiService.baseUrl}/subscriptions/subscribe/$planId',
      method: 'POST',
    );
  }

  static Future<http.Response> getMySubscription() async {
    return await ApiService.makeRequest('${ApiService.baseUrl}/subscriptions/my');
  }
}