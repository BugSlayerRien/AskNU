import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/audit_service.dart';

class NotificationsManagementScreen extends StatefulWidget {
  const NotificationsManagementScreen({super.key});

  @override
  State<NotificationsManagementScreen> createState() => _NotificationsManagementScreenState();
}

class _NotificationsManagementScreenState extends State<NotificationsManagementScreen> {
  final _firestore = FirebaseFirestore.instance;

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateLabel(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _createNotification() async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    bool sendToAll = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Notification'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bodyCtrl,
                decoration: const InputDecoration(labelText: 'Body'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Send to all users'),
                value: sendToAll,
                onChanged: (v) {
                  sendToAll = v;
                  (dialogContext as Element).markNeedsBuild();
                },
              ),
              if (!sendToAll)
                TextField(
                  controller: targetCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Target Email or UID',
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final title = titleCtrl.text.trim();
    final body = bodyCtrl.text.trim();
    if (title.isEmpty) return;

    final currentUser = AuthService.instance.currentUser;
    final adminDoc = await AuthService.instance.getUserDocument();
    final createdBy = adminDoc?['email'] ?? currentUser?.email ?? 'admin';

    if (sendToAll) {
      final users = await _firestore.collection('users').get();
      final batch = _firestore.batch();
      for (final doc in users.docs) {
        final ref = _firestore.collection('notifications').doc();
        batch.set(ref, {
          'userId': doc.id,
          'title': title,
          'body': body,
          'type': 'admin_broadcast',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': createdBy,
        });
      }
      await batch.commit();
      await AuditService.instance.logAudit(
        action: 'notification_send_all',
        metadata: {'title': title},
      );
    } else {
      final target = targetCtrl.text.trim();
      if (target.isEmpty) return;

      String? uid;
      if (target.contains('@')) {
        final snap = await _firestore
            .collection('users')
            .where('email', isEqualTo: target)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) uid = snap.docs.first.id;
      } else {
        uid = target;
      }

      if (uid == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found for that email/UID')),
        );
        return;
      }

      await _firestore.collection('notifications').add({
        'userId': uid,
        'title': title,
        'body': body,
        'type': 'admin_broadcast',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
      });
      await AuditService.instance.logAudit(
        action: 'notification_send',
        metadata: {'title': title, 'userId': uid},
        targetUserId: uid,
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification sent')), 
    );
  }

  Future<void> _deleteNotification(String id) async {
    await _firestore.collection('notifications').doc(id).delete();
    await AuditService.instance.logAudit(
      action: 'notification_delete',
      metadata: {'id': id},
    );
  }

  String _formatTimestamp(dynamic value) {
    if (value is Timestamp) {
      final d = value.toDate();
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications Management'),
        automaticallyImplyLeading: true,
        leading: const BackButton(),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('notifications')
            .where('type', isEqualTo: 'admin_broadcast')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Unable to load notifications. ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = (snapshot.data?.docs ?? []).toList()
            ..sort((a, b) {
              final aTime = a.data()['createdAt'] as Timestamp?;
              final bTime = b.data()['createdAt'] as Timestamp?;
              return (bTime?.millisecondsSinceEpoch ?? 0)
                  .compareTo(aTime?.millisecondsSinceEpoch ?? 0);
            });
          if (docs.isEmpty) {
            return const Center(child: Text('No notifications yet'));
          }

          final grouped = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
          for (final doc in docs) {
            final data = doc.data();
            final createdAt = _readDate(data['createdAt']);
            final key = createdAt != null ? _formatDateKey(createdAt) : 'Unknown';
            grouped.putIfAbsent(key, () => []).add(doc);
          }

          final dayKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: dayKeys.length,
            itemBuilder: (context, i) {
              final key = dayKeys[i];
              final items = grouped[key] ?? [];
              final labelDate = key == 'Unknown'
                  ? 'Unknown date'
                  : _formatDateLabel(DateTime.parse(key));

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  initiallyExpanded: i == 0,
                  title: Text(labelDate, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${items.length} notification${items.length == 1 ? '' : 's'}'),
                  children: [
                    const Divider(height: 1),
                    ...items.map((doc) {
                      final data = doc.data();
                      final title = data['title']?.toString() ?? 'Notification';
                      final body = data['body']?.toString() ?? '';
                      final userId = data['userId']?.toString() ?? '';
                      final createdAt = _formatTimestamp(data['createdAt']);
                      return ListTile(
                        dense: true,
                        title: Text(title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (body.isNotEmpty) Text(body),
                            if (userId.isNotEmpty) Text('User: $userId'),
                            if (createdAt.isNotEmpty) Text('Sent: $createdAt'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteNotification(doc.id),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNotification,
        child: const Icon(Icons.add),
      ),
    );
  }
}
