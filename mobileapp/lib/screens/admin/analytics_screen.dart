import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Remove: import 'package:charts_flutter/flutter.dart' as charts;

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _dateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_dateRange != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _StatCard(
                  title: 'Total Users',
                  valueFuture: _getTotalUsers(),
                  icon: Icons.people,
                  color: Colors.blue,
                ),
                _StatCard(
                  title: 'Total FAQs',
                  valueFuture: _getTotalFAQs(),
                  icon: Icons.question_answer,
                  color: Colors.green,
                ),
                _StatCard(
                  title: 'Active Users',
                  valueFuture: _getActiveUsers(),
                  icon: Icons.person_pin_circle,
                  color: Colors.orange,
                ),
                _StatCard(
                  title: 'FAQ Views',
                  valueFuture: _getTotalFAQViews(),
                  icon: Icons.visibility,
                  color: Colors.deepPurple,
                ),
                _StatCard(
                  title: 'Bookmarks',
                  valueFuture: _getTotalBookmarks(),
                  icon: Icons.bookmarks,
                  color: Colors.teal,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Analytics (Last 30 Days)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildAnalyticsSummary(),
            const SizedBox(height: 16),
            _buildAnalyticsCharts(),
            const SizedBox(height: 32),
            const Text(
              'Most Asked Questions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTopQuestions(),
            const SizedBox(height: 32),
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  // Remove the chart-related methods and keep only basic stats
  // ... keep other methods except chart-related ones

  // Simplified version without charts
  Widget _buildRecentActivity() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .orderBy('lastLogin', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final users = snapshot.data!.docs;
        
        return Card(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>;
              
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    data['firstName']?.toString().substring(0, 1).toUpperCase() ??
                    data['email']?.toString().substring(0, 1).toUpperCase() ??
                    '?',
                  ),
                ),
                title: Text(data['fullName']?.isNotEmpty == true
                    ? data['fullName']!
                    : data['email'] ?? 'Unknown'),
                subtitle: Text(
                  data['lastLogin'] != null
                      ? 'Last active: ${_formatTimestamp(data['lastLogin'])}'
                      : 'Never active',
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTopQuestions() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('faqs')
          .limit(200)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Text('Analytics data is not accessible. Update Firestore rules to allow admin reads for the analytics collection.'),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Text('Not enough data to show top questions yet.'),
            ),
          );
        }

        int resolveCount(Map<String, dynamic> data) {
          final views = data['views'];
          final asked = data['askedCount'];
          if (views is int) return views;
          if (views is String) return int.tryParse(views) ?? 0;
          if (asked is int) return asked;
          if (asked is String) return int.tryParse(asked) ?? 0;
          return 0;
        }

        final top = docs
            .map((d) => MapEntry(d, resolveCount(d.data() as Map<String, dynamic>)))
            .where((entry) => entry.value > 0)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        if (top.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Text('Not enough data to show top questions yet.'),
            ),
          );
        }

        return Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: top.length > 5 ? 5 : top.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = top[index].key.data() as Map<String, dynamic>;
              final question = data['question']?.toString() ?? 'FAQ';
              final count = top[index].value;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                title: Text(question, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Text('$count views', style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsSummary() {
    final range = _dateRange ?? DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
    final startId = _formatDateId(range.start);
    final endId = _formatDateId(range.end);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('analytics')
          .orderBy(FieldPath.documentId)
          .startAt([startId])
          .endAt([endId])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text('Unable to load analytics summary. ${snapshot.error}'),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Text('No analytics data yet.'),
            ),
          );
        }

        int sumField(String field) {
          int total = 0;
          for (final d in docs) {
            final v = d.data()[field];
            if (v is int) total += v;
            if (v is String) total += int.tryParse(v) ?? 0;
          }
          return total;
        }

        final signIns = sumField('signIns');
        final signUps = sumField('signUps');
        final faqViews = sumField('faqViews');
        final faqSearches = sumField('faqSearches');
        final notifReads = sumField('notificationReads');
        final docRequests = sumField('documentRequests');
        final docCancels = sumField('documentCancels');
        final docStatusChanges = sumField('documentStatusChanges');

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _TinyStat(label: 'Sign ins', value: signIns),
            _TinyStat(label: 'Sign ups', value: signUps),
            _TinyStat(label: 'FAQ views', value: faqViews),
            _TinyStat(label: 'FAQ searches', value: faqSearches),
            _TinyStat(label: 'Notification reads', value: notifReads),
            _TinyStat(label: 'Doc requests', value: docRequests),
            _TinyStat(label: 'Doc cancels', value: docCancels),
            _TinyStat(label: 'Doc status', value: docStatusChanges),
          ],
        );
      },
    );
  }

  Widget _buildAnalyticsCharts() {
    final range = _dateRange ?? DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
    final startId = _formatDateId(range.start);
    final endId = _formatDateId(range.end);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('analytics')
          .orderBy(FieldPath.documentId)
          .startAt([startId])
          .endAt([endId])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        final series = _buildDailySeries(range, docs);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DailyMetricChart(title: 'Sign ins', color: Colors.blue, values: series.signIns),
            const SizedBox(height: 12),
            _DailyMetricChart(title: 'FAQ views', color: Colors.deepPurple, values: series.faqViews),
            const SizedBox(height: 12),
            _DailyMetricChart(title: 'Document requests', color: Colors.teal, values: series.documentRequests),
          ],
        );
      },
    );
  }

  _DailySeries _buildDailySeries(DateTimeRange range, List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final byId = <String, Map<String, dynamic>>{};
    for (final d in docs) {
      byId[d.id] = d.data();
    }

    final days = <DateTime>[];
    var cursor = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    while (!cursor.isAfter(end)) {
      days.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }

    int readField(Map<String, dynamic>? data, String field) {
      final v = data?[field];
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    final signIns = <int>[];
    final faqViews = <int>[];
    final documentRequests = <int>[];

    for (final day in days) {
      final id = _formatDateId(day);
      final data = byId[id];
      signIns.add(readField(data, 'signIns'));
      faqViews.add(readField(data, 'faqViews'));
      documentRequests.add(readField(data, 'documentRequests'));
    }

    return _DailySeries(
      signIns: signIns,
      faqViews: faqViews,
      documentRequests: documentRequests,
    );
  }

  String _formatDateId(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  String _formatDate(DateTime d) {
    return '${d.month}/${d.day}/${d.year}';
  }

  String _formatTimestamp(dynamic ts) {
    try {
      DateTime dt;
      if (ts is Timestamp) {
        dt = ts.toDate();
      } else if (ts is DateTime) {
        dt = ts;
      } else if (ts is String) {
        dt = DateTime.parse(ts);
      } else {
        return ts.toString();
      }
      return '${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return ts.toString();
    }
  }

  Future<int> _getTotalUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.size;
  }

  Future<int> _getTotalFAQs() async {
    try {
      final snapshot = await _firestore.collection('faqs').get();
      return snapshot.size;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getActiveUsers() async {
    final range = _dateRange ?? DateTimeRange(start: DateTime.now().subtract(const Duration(days: 30)), end: DateTime.now());
    try {
      final startTs = Timestamp.fromDate(range.start);
      final snapshot = await _firestore
          .collection('users')
          .where('lastLogin', isGreaterThanOrEqualTo: startTs)
          .get();
      return snapshot.size;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getTotalFAQViews() async {
    try {
      final snapshot = await _firestore.collection('faqs').get();
      int sum = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final v = data['views'];
        if (v is int) {
          sum += v;
        } else if (v is String) {
          sum += int.tryParse(v) ?? 0;
        }
      }
      return sum;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getTotalBookmarks() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      int sum = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final v = data['bookmarksCount'];
        if (v is int) {
          sum += v;
        } else if (v is String) {
          sum += int.tryParse(v) ?? 0;
        }
      }
      return sum;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final Future<int> valueFuture;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.valueFuture, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  FutureBuilder<int>(
                    future: valueFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2));
                      }
                      final val = snapshot.data ?? 0;
                      return Text('$val', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _TinyStat extends StatelessWidget {
  final String label;
  final int value;

  const _TinyStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _DailySeries {
  final List<int> signIns;
  final List<int> faqViews;
  final List<int> documentRequests;

  const _DailySeries({
    required this.signIns,
    required this.faqViews,
    required this.documentRequests,
  });
}

class _DailyMetricChart extends StatelessWidget {
  final String title;
  final Color color;
  final List<int> values;

  const _DailyMetricChart({required this.title, required this.color, required this.values});

  @override
  Widget build(BuildContext context) {
    final total = values.fold<int>(0, (sum, v) => sum + v);
    final maxValue = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
    final lastValue = values.isEmpty ? 0 : values.last;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(label: 'Last', value: lastValue, color: color),
                _MetricChip(label: 'Max', value: maxValue, color: color),
                _MetricChip(label: 'Total', value: total, color: color),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: CustomPaint(
                painter: _BarChartPainter(values: values, color: color),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MetricChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<int> values;
  final Color color;

  _BarChartPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final barCount = values.length;
    final barWidth = size.width / barCount;
    final paint = Paint()..color = color.withValues(alpha: 0.7);
    final baseline = size.height - 4;

    final labelStyle = TextStyle(
      color: color.withValues(alpha: 0.85),
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    for (var i = 0; i < barCount; i++) {
      final v = values[i];
      final h = maxValue == 0 ? 0.0 : (v / maxValue) * (size.height - 8.0);
      final x = i * barWidth;
      final rect = Rect.fromLTWH(x + 1, baseline - h, barWidth - 2, h);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), paint);

      if (v > 0 && barWidth >= 18) {
        final textSpan = TextSpan(text: '$v', style: labelStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(maxWidth: barWidth - 4);
        final labelX = x + (barWidth - textPainter.width) / 2;
        final labelY = (baseline - h) - textPainter.height - 2;
        if (labelY >= 0) {
          textPainter.paint(canvas, Offset(labelX, labelY));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}