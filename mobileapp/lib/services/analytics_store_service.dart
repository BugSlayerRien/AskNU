import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsStoreService {
  AnalyticsStoreService._();
  static final AnalyticsStoreService instance = AnalyticsStoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _todayId() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  Future<void> incrementDaily(String field, {int by = 1}) async {
    final docId = _todayId();
    try {
      await _firestore.collection('analytics').doc(docId).set({
        'date': docId,
        field: FieldValue.increment(by),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
