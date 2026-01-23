import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recording.dart';
import '../models/tag.dart';

/// 로컬 저장소 서비스
class StorageService {
  static const String _recordingsKey = 'recordings';
  static const String _tagsKey = 'tags';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // 녹음
  Future<void> saveRecordings(List<Recording> recordings) async {
    final jsonList = recordings.map((r) => r.toJson()).toList();
    await _prefs.setString(_recordingsKey, jsonEncode(jsonList));
  }

  Future<List<Recording>> loadRecordings() async {
    final jsonString = _prefs.getString(_recordingsKey);
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => Recording.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // 태그
  Future<void> saveTags(List<Tag> tags) async {
    final jsonList = tags.map((t) => t.toJson()).toList();
    await _prefs.setString(_tagsKey, jsonEncode(jsonList));
  }

  Future<List<Tag>> loadTags() async {
    final jsonString = _prefs.getString(_tagsKey);
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => Tag.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
