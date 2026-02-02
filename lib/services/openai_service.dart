import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';

class OpenAIService {
  static const String _apiKeyBoxName = 'openai_api_key';
  static const String _keyName = 'api_key';
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  
  // TODO: 여기에 API Key를 입력하세요 (테스트용)
  static const String _hardcodedApiKey = ''; 

  /// API Key 저장
  Future<void> setApiKey(String apiKey) async {
    final box = await Hive.openBox(_apiKeyBoxName);
    await box.put(_keyName, apiKey);
  }

  /// API Key 조회
  Future<String?> getApiKey() async {
    // 1. 하드코딩된 키가 있으면 우선 사용
    if (_hardcodedApiKey.isNotEmpty) return _hardcodedApiKey;

    // 2. 저장된 키 확인
    final box = await Hive.openBox(_apiKeyBoxName);
    return box.get(_keyName);
  }

  /// 요약 생성 요청
  Future<String> generateSummary(String prompt) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API Key가 설정되지 않았습니다.');
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': '너는 음악 연습 기록을 분석하고 요약해주는 친절하고 전문적인 음악 코치야. 사용자의 연습 기록을 바탕으로 동기 부여가 되고 통찰력 있는 요약을 한국어로 작성해줘.'
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        throw Exception('OpenAI API 호출 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('요약 생성 중 오류 발생: $e');
    }
  }
}
