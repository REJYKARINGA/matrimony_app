import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../services/labels_service.dart';

class PaymentService {
  /// Returns the prefix for payment API endpoints
  static String get _p => '${ApiService.baseUrl}/tx';

  static Future<http.Response> getWalletBalance() async {
    return await ApiService.makeRequest('$_p/bal');
  }

  static Future<http.Response> createOrder({
    required double amount,
    required String type,
    int? unlockedUserId,
  }) async {
    return await ApiService.makeRequest(
      '$_p/ord',
      method: 'POST',
      body: {
        'amount': amount,
        'type': type,
        if (unlockedUserId != null) 'unlocked_user_id': unlockedUserId,
      },
    );
  }

  static Future<http.Response> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required int transactionId,
    int? unlockedUserId,
  }) async {
    return await ApiService.makeRequest(
      '$_p/vrf',
      method: 'POST',
      body: {
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
        'transaction_id': transactionId,
        if (unlockedUserId != null) 'unlocked_user_id': unlockedUserId,
      },
    );
  }

  static Future<http.Response> unlockContactWithWallet(int unlockedUserId) async {
    return await ApiService.makeRequest(
      '$_p/uwl',
      method: 'POST',
      body: {'unlocked_user_id': unlockedUserId},
    );
  }

  static Future<http.Response> unlockContactFree(int unlockedUserId) async {
    return await ApiService.makeRequest(
      '$_p/ufr',
      method: 'POST',
      body: {'unlocked_user_id': unlockedUserId},
    );
  }

  static Future<http.Response> checkContactUnlock(int userId) async {
    return await ApiService.makeRequest('$_p/ck/$userId');
  }

  static Future<http.Response> getTransactionHistory() async {
    return await ApiService.makeRequest('$_p/hst');
  }

  static Future<http.Response> getTodayUnlockCount() async {
    return await ApiService.makeRequest('$_p/duc');
  }

  static Future<http.Response> searchUser(String query) async {
    return await ApiService.makeRequest('$_p/su?query=$query');
  }

  static Future<http.Response> requestTransferOtp({
    required int recipientId,
    required double amount,
  }) async {
    return await ApiService.makeRequest(
      '$_p/rto',
      method: 'POST',
      body: {
        'recipient_id': recipientId,
        'amount': amount,
      },
    );
  }

  static Future<http.Response> transferWallet({
    required int recipientId,
    required double amount,
    required String otp,
  }) async {
    return await ApiService.makeRequest(
      '$_p/tfr',
      method: 'POST',
      body: {
        'recipient_id': recipientId,
        'amount': amount,
        'otp': otp,
      },
    );
  }

  // ─── Permission-based Unlock Requests ────────────────────────────────

  static Future<http.Response> requestPermission(int targetUserId) async {
    return await ApiService.makeRequest(
      '$_p/rqp',
      method: 'POST',
      body: {'target_user_id': targetUserId},
    );
  }

  static Future<http.Response> getIncomingPermissionRequests() async {
    return await ApiService.makeRequest('$_p/pmi');
  }

  static Future<http.Response> getSentPermissionRequests() async {
    return await ApiService.makeRequest('$_p/pms');
  }

  static Future<http.Response> checkPermissionRequest(int userId) async {
    return await ApiService.makeRequest('$_p/cpk/$userId');
  }

  static Future<http.Response> approvePermissionRequest(int requestId) async {
    return await ApiService.makeRequest(
      '$_p/pap/$requestId',
      method: 'POST',
    );
  }

  static Future<http.Response> rejectPermissionRequest(int requestId) async {
    return await ApiService.makeRequest(
      '$_p/prj/$requestId',
      method: 'POST',
    );
  }

  static Future<http.Response> getPendingPermissionCount() async {
    return await ApiService.makeRequest('$_p/ppc');
  }
}



