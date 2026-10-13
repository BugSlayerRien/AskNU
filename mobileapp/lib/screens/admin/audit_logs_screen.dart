import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogsScreen extends StatelessWidget {
  const AuditLogsScreen({super.key});

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
        title: const Text('Audit Logs'),
        automaticallyImplyLeading: true,
        leading: const BackButton(),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('audit_logs')
            .orderBy('createdAt', descending: true)
            .limit(300)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Unable to load audit logs. ${snapshot.error}',
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
            return const Center(child: Text('No audit logs yet'));
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
            itemBuilder: (context, index) {
              final key = dayKeys[index];
              final items = grouped[key] ?? [];
              final labelDate = key == 'Unknown'
                  ? 'Unknown date'
                  : _formatDateLabel(DateTime.parse(key));

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  initiallyExpanded: index == 0,
                  title: Text(labelDate, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${items.length} log${items.length == 1 ? '' : 's'}'),
                  children: [
                    const Divider(height: 1),
                    ...items.map((doc) {
                      final data = doc.data();
                      final action = data['action']?.toString() ?? 'Action';
                      final actor = data['actor']?.toString() ?? data['actorId']?.toString() ?? 'System';
                      final meta = data['metadata']?.toString() ?? '';
                      final createdAt = _formatTimestamp(data['createdAt']);
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.receipt_long, size: 18),
                        title: Text(action, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Actor: $actor'),
                            if (createdAt.isNotEmpty) Text('Time: $createdAt'),
                            if (meta.isNotEmpty) Text('Meta: $meta'),
                          ],
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
    );
  }
}
