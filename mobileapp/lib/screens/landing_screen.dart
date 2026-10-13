import 'package:flutter/material.dart';
import 'chat_screen.dart';
import '../services/faq_service.dart';
import '../services/auth_service.dart';
import 'category_page.dart';
import '../widgets/bottom_footer.dart';
import 'bookmarks_screen.dart';
import '../widgets/notifications_modal.dart';
import 'admin/admin_dashboard.dart';

class LandingScreen extends StatefulWidget {
  final FAQService service;
  const LandingScreen({super.key, required this.service});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  List<String> _categories = [];
  List<String> _bookmarks = [];
  List _recent = [];
  bool _checkingAdmin = false;
  bool _isAdmin = false;
  String _userName = '';
  final Map<String, String> _categoryDescriptions = {
    'Enrollment': 'Steps to apply, register, and enroll in classes.',
    'Grading': 'Grading policies, GPA calculation and transcripts.',
    'Documents': 'Required forms, certificates, and where to submit them.',
    'Policies': 'Academic rules, honor code, and leave policies.',
    'Financial': 'Scholarships, discounts, and tuition assistance.',
    'Student Account': 'Account holds, ledgers, and student info updates.',
    'Payments': 'How to pay fees, channels, and refund rules.',
    'ID & Access': 'Student ID, access rules, and replacement steps.',
    'Library': 'Library services and off‑campus access.',
    'Academic': 'Program shifts, leave, and academic procedures.',
    'Graduation': 'Requirements, application, and schedules.',
    'Transfers': 'Credit evaluation and cross‑enrollment.',
    'Attendance': 'Attendance rules and absence limits.',
  };

  @override
  void initState() {
    super.initState();
    _load();
    _checkAdminAndLoadUser();
  }

  Future<void> _load() async {
    final loaded = await widget.service.loadFromFirestore();
    if (!loaded) {
      await widget.service.loadFromAssets();
    }
    final cats = widget.service.categories();
    final ids = await widget.service.getBookmarks();
    final labels = ids.map(_bookmarkLabel).where((v) => v.isNotEmpty).toList();
    setState(() {
      _categories = cats;
      _bookmarks = labels;
      _recent = widget.service.getRecentlyViewed();
    });
  }

  String _bookmarkLabel(String id) {
    final f = widget.service.getById(id);
    if (f == null) return id;
    final words = f.question.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    return words.isNotEmpty ? words.first : f.question;
  }

  Future<void> _checkAdminAndLoadUser() async {
    setState(() => _checkingAdmin = true);
    
    try {
      // Check if user is admin
      final isAdmin = await AuthService.instance.isAdmin();
      
      // Load user name
      final userDoc = await AuthService.instance.getUserDocument();
      final firstName = userDoc?['firstName']?.toString() ?? '';
      final fullName = userDoc?['fullName']?.toString() ?? '';
      final email = userDoc?['email']?.toString() ?? '';
      
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _userName = fullName.isNotEmpty ? fullName : 
                    firstName.isNotEmpty ? firstName : 
                    email.split('@').first;
          _checkingAdmin = false;
        });
      }
      
      // If user is admin, redirect to admin dashboard after a delay
      if (isAdmin) {
        if (!mounted) return;
        final navigator = Navigator.of(context);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          navigator.pushReplacement(
            MaterialPageRoute(
              builder: (context) => AdminDashboardScreen(service: widget.service),
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkingAdmin = false;
          _isAdmin = false;
        });
      }
    }
  }

  void _openCategories() {
    Navigator.of(context).pushNamed('/categories');
  }

  void _openOffices() {
    Navigator.of(context).pushNamed('/offices');
  }

  void _openChat() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(service: widget.service)));
  }

  void _openAdminDashboard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminDashboardScreen(service: widget.service),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final royalBlue = Theme.of(context).colorScheme.primary;
    final gold = Theme.of(context).colorScheme.secondary;

    if (_checkingAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Welcome back...',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Hero(
              tag: 'app-logo',
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Image.asset(
                  'assets/logo.png',
                  width: 28,
                  height: 28,
                  errorBuilder: (c, e, s) => CircleAvatar(
                    backgroundColor: gold,
                    child: const Icon(Icons.school, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Text('AskNU'),
          ],
        ),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: _openAdminDashboard,
              tooltip: 'Admin Dashboard',
            ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => showNotificationsModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            tooltip: 'Profile',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: royalBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: gold,
                      child: Text(
                        _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, $_userName!',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'How can we help you today?',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: Colors.white.withAlpha((0.9 * 255).round()),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Get instant answers about enrollment, grading, documents and more.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                        color: Colors.white.withAlpha((0.9 * 255).round()),
                      ),
                ),
                const SizedBox(height: 12),
                // Quick search field
                GestureDetector(
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    final q = await showSearch(
                      context: context,
                      delegate: _LandingSearch(widget.service),
                    );
                    if (!mounted) return;
                    if (q is Map && q['faq'] != null) {
                      navigator.pushNamed('/categories');
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.black54),
                        const SizedBox(width: 8),
                        Text(
                          'Search FAQs',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Quick actions
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final itemWidth = (width - 24) / 3;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: ElevatedButton.icon(
                      onPressed: _openCategories,
                      icon: const Icon(Icons.list, size: 18),
                      label: const Text('Browse FAQs'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/conversations'),
                      icon: const Icon(Icons.forum, size: 18),
                      label: const Text('Conversations'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: gold,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BookmarksScreen(service: widget.service),
                        ),
                      ),
                      icon: const Icon(Icons.bookmarks, size: 18),
                      label: const Text('Bookmarks'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Bookmarks section
          if (_bookmarks.isNotEmpty) ...[
            Row(
              children: [
                Text('Your Bookmarks', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BookmarksScreen(service: widget.service),
                    ),
                  ),
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _bookmarks.take(4).map<Widget>((b) {
                return Chip(
                  label: Text(b.toString()),
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Categories summary container
          if (_categories.isNotEmpty)
            Card(
              color: royalBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Explore Topics',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _openCategories,
                          child: const Text(
                            'View All',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = 3;
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.1,
                          children: _categories.map((c) {
                            final desc = _categoryDescriptions[c] ?? '';
                            return GestureDetector(
                              onTap: () {
                                final list = widget.service.byCategory(c);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CategoryPage(
                                      category: c,
                                      faqs: list,
                                      service: widget.service,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha((0.06 * 255).round()),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Expanded(
                                      child: Text(
                                        desc,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.white70),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),

          // Recently Viewed
          if (_recent.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recently Viewed',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: _recent.take(3).map((f) {
                        return ListTile(
                          leading: const Icon(Icons.history, size: 20),
                          title: Text(
                            (f as dynamic).question ?? '',
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () {
                            widget.service.markViewed(f.id);
                            // Navigate to FAQ detail or category
                            _openCategories();
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 20),

          // Footer
          Center(
            child: Text(
              '© AskNU — Your university assistant',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
      bottomNavigationBar: BottomFooter(
        service: widget.service,
        onChat: _openChat,
        onBrowse: _openOffices,
        onHome: () => Navigator.pushNamed(context, '/home'),
        isHome: true,
      ),
    );
  }
}

class _LandingSearch extends SearchDelegate {
  final FAQService service;
  _LandingSearch(this.service) : super(searchFieldLabel: 'Search FAQs');

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) {
    final results = service.search(query);
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, i) {
        final f = results[i];
        return ListTile(
          title: Text(f.question),
          subtitle: Text(f.category),
          onTap: () => close(context, {'faq': f}),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty ? <dynamic>[] : service.search(query);
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, i) {
        final f = suggestions[i];
        return ListTile(
          title: Text(f.question),
          subtitle: Text(f.category),
          onTap: () => close(context, {'faq': f}),
        );
      },
    );
  }
}