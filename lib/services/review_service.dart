import 'dart:convert';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/review_config.dart';
import 'api_service.dart';

class ReviewService {
  static const String _unlockCountKey = 'review_unlock_count';
  static const String _ratingDisabledKey = 'rating_disabled';
  static const String _lastReviewKey = 'last_review_date';
  static const String _promptsShownKey = 'prompts_shown_count';

  static final ReviewService instance = ReviewService._();
  final InAppReview _inAppReview = InAppReview.instance;
  ReviewConfig _config = const ReviewConfig();
  bool _configLoaded = false;

  ReviewService._();

  Future<ReviewConfig> get config async {
    if (!_configLoaded) await _loadConfig();
    return _config;
  }

  Future<void> _loadConfig() async {
    try {
      final response = await ApiService.makeRequest(
        '${ApiService.baseUrl}/config/review',
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _config = ReviewConfig.fromJson(data);
      }
    } catch (_) {}
    _configLoaded = true;
  }

  Future<void> incrementUnlockAndTryReview() async {
    if (!_configLoaded) await _loadConfig();

    if (!_config.enabled) return;
    if (await _isRatingDisabled()) return;

    final prefs = await SharedPreferences.getInstance();
    int count = (prefs.getInt(_unlockCountKey) ?? 0) + 1;
    await prefs.setInt(_unlockCountKey, count);

    if (count >= _config.unlockThreshold) {
      if (await _shouldShowPrompt(prefs)) {
        if (await _inAppReview.isAvailable()) {
          await _inAppReview.requestReview();
          int promptsShown = (prefs.getInt(_promptsShownKey) ?? 0) + 1;
          await prefs.setInt(_promptsShownKey, promptsShown);
          await prefs.setString(
            _lastReviewKey,
            DateTime.now().toIso8601String(),
          );
          await prefs.setInt(_unlockCountKey, 0);
        }
      }
    }
  }

  Future<bool> _shouldShowPrompt(SharedPreferences prefs) async {
    int promptsShown = prefs.getInt(_promptsShownKey) ?? 0;
    if (promptsShown >= _config.maxPrompts) return false;

    String? lastReview = prefs.getString(_lastReviewKey);
    if (lastReview != null) {
      final daysSince = DateTime.now()
          .difference(DateTime.parse(lastReview))
          .inDays;
      if (daysSince < _config.minDaysBetween) return false;
    }

    return true;
  }

  Future<bool> _isRatingDisabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_ratingDisabledKey) ?? false;
  }

  Future<bool> isRatingDisabled() async {
    return _isRatingDisabled();
  }

  Future<void> setRatingDisabled(bool disabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ratingDisabledKey, disabled);
  }

  Future<int> getPromptsShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_promptsShownKey) ?? 0;
  }
}
