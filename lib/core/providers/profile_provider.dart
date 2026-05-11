import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String nativeCountry;
  final String hostCountry;
  final String language;
  final String status;

  UserProfile({
    required this.nativeCountry,
    required this.hostCountry,
    required this.language,
    required this.status,
  });
}


final profileNotifierProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  return ProfileNotifier(ref);
});

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  ProfileNotifier(Ref ref) : super(const AsyncValue.loading()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nativeCountry = prefs.getString('nativeCountry');
      final hostCountry = prefs.getString('hostCountry');
      final language = prefs.getString('language');
      final status = prefs.getString('status');

      if (nativeCountry != null && hostCountry != null && language != null && status != null) {
        state = AsyncValue.data(UserProfile(
          nativeCountry: nativeCountry,
          hostCountry: hostCountry,
          language: language,
          status: status,
        ));
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveProfile({
    required String nativeCountry,
    required String hostCountry,
    required String language,
    required String status,
  }) async {
    state = const AsyncValue.loading();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nativeCountry', nativeCountry);
      await prefs.setString('hostCountry', hostCountry);
      await prefs.setString('language', language);
      await prefs.setString('status', status);
      
      state = AsyncValue.data(UserProfile(
        nativeCountry: nativeCountry,
        hostCountry: hostCountry,
        language: language,
        status: status,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clearProfile() async {
    state = const AsyncValue.loading();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('nativeCountry');
      await prefs.remove('hostCountry');
      await prefs.remove('language');
      await prefs.remove('status');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
