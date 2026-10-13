import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await AuthService.instance.getUserDocument();
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.instance.isAdmin(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data == true;

        if (snapshot.connectionState == ConnectionState.waiting || _loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!isAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('Settings')),
            body: const Center(child: Text('Admin access required')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: ListView(
            children: [
              _buildUserSection(),
              const Divider(),
              _buildAdminSection(),
              const Divider(),
              _buildDangerZone(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserSection() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: AuthService.instance.getUserDocument(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isAdmin = (user?['role']?.toString().toLowerCase() ?? '') == 'admin';
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isAdmin ? Colors.purple : Colors.blue,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          title: Text(user?['email'] ?? 'Loading...'),
          subtitle: Text(isAdmin ? 'Administrator' : 'User'),
        );
      },
    );
  }

  Widget _buildAdminSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Manage User Accounts'),
            subtitle: const Text('Add or remove user access'),
            onTap: () => Navigator.pushNamed(context, '/admin/users'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('Notifications Management'),
            subtitle: const Text('Create and manage notifications'),
            onTap: () => Navigator.pushNamed(context, '/admin/notifications'),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Audit Logs'),
            subtitle: const Text('Review system actions'),
            onTap: () => Navigator.pushNamed(context, '/admin/audit-logs'),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                  onTap: () => _showSignOutDialog(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await AuthService.instance.signOut();
              if (!dialogContext.mounted) return;
              Navigator.pushNamedAndRemoveUntil(dialogContext, '/sign-in', (route) => false);
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  
}

