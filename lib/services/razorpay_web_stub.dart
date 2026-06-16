// Stub for mobile — openRazorpayWeb is never called on mobile (kIsWeb=false)
void openRazorpayWeb({
  required String key,
  required int amountPaise,
  required String orderId,
  required String callbackName,
  required String description,
  required void Function(String, String, String) onSuccess,
  required void Function(String) onError,
}) {
  throw UnsupportedError('openRazorpayWeb is not supported on this platform');
}
