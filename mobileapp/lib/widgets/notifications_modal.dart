import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

Future<void> showNotificationsModal(BuildContext context) async {
  return showModalBottomSheet(context: context, builder: (ctx) {
    final user = AuthService.instance.currentUser;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Notifications', style: Theme.of(ctx).textTheme.titleMedium), TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close'))]),
          const SizedBox(height: 8),
          if (user == null)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Please sign in to view notifications'),
            )
          else
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: user.uid)
                  .limit(50)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Error: ${snap.error}'),
                  );
                }
                final docs = (snap.data?.docs ?? []).toList();
                docs.sort((a, b) {
                  final at = a.data()['createdAt'];
                  final bt = b.data()['createdAt'];
                  if (at is Timestamp && bt is Timestamp) {
                    return bt.compareTo(at);
                  }
                  return 0;
                });
                if (docs.isEmpty) return const Padding(padding: EdgeInsets.all(12), child: Text('No notifications'));
                return Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: docs.length,
                    separatorBuilder: (c, i) => const Divider(),
                    itemBuilder: (c, i) {
                      final it = docs[i].data();
                      final title = (it['title'] ?? 'Notification').toString();
                      final body = (it['body'] ?? it['text'] ?? '').toString();
                      final createdAt = it['createdAt'];
                      String time = '';
                      if (createdAt is Timestamp) {
                        final d = createdAt.toDate();
                        time = '${d.month}/${d.day}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
                      }
                      return ListTile(
                        title: Text(title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (body.isNotEmpty) Text(body),
                            if (time.isNotEmpty) Text(time),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            )
        ]),
      ),
    );
  });
}
