import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final royal = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Usage', style: Theme.of(context).textTheme.headlineSmall),
            Text('Last 7 days', style: Theme.of(context).textTheme.bodySmall)
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _MetricCard(title: 'Active Users', value: '24', color: royal)),
            const SizedBox(width: 8),
            Expanded(child: _MetricCard(title: 'Bookmarks', value: '8', color: royal)),
          ]),
          const SizedBox(height: 12),
          Text('Most Asked Questions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('faqs').orderBy('askedCount', descending: true).limit(10).snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return const Center(child: Text('No data'));
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (c, i) => const Divider(),
                  itemBuilder: (c, i) {
                    final d = docs[i].data();
                    final title = d['question'] ?? 'Untitled';
                    final count = d['askedCount']?.toString() ?? '0';
                    return ListTile(title: Text(title), trailing: Text(count));
                  },
                );
              },
            ),
          )
        ]),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _MetricCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        ]),
      ),
    );
  }
}
