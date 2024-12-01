import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _nameKey = 'user_name';
  static const String _ageGroupKey = 'user_age_group';
  static const String _visitFrequencyKey = 'user_visit_frequency';
  static const String _interestsKey = 'user_interests';
  static const String _onboardingCompleteKey = 'onboarding_complete';

  Future<void> saveOnboardingData({
    String? name,
    String? ageGroup,
    String? visitFrequency,
    List<String>? interests,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (name != null) await prefs.setString(_nameKey, name);
    if (ageGroup != null) await prefs.setString(_ageGroupKey, ageGroup);
    if (visitFrequency != null)
      await prefs.setString(_visitFrequencyKey, visitFrequency);
    if (interests != null) await prefs.setStringList(_interestsKey, interests);
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
  }

  Future<Map<String, dynamic>> getOnboardingData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'name': prefs.getString(_nameKey),
      'ageGroup': prefs.getString(_ageGroupKey),
      'visitFrequency': prefs.getString(_visitFrequencyKey),
      'interests': prefs.getStringList(_interestsKey),
      'isComplete': prefs.getBool(_onboardingCompleteKey) ?? false,
    };
  }

  Future<void> clearOnboardingData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nameKey);
    await prefs.remove(_ageGroupKey);
    await prefs.remove(_visitFrequencyKey);
    await prefs.remove(_interestsKey);
    await prefs.remove(_onboardingCompleteKey);
  }
}
