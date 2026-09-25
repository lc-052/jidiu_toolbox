import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../shared/hive/hive_init.dart';
import '../models/chat_message.dart';

class ApiClient {
  final String baseUrl;
  final String apiKey;

  ApiClient({required this.baseUrl, required this.apiKey});

  Future<String> send({
    required String userMessage,
    required List<ChatMessage> history,
    bool stream = true,
  }) async {
    // 构造 messages 数组
    final messages = [
      // system prompt
      {'role': 'system', 'content': '你是一个有用的助手。请用中文回答。'},
      // historical messages
      ...history.map((m) => m.toJson()),
      // new user message
      {'role': 'user', 'content': userMessage},
    ];

    final url = Uri.parse('$baseUrl/chat/completions');

    if (stream) {
      // SSE 流式请求
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'model': AppPreferences.getModelName(), 'messages': messages, 'stream': true}),
      );

      if (response.statusCode == 200) {
        // 解析 SSE chunks
        return _parseStream(response.body);
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } else {
      // 非流式请求
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'model': AppPreferences.getModelName(), 'messages': messages, 'stream': false}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List;
        return choices[0]['message']['content'] as String;
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    }
  }

  String _parseStream(String responseBody) {
    // 简单 SSE 解析：合并所有 delta.content
    final parts = <String>[];
    for (final line in responseBody.split('\n')) {
      if (line.startsWith('data: ')) {
        final data = line.substring(6);
        if (data == '[DONE]') continue;
        try {
          final chunk = jsonDecode(data) as Map<String, dynamic>;
          final delta = chunk['delta'] as Map<String, dynamic>?;
          final content = delta?['content'] as String?;
          if (content != null) parts.add(content);
        } catch (_) {}
      }
    }
    return parts.join();
  }
}
