import 'package:flutter/material.dart';

import '../models/faq.dart';
import '../services/faq_service.dart';
import '../services/faq_summary_service.dart';
import '../services/audit_service.dart';
import '../services/analytics_store_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FAQDetail extends StatefulWidget {
  final FAQ faq;
  final FAQService service;

  const FAQDetail({super.key, required this.faq, required this.service});

  @override
  State<FAQDetail> createState() => _FAQDetailState();
}

class _FAQDetailState extends State<FAQDetail> {
  bool _bookmarked = false;
  bool _summarizing = false;

  @override
  void initState() {
    super.initState();
    widget.service.markViewed(widget.faq.id);
    widget.service.isBookmarked(widget.faq.id).then((v) => setState(() => _bookmarked = v));
    _logView();
  }

  Future<void> _logView() async {
    try {
      final faqId = widget.faq.id;
      await FirebaseFirestore.instance.collection('faqs').doc(faqId).set({
        'views': FieldValue.increment(1),
        'viewCount': FieldValue.increment(1),
        'lastViewedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await AuditService.instance.logAudit(
        action: 'faq_view',
        metadata: {'faqId': faqId, 'question': widget.faq.question},
      );
      await AuditService.instance.logUserActivity(
        type: 'faq_view',
        description: 'Viewed FAQ',
      );
      await AnalyticsStoreService.instance.incrementDaily('faqViews');
    } catch (_) {}
  }

  Future<void> _toggle() async {
    final next = !_bookmarked;
    setState(() => _bookmarked = next);
    try {
      await widget.service.toggleBookmark(widget.faq.id);
      final v = await widget.service.isBookmarked(widget.faq.id);
      if (!mounted) return;
      setState(() => _bookmarked = v);
    } catch (_) {
      if (!mounted) return;
      setState(() => _bookmarked = !next);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update bookmark')),
      );
    }
  }

  Future<void> _generateSummary() async {
    setState(() => _summarizing = true);
    try {
      await FAQSummaryService.instance.generateAndSaveSummary(widget.faq);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Summary generated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate summary: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _summarizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.faq.question, maxLines: 2, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                _bookmarked ? Icons.bookmark : Icons.bookmark_border,
                key: ValueKey(_bookmarked),
                color: _bookmarked ? Theme.of(context).colorScheme.secondary : null,
              ),
            ),
            onPressed: _toggle,
            tooltip: _bookmarked ? 'Remove bookmark' : 'Bookmark',
          ),
          IconButton(
            icon: _summarizing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome),
            onPressed: _summarizing ? null : _generateSummary,
            tooltip: 'Generate summary',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.faq.category, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            Text(widget.faq.question, style: Theme.of(context).textTheme.headlineSmall),
            if (_bookmarked) ...[
              const SizedBox(height: 8),
              Chip(
                label: const Text('Saved'),
                avatar: const Icon(Icons.bookmark, size: 16),
              ),
            ],
            const SizedBox(height: 16),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('faqs')
                  .doc(widget.faq.id)
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data();
                final summary = data?['summary']?.toString().trim() ?? '';
                if (summary.isEmpty) return const SizedBox();
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Summary', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text(summary),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(widget.faq.answer, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4)),
          ]),
        ),
      ),
    );
  }
}
