import 'dart:async';

import 'package:flutter/material.dart';

import '../models/faq.dart';
import '../services/faq_service.dart';
import '../services/audit_service.dart';
import '../services/analytics_store_service.dart';
import 'faq_detail.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _service = FAQService(remoteUrl: null);
  final _searchCtrl = TextEditingController();
  String _query = '';
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      _logSearch(value);
    });
  }

  Future<void> _logSearch(String value) async {
    final q = value.trim();
    if (q.length < 3) return;
    await AuditService.instance.logAudit(
      action: 'faq_search',
      metadata: {'query': q},
    );
    await AuditService.instance.logUserActivity(
      type: 'faq_search',
      description: 'Searched FAQs',
    );
    await AnalyticsStoreService.instance.incrementDaily('faqSearches');
  }

  List<FAQ> _filterFaqs(List<FAQ> faqs) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return faqs;

    bool matches(FAQ f) {
      final question = f.question.toLowerCase();
      final answer = f.answer.toLowerCase();
      final category = f.category.toLowerCase();
      return question.contains(q) || answer.contains(q) || category.contains(q);
    }

    return faqs.where(matches).toList();
  }

  Future<void> _openFAQ(FAQ faq) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FAQDetail(faq: faq, service: _service)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search FAQs',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.streamRemoteFaqs(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final raw = snapshot.data ?? [];
                final faqs = raw.map((m) => FAQ.fromJson(m)).toList();
                final results = _filterFaqs(faqs);

                if (results.isEmpty) {
                  return const Center(child: Text('No results found'));
                }

                return ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final f = results[i];
                    return ListTile(
                      title: Text(f.question),
                      subtitle: Text(f.category),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openFAQ(f),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
