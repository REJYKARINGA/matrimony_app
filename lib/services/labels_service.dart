import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/payment_labels_model.dart';
import 'api_service.dart';

class LabelsService {
  static LabelsService? _instance;
  PaymentLabels? _labels;

  LabelsService._();

  static LabelsService get instance {
    _instance ??= LabelsService._();
    return _instance!;
  }

  PaymentLabels get labels {
    if (_labels != null) return _labels!;
    return PaymentLabels();
  }

  bool get isLoaded => _labels != null;

  String curr(String amount) {
    return '${labels.currency}$amount';
  }

  Future<void> load() async {
    await _fetch();
  }

  Future<void> reload() async {
    await _fetch();
  }

  Future<void> _fetch() async {
    try {
      final response = await ApiService.makeRequest(
        '${ApiService.baseUrl}/config/payment-labels',
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('LABELS_FETCH: status=200 body_keys=${data.keys.join(",")}');
        if (data['pricing'] != null) {
          debugPrint('LABELS_PRICING: wallet_is_active=${data['pricing']['wallet_is_active']} ios=${data['pricing']['wallet_in_maintenance_ios']} android=${data['pricing']['wallet_in_maintenance_android']}');
        }
        _labels = PaymentLabels.fromJson(data);
      } else {
        debugPrint('LABELS_FETCH: status=${response.statusCode} body=${response.body}');
      }
    } catch (e) {
      debugPrint('LabelsService._fetch ERROR: $e');
    }
  }
}
