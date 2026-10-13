import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/faq_service.dart';
import '../../services/auth_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  final FAQService service;
  const AdminDashboardScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _AdminCard(
        icon: Icons.question_answer,
        title: 'Manage FAQs',
        color: Colors.blue,
        onTap: () => Navigator.pushNamed(context, '/admin/faqs'),
      ),
      _AdminCard(
        icon: Icons.people,
        title: 'Manage Users',
        color: Colors.green,
        onTap: () => Navigator.pushNamed(context, '/admin/users'),
      ),
      _AdminCard(
        icon: Icons.analytics,
        title: 'Analytics',
        color: Colors.purple,
        onTap: () => Navigator.pushNamed(context, '/admin/analytics'),
      ),
      _AdminCard(
        icon: Icons.settings,
        title: 'Settings',
        color: Colors.orange,
        onTap: () => Navigator.pushNamed(context, '/admin/settings'),
      ),
      _AdminCard(
        icon: Icons.description,
        title: 'Document Requests',
        color: Colors.teal,
        onTap: () => Navigator.pushNamed(context, '/document-requests'),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildProfileCard(context),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 900
                  ? 4
                  : constraints.maxWidth >= 600
                      ? 3
                      : 2;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                childAspectRatio: 1.4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: tiles,
              );
            },
          ),
          const SizedBox(height: 24),
          _buildStatsCard(),
        ],
      ),
    );
  }

  Future<int> _getTotalFAQs() async {
    try {
      final snapshot = await service.faqsCollection.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getTotalUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Widget _buildProfileCard(BuildContext context) {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Not signed in'),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final displayName = (data?['fullName'] ?? data?['name'])?.toString().trim();
        final resolvedName = (displayName != null && displayName.isNotEmpty)
            ? displayName
            : (currentUser.email?.split('@').first ?? 'Admin');
        final photoUrlRaw = data?['photoURL']?.toString();
        final photoUrl = (photoUrlRaw != null && photoUrlRaw.isNotEmpty)
          ? photoUrlRaw
          : currentUser.photoURL;
        final role = data?['role']?.toString().toUpperCase() ?? 'ADMIN';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).primaryColor,
                  backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                      ? NetworkImage(photoUrl)
                      : null,
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? Text(
                          resolvedName.isNotEmpty
                              ? resolvedName.substring(0, 1).toUpperCase()
                              : 'A',
                          style: const TextStyle(fontSize: 24, color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resolvedName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(currentUser.email ?? '', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Chip(
                            label: Text(role, style: const TextStyle(fontSize: 10)),
                            backgroundColor: Colors.purple.withValues(alpha: 0.2),
                          ),
                          const SizedBox(width: 8),
                          const Text('Administrator Panel'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            FutureBuilder<int>(
              future: _getTotalFAQs(),
              builder: (context, snapshot) => _StatItem(label: 'Total FAQs', value: '${snapshot.data ?? 0}'),
            ),
            FutureBuilder<int>(
              future: _getTotalUsers(),
              builder: (context, snapshot) => _StatItem(label: 'Total Users', value: '${snapshot.data ?? 0}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _AdminCard({required this.icon, required this.title, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}