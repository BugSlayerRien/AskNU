import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class AIChatService {
  AIChatService._();
  static final AIChatService instance = AIChatService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> generateAnswer({required String question}) async {
    final config = await _firestore.collection('app_config').doc('ai').get();
    final data = config.data() ?? {};
    final endpoint = data['chatEndpoint']?.toString() ?? '';
    final apiKey = data['apiKey']?.toString() ?? '';
    final provider = data['provider']?.toString().toLowerCase() ?? '';
    final model = data['model']?.toString() ?? 'gemini-1.5-flash';

    if (provider.isEmpty && endpoint.isEmpty) {
      throw Exception('Missing provider or chatEndpoint in app_config/ai');
    }
    if (provider == 'gemini' && apiKey.isEmpty && endpoint.isEmpty) {
      throw Exception('Missing Gemini apiKey in app_config/ai');
    }

    if (provider == 'gemini' || endpoint.isNotEmpty) {
      final uri = endpoint.isNotEmpty
          ? Uri.parse(endpoint)
          : Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
            );

      final prompt = _buildPrompt(question);
      final body = provider == 'gemini' || endpoint.isEmpty
          ? {
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ]
            }
          : {
              'question': question,
              'prompt': prompt,
            };

      final headers = {
        'Content-Type': 'application/json',
        if (apiKey.isNotEmpty && endpoint.isNotEmpty) 'Authorization': 'Bearer $apiKey',
      };

      final resp = await http
          .post(uri, headers: headers, body: json.encode(body))
          .timeout(const Duration(seconds: 20));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final payload = json.decode(resp.body);
        if (provider == 'gemini' || endpoint.isEmpty) {
          final text = (payload is Map && payload['candidates'] is List && (payload['candidates'] as List).isNotEmpty)
              ? (((payload['candidates'] as List).first['content']?['parts'] as List?)?.first['text']?.toString() ?? '')
              : '';
          if (text.trim().isNotEmpty) return _normalize(text);
        }
        final answer = (payload is Map && payload['answer'] != null)
            ? payload['answer'].toString()
            : (payload is Map && payload['response'] != null)
                ? payload['response'].toString()
                : resp.body.toString();
        return _normalize(answer);
      }

      throw Exception('AI HTTP ${resp.statusCode}: ${resp.body}');
    }

    return _fallbackAnswer();
  }

  String _buildPrompt(String question) {
    return 'You are AskNU, a helpful university registrar assistant. '
        'Answer clearly and concisely in 1-3 short sentences. '
        'If you are unsure or the request needs official confirmation, '
        'say you are not sure and suggest contacting the registrar office.\n\n'
        'Question: $question';
  }

  String _fallbackAnswer() {
    return 'I could not find a direct FAQ answer and the AI assistant is not available right now.';
  }

  String _normalize(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
