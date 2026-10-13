import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Widget _sectionTitle(BuildContext context, String text) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }

  Widget _featureRow(BuildContext context, IconData icon, String title, String body) {
    final royal = Theme.of(context).colorScheme.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: royal),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(body),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroPill(Color bg, Color fg, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(30)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final heroText = Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        );
    final heroBody = Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70);
    return Scaffold(
      appBar: AppBar(title: const Text('About AskNU')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withOpacity(0.9),
                  scheme.secondary.withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AskNU', style: heroText),
                const SizedBox(height: 6),
                Text(
                  'Your student assistant for National University. Find answers fast, navigate policies, and reach campus services with confidence.',
                  style: heroBody,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _heroPill(Colors.white, scheme.primary, Icons.verified, 'Verified info'),
                    _heroPill(Colors.white, scheme.primary, Icons.school, 'Student focused'),
                    _heroPill(Colors.white, scheme.primary, Icons.support_agent, 'Help in minutes'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle(context, 'What you can do'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _featureRow(
                    context,
                    Icons.search,
                    'Find answers fast',
                    'Browse FAQs and handbook topics without digging through long documents.',
                  ),
                  const SizedBox(height: 14),
                  _featureRow(
                    context,
                    Icons.chat_bubble_outline,
                    'Chat for guidance',
                    'Ask questions and get step-by-step help for campus processes.',
                  ),
                  const SizedBox(height: 14),
                  _featureRow(
                    context,
                    Icons.bookmark_border,
                    'Save what matters',
                    'Bookmark important answers and keep them ready for later.',
                  ),
                  const SizedBox(height: 14),
                  _featureRow(
                    context,
                    Icons.notifications_none,
                    'Stay updated',
                    'Receive notifications for updates, requests, and office changes.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle(context, 'Core offices supported'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  Chip(label: Text('IT Services Office')),
                  Chip(label: Text('Student Affairs Office')),
                  Chip(label: Text('Registrar')),
                  Chip(label: Text('Treasury')),
                  Chip(label: Text('Facilities Management')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle(context, 'Version and support'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Version 1.0.0', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 6),
                  Text('Built for NU students to access reliable answers and campus services.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
