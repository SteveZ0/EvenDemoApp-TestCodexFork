import 'package:dio/dio.dart';

class ApiGpt4oService {
  late Dio _dio;

  ApiGpt4oService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.openai.com/v1',
        headers: {
          'Authorization': 'Bearer ${const String.fromEnvironment("OPENAI_API_KEY", defaultValue: "sk-PLACEHOLDER")}',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  Future<String> sendChatRequest(String question) async {
    final data = {
      "model": "gpt-4o-mini",
      "messages": [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": question}
      ],
    };

    try {
      final response = await _dio.post('/chat/completions', data: data);

      if (response.statusCode == 200) {
        final data = response.data;
        final content = data['choices']?[0]?['message']?['content'] ?? 'Unable to answer the question';
        return content;
      } else {
        return 'Request failed with status: ${response.statusCode}';
      }
    } on DioError catch (e) {
      if (e.response != null) {
        return 'AI request error: ${e.response?.statusCode}, ${e.response?.data}';
      } else {
        return 'AI request error: ${e.message}';
      }
    }
  }
}
