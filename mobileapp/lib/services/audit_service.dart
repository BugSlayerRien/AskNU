import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class AuditService {
  AuditService._();
  static final AuditService instance = AuditService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> logAudit({
    required String action,
    Map<String, dynamic>? metadata,
    String? targetUserId,
  }) async {
    try {
      final user = AuthService.instance.currentUser;
      final doc = await AuthService.instance.getUserDocument();
      await _firestore.collection('audit_logs').add({
        'action': action,
        'actorId': user?.uid,
        'actor': doc?['email'] ?? user?.email,
        'targetUserId': targetUserId,
        'metadata': metadata ?? <String, dynamic>{},
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> logUserActivity({
    required String type,
    String? description,
    String? userId,
    String? userEmail,
  }) async {
    try {
      final user = AuthService.instance.currentUser;
      final doc = await AuthService.instance.getUserDocument();
      await _firestore.collection('user_activity').add({
        'type': type,
        'description': description ?? '',
        'userId': userId ?? user?.uid,
        'userEmail': userEmail ?? doc?['email'] ?? user?.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}
