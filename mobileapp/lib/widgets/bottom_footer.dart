import 'package:flutter/material.dart';

import '../services/faq_service.dart';
import '../services/auth_service.dart';

class BottomFooter extends StatelessWidget {
  final FAQService? service;
  final VoidCallback? onChat;
  final VoidCallback? onBrowse;
  final VoidCallback? onHome;
  final bool isHome;

  const BottomFooter({super.key, this.service, this.onChat, this.onBrowse, this.onHome, this.isHome = false});

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dCtx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(dCtx).pop(true), child: const Text('Sign Out')),
        ],
      ),
    );
    if (ok == true) {
      await AuthService.instance.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false);
      }
    }
  }

  void _openMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/about');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () {
                Navigator.pop(ctx);
                _confirmSignOut(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final gold = Theme.of(context).colorScheme.secondary;
    return BottomAppBar(
      color: color,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              tooltip: 'Home',
              icon: Icon(Icons.home, color: isHome ? Colors.white70 : gold),
              onPressed: isHome ? null : (onHome ?? () => Navigator.pushNamed(context, '/home')),
            ),
            IconButton(
              tooltip: 'Offices',
              icon: Icon(Icons.apartment, color: gold),
              onPressed: onBrowse ?? () => Navigator.pushNamed(context, '/offices'),
            ),
            // emphasized circular chat button (center)
            Container(
              width: 64,
              height: 64,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: gold,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gold.withAlpha((0.18 * 255).round()),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                tooltip: 'Chat',
                icon: Icon(Icons.chat_bubble, color: color),
                onPressed: onChat ?? () => Navigator.pushNamed(context, '/conversations'),
              ),
            ),
            IconButton(
              tooltip: 'Documents',
              icon: Icon(Icons.description, color: gold),
              onPressed: () => Navigator.pushNamed(context, '/document-requests'),
            ),
            IconButton(
              tooltip: 'Menu',
              icon: Icon(Icons.menu, color: gold),
              onPressed: () => _openMenu(context),
            ),
          ],
        ),
      ),
    );
  }
}
