import 'package:flutter/material.dart';

import '../services/faq_service.dart';
import 'faq_detail.dart';

class BookmarksScreen extends StatefulWidget {
  final FAQService service;
  const BookmarksScreen({super.key, required this.service});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List _bookmarked = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await widget.service.loadFromFirestore();
    if (!loaded) {
      await widget.service.loadFromAssets();
    }
    final list = await widget.service.getBookmarkedFaqs();
    setState(() => _bookmarked = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: _bookmarked.isEmpty
          ? Center(child: Text('No bookmarks yet', style: Theme.of(context).textTheme.bodyLarge))
          : ListView.builder(
              itemCount: _bookmarked.length,
              itemBuilder: (context, i) {
                final f = _bookmarked[i];
                return ListTile(
                  title: Text(f.question),
                  subtitle: Text(f.category),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FAQDetail(faq: f, service: widget.service))),
                );
              },
            ),
    );
  }
}
