import 'package:flutter/material.dart';

import '../models/faq.dart';
import '../services/faq_service.dart';
import '../widgets/notifications_modal.dart';
import 'faq_detail.dart';
import 'category_page.dart';
import 'bookmarks_screen.dart';
import '../widgets/bottom_footer.dart';
import '../widgets/category_grid.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  final FAQService service;

  const HomeScreen({super.key, required this.service});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _categories = [];
  List<FAQ> _faqs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await widget.service.loadFromAssets();
    setState(() {
      _faqs = widget.service.all();
      _categories = widget.service.categories();
    });
  }

  void _openFAQ(FAQ faq) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => FAQDetail(faq: faq, service: widget.service)));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [Hero(tag: 'app-logo', child: Padding(padding: EdgeInsets.only(right: 8), child: Image(image: AssetImage('assets/logo.png'), width: 36, height: 36, errorBuilder: (c, e, s) => CircleAvatar(backgroundColor: Theme.of(context).colorScheme.secondary, child: Icon(Icons.school, color: Colors.white))))), const SizedBox(width: 8), const Text('AskNU')]),
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () => showNotificationsModal(context)),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.bookmarks),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookmarksScreen(service: widget.service))),
            tooltip: 'Bookmarks',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final q = await showSearch(context: context, delegate: _FAQSearch(widget.service));
              if (q is FAQ) _openFAQ(q);
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final updated = await widget.service.fetchRemoteUpdate();
          if (updated) await _load();
        },
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: widget.service.streamRemoteFaqs(),
          builder: (context, snap) {
            final remote = snap.data;
            final useRemote = remote != null && remote.isNotEmpty;
            final faqs = useRemote ? remote.map((m) => FAQ.fromJson(m)).toList() : _faqs;
            final categories = useRemote ? faqs.map((f) => f.category).toSet().toList() : _categories;
            return ListView(padding: const EdgeInsets.all(16), children: [
              const Text('Browse by category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              CategoryGrid(categories: categories, onTap: _showCategory),
              const SizedBox(height: 16),
              const Text('Popular FAQs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...faqs.take(5).map((f) => ListTile(
                    title: Text(f.question),
                    subtitle: Text(f.category),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openFAQ(f),
                  ))
            ]);
          },
        ),
      ),
      bottomNavigationBar: BottomFooter(
        service: widget.service,
        onChat: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(service: widget.service))),
        onHome: () => Navigator.pushNamed(context, '/home'),
        isHome: true,
      ),
    );
  }

  void _showCategory(String category) {
    final list = widget.service.byCategory(category);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CategoryPage(category: category, faqs: list, service: widget.service)));
  }



}

/* _CategoryPage removed — use `CategoryPage` in category_page.dart instead */

class _FAQSearch extends SearchDelegate {
  final FAQService service;

  _FAQSearch(this.service) : super(searchFieldLabel: 'Search FAQs');

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = service.search(query);
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, i) {
        final f = results[i];
        return ListTile(
          title: _highlightText(f.question, query, Theme.of(context).textTheme.titleMedium!),
          subtitle: _highlightText(f.answer, query, Theme.of(context).textTheme.bodySmall!),
          onTap: () => close(context, f),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty ? <FAQ>[] : service.search(query);
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, i) {
        final f = suggestions[i];
        return ListTile(
          title: _highlightText(f.question, query, Theme.of(context).textTheme.titleMedium!),
          subtitle: _highlightText(f.category, query, Theme.of(context).textTheme.bodySmall!),
          onTap: () => close(context, f),
        );
      },
    );
  }

  Widget _highlightText(String text, String query, TextStyle style) {
    if (query.isEmpty) return Text(text, style: style);
    final low = text.toLowerCase();
    final q = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    while (true) {
      final idx = low.indexOf(q, start);
      if (idx < 0) {
        spans.add(TextSpan(text: text.substring(start), style: style));
        break;
      }
      if (idx > start) spans.add(TextSpan(text: text.substring(start, idx), style: style));
      spans.add(TextSpan(text: text.substring(idx, idx + q.length), style: style.copyWith(backgroundColor: Colors.yellow.withAlpha((0.6 * 255).round()))));
      start = idx + q.length;
    }
    return RichText(text: TextSpan(children: spans));
  }
}
