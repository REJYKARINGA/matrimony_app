import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'payment_service.dart';

// dart:js_interop is available on web, stub on mobile
import 'razorpay_web_stub.dart'
    if (dart.library.js_interop) 'razorpay_web_impl.dart' as web_impl;

class RazorpayService {
  static int _callbackCounter = 0;

  static void openCheckout({
    required String key,
    required double amount,
    required String orderId,
    required int transactionId,
    String? unlockedUserId,
    required void Function() onSuccess,
    required void Function(String) onError,
  }) {
    if (kIsWeb) {
      final cbName = 'rzp_cb_${_callbackCounter++}';
      web_impl.openRazorpayWeb(
        key: key,
        amountPaise: (amount * 100).toInt(),
        orderId: orderId,
        callbackName: cbName,
        description: unlockedUserId != null ? 'Contact Unlock' : 'Wallet Recharge',
        onSuccess: (paymentId, rzpOrderId, signature) async {
          final verifyRes = await PaymentService.verifyPayment(
            razorpayOrderId: rzpOrderId,
            razorpayPaymentId: paymentId,
            razorpaySignature: signature,
            transactionId: transactionId,
            unlockedUserId: unlockedUserId != null ? int.tryParse(unlockedUserId) : null,
          );
          if (verifyRes.statusCode == 200) {
            onSuccess();
          } else {
            final msg = json.decode(verifyRes.body)['error'] ?? 'Verification failed';
            onError(msg.toString());
          }
        },
        onError: onError,
      );
    } else {
      _openNativeCheckout(
        key: key,
        amount: amount,
        orderId: orderId,
        transactionId: transactionId,
        unlockedUserId: unlockedUserId,
        onSuccess: onSuccess,
        onError: onError,
      );
    }
  }

  static void _openNativeCheckout({
    required String key,
    required double amount,
    required String orderId,
    required int transactionId,
    String? unlockedUserId,
    required void Function() onSuccess,
    required void Function(String) onError,
  }) {
    final razorpay = Razorpay();

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (response) async {
      final paymentId = response['razorpay_payment_id'];
      final signature = response['razorpay_signature'];

      final verifyRes = await PaymentService.verifyPayment(
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: signature,
        transactionId: transactionId,
        unlockedUserId: unlockedUserId != null ? int.tryParse(unlockedUserId) : null,
      );

      if (verifyRes.statusCode == 200) {
        onSuccess();
      } else {
        final msg = json.decode(verifyRes.body)['error'] ?? 'Verification failed';
        onError(msg.toString());
      }
      razorpay.clear();
    });

    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (response) {
      onError(response['message'] ?? 'Payment failed');
      razorpay.clear();
    });

    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});

    razorpay.open({
      'key': key,
      'amount': (amount * 100).toInt(),
      'order_id': orderId,
      'name': 'Matrimony',
      'description': unlockedUserId != null ? 'Contact Unlock' : 'Wallet Recharge',
      'theme': {'color': '#00A87D'},
    });
  }
}
