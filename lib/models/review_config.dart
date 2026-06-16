class ReviewConfig {
  final bool enabled;
  final int unlockThreshold;
  final int minDaysBetween;
  final int maxPrompts;

  const ReviewConfig({
    this.enabled = true,
    this.unlockThreshold = 10,
    this.minDaysBetween = 90,
    this.maxPrompts = 3,
  });

  factory ReviewConfig.fromJson(Map<String, dynamic> json) {
    return ReviewConfig(
      enabled: json['enabled'] != null 
          ? (json['enabled'] == true || json['enabled'] == 'true' || json['enabled'] == 1) 
          : true,
      unlockThreshold: json['unlock_threshold'] != null 
          ? int.tryParse(json['unlock_threshold'].toString()) ?? 10 
          : 10,
      minDaysBetween: json['min_days_between'] != null 
          ? int.tryParse(json['min_days_between'].toString()) ?? 90 
          : 90,
      maxPrompts: json['max_prompts'] != null 
          ? int.tryParse(json['max_prompts'].toString()) ?? 3 
          : 3,
    );
  }
}
