import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserActivityScreen extends StatelessWidget {
  const UserActivityScreen({super.key});

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
        title: const Text('User Activity Timeline'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('user_activity')
            .orderBy('createdAt', descending: true)
            .limit(300)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Unable to load user activity. ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No activity yet'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final data = docs[i].data();
              final user = data['userEmail']?.toString() ?? data['userId']?.toString() ?? 'User';
              final type = data['type']?.toString() ?? 'Activity';
              final description = data['description']?.toString() ?? '';
              final createdAt = _formatTimestamp(data['createdAt']);

              return ListTile(
                title: Text(type),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user),
                    if (description.isNotEmpty) Text(description),
                    if (createdAt.isNotEmpty) Text('Time: $createdAt'),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
