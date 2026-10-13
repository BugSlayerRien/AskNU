import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/audit_service.dart';
import '../services/analytics_store_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> _markRead(String id) async {
    await FirebaseFirestore.instance.collection('notifications').doc(id).set({
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await AuditService.instance.logAudit(
      action: 'notification_read',
      metadata: {'notificationId': id},
    );
    await AuditService.instance.logUserActivity(
      type: 'notification_read',
      description: 'Opened notification',
    );
    await AnalyticsStoreService.instance.incrementDaily('notificationReads');
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: user == null
          ? const Center(child: Text('Sign in to see your notifications'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data?.docs ?? [];
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.notifications_none, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No notifications yet'),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final data = items[index].data();
                    final docId = items[index].id;
                    final title = data['title']?.toString() ?? 'Notification';
                    final body = data['body']?.toString() ?? '';
                    final read = data['read'] == true;

                    return ListTile(
                      leading: Icon(
                        read ? Icons.notifications : Icons.notifications_active,
                        color: read ? Colors.grey : Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(title),
                      subtitle: body.isNotEmpty ? Text(body) : null,
                      trailing: read
                          ? null
                          : const Icon(Icons.circle, size: 8, color: Colors.red),
                      onTap: read ? null : () => _markRead(docId),
                    );
                  },
                );
              },
            ),
    );
  }
}
