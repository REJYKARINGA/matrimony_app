import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class PaymentService {
  static Future<http.Response> getWalletBalance() async {
    return await ApiService.makeRequest('${ApiService.baseUrl}/payment/wallet/balance');
  }

  static Future<http.Response> createOrder({
    required double amount,
    required String type,
    int? unlockedUserId,
  }) async {
    return await ApiService.makeRequest(
      '${ApiService.baseUrl}/payment/create-order',
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
      '${ApiService.baseUrl}/payment/verify',
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
      '${ApiService.baseUrl}/payment/unlock-contact-wallet',
      method: 'POST',
      body: {'unlocked_user_id': unlockedUserId},
    );
  }

  static Future<http.Response> checkContactUnlock(int userId) async {
    return await ApiService.makeRequest('${ApiService.baseUrl}/payment/check-unlock/$userId');
  }

  static Future<http.Response> getTransactionHistory() async {
    return await ApiService.makeRequest('${ApiService.baseUrl}/payment/transactions');
  }
}
