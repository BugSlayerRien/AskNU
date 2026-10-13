import 'package:flutter/material.dart';

import '../services/faq_service.dart';
import '../widgets/bottom_footer.dart';
import '../widgets/category_grid.dart';
import 'category_page.dart';
import 'chat_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final FAQService service;

  const CategoriesScreen({super.key, required this.service});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<String> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refreshCategories();
  }

  Future<void> _refreshCategories() async {
    await widget.service.loadFromAssets();
    if (!mounted) return;
    setState(() {
      _categories = widget.service.categories();
      _loading = false;
    });
  }

  void _openCategory(String category) {
    final list = widget.service.byCategory(category);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CategoryPage(category: category, faqs: list, service: widget.service),
    ));
  }

  void _openChat() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(service: widget.service)));
  }

  void _openOffices() {
    Navigator.of(context).pushNamed('/offices');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse FAQs')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshCategories,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Browse by category', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  CategoryGrid(categories: _categories, onTap: _openCategory),
                ],
              ),
            ),
      bottomNavigationBar: BottomFooter(
        service: widget.service,
        onChat: _openChat,
        onBrowse: _openOffices,
        onHome: () => Navigator.pushNamed(context, '/home'),
        isHome: false,
      ),
    );
  }
}
