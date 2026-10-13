import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_settings_service.dart';
import '../services/audit_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _analyticsKey = 'settings_analytics';
  static const _autoUpdateKey = 'settings_auto_update';

  bool _loading = true;
  bool _notificationsEnabled = true;
  bool _analyticsEnabled = true;
  bool _autoUpdateEnabled = true;
  bool _darkMode = false;
  final _settings = AppSettingsService.instance;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    await _settings.load();
    setState(() {
      _notificationsEnabled = _settings.notificationsEnabled.value;
      _darkMode = _settings.themeMode.value == ThemeMode.dark;
      _loading = false;
    });
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _analyticsEnabled = prefs.getBool(_analyticsKey) ?? true;
      _autoUpdateEnabled = prefs.getBool(_autoUpdateKey) ?? true;
    });
  }

  Future<void> _setPreference(String key, bool value, void Function(bool) onUpdate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (!mounted) return;
    setState(() => onUpdate(value));
    await _logSettingChange(key, value);
  }

  Future<void> _setNotifications(bool value) async {
    await _settings.setNotificationsEnabled(value);
    if (!mounted) return;
    setState(() => _notificationsEnabled = value);
    await _logSettingChange('notifications', value);
  }

  Future<void> _setDarkMode(bool value) async {
    await _settings.setDarkMode(value);
    if (!mounted) return;
    setState(() => _darkMode = value);
    await _logSettingChange('dark_mode', value);
  }

  Future<void> _logSettingChange(String key, bool value) async {
    final userId = AuthService.instance.currentUser?.uid;
    await AuditService.instance.logAudit(
      action: 'settings_change',
      metadata: {'key': key, 'value': value},
      targetUserId: userId,
    );
    await AuditService.instance.logUserActivity(
      type: 'settings_change',
      description: 'Updated setting: $key',
      userId: userId,
    );
  }

  Future<void> _clearBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bookmarks');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bookmarks cleared')));
  }

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false);
  }

  Future<void> _showSupport() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Support'),
        content: const Text('Reach the AskNU team at support@asknu.edu or call (555) 010-8675.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Preferences', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Enable notifications'),
            subtitle: const Text('Receive campus announcements and alerts'),
            value: _notificationsEnabled,
            onChanged: _setNotifications,
          ),
          SwitchListTile(
            title: const Text('Dark mode'),
            subtitle: const Text('Use dark theme throughout the app'),
            value: _darkMode,
            onChanged: _setDarkMode,
          ),
          SwitchListTile(
            title: const Text('Share anonymous analytics'),
            subtitle: const Text('Help us improve the app with usage data'),
            value: _analyticsEnabled,
            onChanged: (value) => _setPreference(_analyticsKey, value, (v) => _analyticsEnabled = v),
          ),
          SwitchListTile(
            title: const Text('Automatic updates'),
            subtitle: const Text('Fetch new FAQs and policy changes automatically'),
            value: _autoUpdateEnabled,
            onChanged: (value) => _setPreference(_autoUpdateKey, value, (v) => _autoUpdateEnabled = v),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Manage profile'),
            subtitle: const Text('Update your name or contact details'),
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          ListTile(
            leading: const Icon(Icons.bookmarks),
            title: const Text('Clear bookmarks'),
            subtitle: const Text('Remove saved FAQs to start fresh'),
            onTap: _clearBookmarks,
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Get support'),
            subtitle: const Text('Ask questions or report issues'),
            onTap: _showSupport,
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: _signOut,
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About AskNU'),
            subtitle: const Text('Version 1.0.0 · Built for NU students'),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'AskNU',
              applicationVersion: '1.0.0',
              applicationLegalese: '© ${DateTime.now().year} AskNU',
            ),
          ),
        ],
      ),
    );
  }
}
