// Web implementation using dart:js_interop + dart:js_interop_unsafe (Flutter 3.x+)
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('openRazorpayCheckout')
external void _jsOpenRazorpayCheckout(
  String key,
  int amount,
  String orderId,
  String name,
  String description,
  String color,
  String callbackName,
);

@JS('window')
external JSObject get _window;

void openRazorpayWeb({
  required String key,
  required int amountPaise,
  required String orderId,
  required String callbackName,
  required String description,
  required void Function(String, String, String) onSuccess,
  required void Function(String) onError,
}) {
  // Register success callback on window
  final successCb = ((JSString paymentId, JSString rzpOrderId, JSString signature) {
    _cleanup(callbackName);
    onSuccess(paymentId.toDart, rzpOrderId.toDart, signature.toDart);
  }).toJS;

  final dismissCb = (() {
    _cleanup(callbackName);
    onError('Payment cancelled');
  }).toJS;

  final errorCb = ((JSString msg) {
    _cleanup(callbackName);
    onError(msg.toDart);
  }).toJS;

  _window.setProperty('${callbackName}_success'.toJS, successCb);
  _window.setProperty('${callbackName}_dismiss'.toJS, dismissCb);
  _window.setProperty('${callbackName}_error'.toJS, errorCb);

  // Call the global openRazorpayCheckout function from index.html
  _jsOpenRazorpayCheckout(
    key,
    amountPaise,
    orderId,
    'Matrimony',
    description,
    '#00A87D',
    callbackName,
  );
}

void _cleanup(String callbackName) {
  _window.setProperty('${callbackName}_success'.toJS, ''.toJS);
  _window.setProperty('${callbackName}_dismiss'.toJS, ''.toJS);
  _window.setProperty('${callbackName}_error'.toJS, ''.toJS);
}
