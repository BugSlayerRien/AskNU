import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../models/faq.dart';
import 'audit_service.dart';
import 'auth_service.dart';

class FAQSummaryService {
  FAQSummaryService._();
  static final FAQSummaryService instance = FAQSummaryService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<String> generateSummary(FAQ faq) async {
    final config = await _firestore.collection('app_config').doc('ai').get();
    final data = config.data() ?? {};
    final endpoint = data['summaryEndpoint']?.toString() ?? '';
    final apiKey = data['apiKey']?.toString() ?? '';
    final provider = data['provider']?.toString().toLowerCase() ?? '';
    final model = data['model']?.toString() ?? 'gemini-1.5-flash';

    if (provider.isEmpty && endpoint.isEmpty) {
      throw Exception('Missing provider or summaryEndpoint in app_config/ai');
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

      final body = provider == 'gemini' || endpoint.isEmpty
          ? {
              'contents': [
                {
                  'parts': [
                    {
                      'text': 'Summarize this university registrar FAQ in 1-3 short, student-friendly sentences.\n\nQuestion: ${faq.question}\n\nAnswer: ${faq.answer}\n\nCategory: ${faq.category}\n\nDescription: ${faq.description}'
                    }
                  ]
                }
              ]
            }
          : {
              'question': faq.question,
              'answer': faq.answer,
              'category': faq.category,
              'description': faq.description,
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
          if (text.isNotEmpty) return _normalize(text);
        }
        final summary = (payload is Map && payload['summary'] != null)
            ? payload['summary'].toString()
            : resp.body.toString();
        return _normalize(summary);
      }
      throw Exception('Summarizer HTTP ${resp.statusCode}: ${resp.body}');
    }

    return _fallbackSummary(faq.answer);
  }

  Future<void> generateAndSaveSummary(FAQ faq) async {
    final docRef = _firestore.collection('faqs').doc(faq.id);
    final existing = await docRef.get();
    if (!existing.exists) {
      throw Exception('FAQ not found in Firestore. Use Firestore FAQs to summarize.');
    }

    final summary = await generateSummary(faq);
    final source = summary == _fallbackSummary(faq.answer) ? 'auto' : 'ai';

    await docRef.set({
      'summary': summary,
      'summarySource': source,
      'summaryUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final isAdmin = await AuthService.instance.isAdmin();
    if (isAdmin) {
      await AuditService.instance.logAudit(
        action: 'faq_summary_generate',
        metadata: {'faqId': faq.id, 'source': source},
      );
      await AuditService.instance.logUserActivity(
        type: 'faq_summary_generate',
        description: 'Generated FAQ summary',
        userId: null,
      );
    }

    final user = AuthService.instance.currentUser;
    if (user != null) {
      await _firestore.collection('notifications').add({
        'userId': user.uid,
        'title': 'FAQ summary ready',
        'body': 'Summary generated for: ${faq.question}',
        'type': 'faq_summary',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  String _fallbackSummary(String text) {
    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return '';
    final parts = cleaned.split(RegExp(r'(?<=[.!?])\s+'));
    final take = parts.take(2).join(' ');
    return _normalize(take.length > 280 ? take.substring(0, 280) : take);
  }

  String _normalize(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
