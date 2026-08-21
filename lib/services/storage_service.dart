import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/daily_workout.dart';
import '../models/game_result.dart';
import '../models/user_level_progress.dart';

class StorageService {
  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // --- Auth Storage ---
  Future<bool> isLoggedIn() async {
    await init();
    return _prefs?.getBool('is_logged_in') ?? false;
  }

  Future<void> setLoggedIn(bool value) async {
    await init();
    await _prefs?.setBool('is_logged_in', value);
  }

  Future<void> logout() async {
    await init();
    await _prefs?.setBool('is_logged_in', false);
  }

  // --- Profile Storage ---
  Future<UserProfile> loadProfile() async {
    await init();
    String? raw = _prefs?.getString('user_profile');
    if (raw != null) {
      try {
        return UserProfile.fromJson(jsonDecode(raw));
      } catch (_) {}
    }
    UserProfile defaultProf = UserProfile.defaultProfile();
    await saveProfile(defaultProf);
    return defaultProf;
  }

  Future<void> saveProfile(UserProfile profile) async {
    await init();
    await _prefs?.setString('user_profile', jsonEncode(profile.toJson()));
  }

  // --- Level Journey Progress Storage ---
  Future<UserLevelProgress> loadLevelProgress() async {
    await init();
    String? raw = _prefs?.getString('user_level_progress');
    if (raw != null) {
      try {
        return UserLevelProgress.fromJson(jsonDecode(raw));
      } catch (_) {}
    }
    UserLevelProgress initial = UserLevelProgress.initial();
    await saveLevelProgress(initial);
    return initial;
  }

  Future<void> saveLevelProgress(UserLevelProgress progress) async {
    await init();
    await _prefs?.setString('user_level_progress', jsonEncode(progress.toJson()));
  }

  // --- Daily Workout Storage ---
  Future<DailyWorkout> loadDailyWorkout() async {
    await init();
    final now = DateTime.now();
    final todayKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    String? raw = _prefs?.getString('daily_workout');
    if (raw != null) {
      try {
        DailyWorkout loaded = DailyWorkout.fromJson(jsonDecode(raw));
        if (loaded.dateKey == todayKey) {
          return loaded;
        }
      } catch (_) {}
    }

    // New day workout
    DailyWorkout todayWorkout = DailyWorkout.generateForToday();
    await saveDailyWorkout(todayWorkout);
    return todayWorkout;
  }

  Future<void> saveDailyWorkout(DailyWorkout workout) async {
    await init();
    await _prefs?.setString('daily_workout', jsonEncode(workout.toJson()));
  }

  // --- History Storage ---
  Future<List<GameResult>> loadGameHistory() async {
    await init();
    List<String>? rawList = _prefs?.getStringList('game_history');
    if (rawList != null) {
      try {
        return rawList
            .map((item) => GameResult.fromJson(jsonDecode(item)))
            .toList();
      } catch (_) {}
    }
    return [];
  }

  Future<void> addGameResult(GameResult result) async {
    await init();
    List<GameResult> current = await loadGameHistory();
    current.insert(0, result);
    // Keep last 50 games
    if (current.length > 50) current = current.sublist(0, 50);

    List<String> rawList =
        current.map((r) => jsonEncode(r.toJson())).toList();
    await _prefs?.setStringList('game_history', rawList);
  }
}
