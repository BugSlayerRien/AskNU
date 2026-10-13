import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class ConversationService {
  static final ConversationService instance = ConversationService._internal();
  ConversationService._internal();

  // This is correct for subcollections
  CollectionReference<Map<String, dynamic>> _conversationsFor(String uid) => 
      FirebaseFirestore.instance.collection('users').doc(uid).collection('conversations');

  Stream<List<Map<String, dynamic>>> streamConversations() {
    final u = AuthService.instance.currentUser;
    if (u == null) return const Stream.empty();
    return _conversationsFor(u.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Future<DocumentReference<Map<String, dynamic>>> createConversation({required String title}) async {
    final u = AuthService.instance.currentUser!;
    final now = DateTime.now().toUtc().toIso8601String();
    final payload = {
      'title': title, 
      'createdAt': now, 
      'updatedAt': now, 
      'messages': <Map<String,dynamic>>[],
      'messageCount': 0,
      'lastMessageText': '',
      'lastMessageAt': null,
    };
    return await _conversationsFor(u.uid).add(payload);
  }

  Future<void> renameConversation(String id, String title) async {
    final u = AuthService.instance.currentUser!;
    await _conversationsFor(u.uid).doc(id).update({
      'title': title, 
      'updatedAt': DateTime.now().toUtc().toIso8601String()
    });
  }

  Future<void> addMessage(String conversationId, Map<String, dynamic> message) async {
    final u = AuthService.instance.currentUser!;
    final ref = _conversationsFor(u.uid).doc(conversationId);
    final lastText = message['text']?.toString() ?? '';
    await ref.update({
      'messages': FieldValue.arrayUnion([message]),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'lastMessageText': lastText,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'messageCount': FieldValue.increment(1),
    });
    // If message contains a referenced FAQ, increment askedCount on that FAQ document
    try {
      final faq = message['faq'];
      String? faqId;
      if (faq is Map && faq['id'] != null) faqId = faq['id'].toString();
      if (faqId != null && faqId.isNotEmpty) {
        final fRef = FirebaseFirestore.instance.collection('faqs').doc(faqId);
        await fRef.set({'askedCount': FieldValue.increment(1)}, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  Future<void> deleteConversation(String id) async {
    final u = AuthService.instance.currentUser!;
    await _conversationsFor(u.uid).doc(id).delete();
  }

  Future<Map<String, dynamic>?> getConversation(String id) async {
    final u = AuthService.instance.currentUser!;
    final doc = await _conversationsFor(u.uid).doc(id).get();
    if (!doc.exists) return null;
    return {...doc.data()!, 'id': doc.id};
  }
}