import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_service.dart';
import 'auth_service.dart';
import 'audit_service.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/faq.dart';

class FAQService {
  final String assetPath = 'assets/faqs.json';
  final String? remoteUrl; // optional remote update URL

  List<FAQ> _faqs = [];
  final List<String> _recent = [];

  FAQService({this.remoteUrl});

  FAQ _mapFaq(Map<String, dynamic> data, String id) {
    final rawTags = data['tags'];
    final tags = rawTags is List ? rawTags.map((e) => e.toString()).toList() : <String>[];
    final description = _resolveDescription(data);
    return FAQ(
      id: id,
      category: (data['category'] ?? 'General').toString(),
      question: (data['question'] ?? '').toString(),
      answer: (data['answer'] ?? '').toString(),
      description: description,
      tags: tags,
    );
  }

  String _resolveDescription(Map<String, dynamic> data) {
    final raw = data['description'] ?? data['summaryHint'];
    final text = raw?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
    final answer = data['answer']?.toString() ?? '';
    final parts = answer.split(RegExp(r'(?<=[.!?])\s+'));
    if (parts.isNotEmpty && parts.first.trim().isNotEmpty) {
      return parts.first.trim();
    }
    return (data['question'] ?? '').toString();
  }

  // Public getter for Firestore collection
  CollectionReference<Map<String, dynamic>> get faqsCollection => 
      FirebaseFirestore.instance.collection('faqs');

  Future<void> loadFromAssets() async {
    final raw = await rootBundle.loadString(assetPath);
    final List<dynamic> j = json.decode(raw) as List<dynamic>;
    _faqs = j.map((e) => FAQ.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<bool> loadFromFirestore({int limit = 500}) async {
    try {
      final snap = await faqsCollection.limit(limit).get();
      if (snap.docs.isEmpty) return false;
      _faqs = snap.docs
          .map((d) => _mapFaq(d.data(), d.id))
          .where((f) => f.question.isNotEmpty && f.answer.isNotEmpty)
          .toList();
      return _faqs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  List<FAQ> all() => List.unmodifiable(_faqs);

  List<String> categories() => _faqs.map((f) => f.category).toSet().toList();

  List<FAQ> byCategory(String category) => _faqs.where((f) => f.category == category).toList();

  List<FAQ> search(String q) {
    final queryRaw = q.trim().toLowerCase();
    if (queryRaw.isEmpty) return [];

    // tokenize the query
    final tokenReg = RegExp(r"\w+");
    final queryTokens = tokenReg.allMatches(queryRaw).map((m) => m.group(0)!).toList();

    final List<MapEntry<FAQ, double>> scored = [];

    for (final f in _faqs) {
      final qLowerQuestion = f.question.toLowerCase();
      final qLowerAnswer = f.answer.toLowerCase();
      final tagsLower = f.tags.map((t) => t.toLowerCase()).toList();

      double score = 0.0;

      // exact substring matches are strong signals
      if (qLowerQuestion.contains(queryRaw)) score += 60;
      if (qLowerAnswer.contains(queryRaw)) score += 30;

      // token matches with different weights
      for (final tkn in queryTokens) {
        if (qLowerQuestion.contains(tkn)) score += 10;
        if (qLowerAnswer.contains(tkn)) score += 4;
        if (tagsLower.any((tg) => tg.contains(tkn))) score += 12;
      }

      // if all tokens appear within the same answer sentence, boost confidence
      if (queryTokens.length > 1) {
        final sentences = qLowerAnswer.split(RegExp(r"[.!?]\s*"));
        for (final s in sentences) {
          final hasAll = queryTokens.every((tkn) => s.contains(tkn));
          if (hasAll) {
            score += 20;
            break;
          }
        }
      }

      if (score > 0) scored.add(MapEntry(f, score));
    }

    // sort by score desc
    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored.map((e) => e.key).toList();
  }

  void markViewed(String id) {
    _recent.remove(id);
    _recent.insert(0, id);
    if (_recent.length > 10) _recent.removeLast();
  }

  List<FAQ> getRecentlyViewed() => _recent.map((id) => _faqs.firstWhere((f) => f.id == id, orElse: () => _faqs.first)).toList();

  Future<void> toggleBookmark(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('bookmarks') ?? <String>[];
    // stored items are JSON strings {"id":"...","title":"..."}
    final List<Map<String, dynamic>> items = stored.map((s) {
      try {
        return json.decode(s) as Map<String, dynamic>;
      } catch (_) {
        return {'id': s, 'title': ''};
      }
    }).toList();

    final exists = items.any((it) => it['id'] == id);
    if (exists) {
      items.removeWhere((it) => it['id'] == id);
      await prefs.setStringList('bookmarks', items.map((it) => json.encode(it)).toList());
      final f = getById(id);
      try {
        await AnalyticsService.instance.logBookmark(id: id, title: f?.question ?? '', added: false);
        final u = AuthService.instance.currentUser;
        if (u != null) {
          await FirebaseFirestore.instance.collection('users').doc(u.uid).set({
            'bookmarksCount': FieldValue.increment(-1),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          await FirebaseFirestore.instance.collection('notifications').add({
            'userId': u.uid,
            'title': 'Bookmark removed',
            'body': 'Removed from bookmarks: ${f?.question ?? 'FAQ'}',
            'type': 'bookmark_removed',
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
          final isAdmin = await AuthService.instance.isAdmin();
          if (isAdmin) {
            await AuditService.instance.logUserActivity(
              type: 'bookmark_remove',
              description: 'Removed a bookmark',
              userId: u.uid,
            );
          }
        }
      } catch (_) {}
      return;
    }

    final f = getById(id);
    final title = f?.question ?? '';
    final newItem = {'id': id, 'title': title};
    items.add(newItem);
    await prefs.setStringList('bookmarks', items.map((it) => json.encode(it)).toList());
    try {
      await AnalyticsService.instance.logBookmark(id: id, title: title, added: true);
      final u = AuthService.instance.currentUser;
      if (u != null) {
        await FirebaseFirestore.instance.collection('users').doc(u.uid).set({
          'bookmarksCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': u.uid,
          'title': 'Bookmark saved',
          'body': 'Saved to bookmarks: $title',
          'type': 'bookmark_added',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        final isAdmin = await AuthService.instance.isAdmin();
        if (isAdmin) {
          await AuditService.instance.logUserActivity(
            type: 'bookmark_add',
            description: 'Added a bookmark',
            userId: u.uid,
          );
        }
      }
    } catch (_) {}
  }

  Future<List<String>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('bookmarks') ?? <String>[];
    final ids = <String>[];
    for (final s in stored) {
      try {
        final m = json.decode(s) as Map<String, dynamic>;
        ids.add(m['id']?.toString() ?? s);
      } catch (_) {
        ids.add(s);
      }
    }
    return ids;
  }

  FAQ? getById(String id) {
    try {
      return _faqs.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<FAQ>> getBookmarkedFaqs() async {
    if (_faqs.isEmpty) {
      final loaded = await loadFromFirestore();
      if (!loaded) {
        await loadFromAssets();
      }
    }
    final ids = await getBookmarks();
    final out = <FAQ>[];
    for (final id in ids) {
      final f = getById(id);
      if (f != null) out.add(f);
    }
    return out;
  }

  Future<bool> isBookmarked(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final set = prefs.getStringList('bookmarks') ?? <String>[];
    for (final s in set) {
      try {
        final m = json.decode(s) as Map<String, dynamic>;
        if (m['id'] == id) return true;
      } catch (_) {
        if (s == id) return true;
      }
    }
    return false;
  }

  /// Try to fetch updated FAQs from remoteUrl (if provided).
  Future<bool> fetchRemoteUpdate() async {
    if (remoteUrl == null) return false;
    try {
      final resp = await http.get(Uri.parse(remoteUrl!));
      if (resp.statusCode == 200) {
        final List<dynamic> j = json.decode(resp.body) as List<dynamic>;
        _faqs = j.map((e) => FAQ.fromJson(e as Map<String, dynamic>)).toList();
        return true;
      }
    } catch (_) {}
    return false;
  }

  // Firestore-backed CRUD for FAQs (admin)
  Stream<List<Map<String, dynamic>>> streamRemoteFaqs() {
    return faqsCollection
        .orderBy('question')
        .snapshots()
        .map((snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Future<DocumentReference<Map<String, dynamic>>> createFaq(Map<String, dynamic> data) async {
    final now = DateTime.now().toUtc();
    final payload = {...data, 'createdAt': now.toIso8601String(), 'updatedAt': now.toIso8601String()};
    return await faqsCollection.add(payload);
  }

  Future<void> updateFaq(String id, Map<String, dynamic> changes) async {
    final now = DateTime.now().toUtc();
    final payload = {...changes, 'updatedAt': now.toIso8601String()};
    await faqsCollection.doc(id).update(payload);
  }

  Future<void> deleteFaq(String id) async {
    await faqsCollection.doc(id).delete();
  }
}