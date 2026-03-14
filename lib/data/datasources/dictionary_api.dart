import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../models/dictionary_response.dart';

class DictionaryApi {
  final http.Client _client;

  DictionaryApi({http.Client? client}) : _client = client ?? http.Client();

  Future<DictionaryResponse> search(String word) async {
    final uri = Uri.parse('${AppConstants.dictionaryApiBaseUrl}/${Uri.encodeComponent(word.trim().toLowerCase())}');

    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: AppConstants.apiTimeoutSeconds));

    if (response.statusCode == 200) {
      final jsonList = json.decode(response.body) as List<dynamic>;
      return DictionaryResponse.fromJsonList(jsonList);
    } else if (response.statusCode == 404) {
      throw WordNotFoundException(word);
    } else {
      throw Exception('API error: ${response.statusCode}');
    }
  }

  void dispose() {
    _client.close();
  }
}

class WordNotFoundException implements Exception {
  final String word;
  WordNotFoundException(this.word);

  @override
  String toString() => '단어를 찾을 수 없습니다: $word';
}
