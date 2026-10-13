import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/audit_service.dart';
import '../services/app_settings_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  Map<String, dynamic>? _userDoc;
  bool _loading = false;
  final _nameController = TextEditingController();
  final _photoUrlController = TextEditingController();
  final _phoneController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _departmentController = TextEditingController();
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;
  final _settings = AppSettingsService.instance;

  @override
  void initState() {
    super.initState();
    _user = AuthService.instance.currentUser;
    AuthService.instance.authStateChanges().listen((u) {
      if (!mounted) return;
      setState(() => _user = u);
      if (u != null) {
        _loadUserDoc(u);
        _listenToUserDoc(u);
      } else {
        _userDocSub?.cancel();
        _userDocSub = null;
      }
    });
    if (_user != null) {
      _loadUserDoc(_user);
      _listenToUserDoc(_user!);
    }
  }

  void _listenToUserDoc(User user) {
    _userDocSub?.cancel();
    _userDocSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
      if (!doc.exists || !mounted) return;
      final data = doc.data();
      if (data == null) return;

      if (!_loading) {
        final fullName = (data['fullName'] ?? data['name'] ?? '').toString();
        _nameController.text = fullName;
        _photoUrlController.text = (data['photoURL'] ?? '').toString();
        _phoneController.text = (data['phone'] ?? '').toString();
        _studentIdController.text = (data['studentId'] ?? '').toString();
        _departmentController.text = (data['department'] ?? '').toString();
      }

      setState(() {
        _userDoc = data;
        _notificationsEnabled = data['notifications'] ?? true;
        _darkMode = data['darkMode'] ?? false;
      });
      _settings.setNotificationsEnabled(_notificationsEnabled);
      _settings.setDarkMode(_darkMode);
    });
  }

  Future<void> _loadUserDoc(User? u) async {
    if (u == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(u.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (!mounted) return;
        final fullName = (data['fullName'] ?? data['name'] ?? '').toString();
        setState(() {
          _userDoc = data;
          _nameController.text = fullName;
          _photoUrlController.text = (data['photoURL'] ?? '').toString();
          _phoneController.text = (data['phone'] ?? '').toString();
          _studentIdController.text = (data['studentId'] ?? '').toString();
          _departmentController.text = (data['department'] ?? '').toString();
          _notificationsEnabled = data['notifications'] ?? true;
          _darkMode = data['darkMode'] ?? false;
        });
        _settings.setNotificationsEnabled(_notificationsEnabled);
        _settings.setDarkMode(_darkMode);
      }
    } catch (_) {}
  }

  Future<void> _updatePreferences({bool? notifications, bool? darkMode}) async {
    if (_user == null) return;
    final nextNotifications = notifications ?? _notificationsEnabled;
    final nextDarkMode = darkMode ?? _darkMode;
    _settings.setNotificationsEnabled(nextNotifications);
    _settings.setDarkMode(nextDarkMode);
    try {
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
        'notifications': nextNotifications,
        'darkMode': nextDarkMode,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _updateProfile() async {
    if (_user == null) return;
    
    setState(() => _loading = true);
    try {
      final fullName = _nameController.text.trim();
      final nameParts = fullName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
        'fullName': fullName,
        'name': fullName,
        'firstName': firstName,
        'lastName': lastName,
        'photoURL': _photoUrlController.text.trim(),
        'phone': _phoneController.text.trim(),
        'studentId': _studentIdController.text.trim(),
        'department': _departmentController.text.trim(),
        'notifications': _notificationsEnabled,
        'darkMode': _darkMode,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await AuditService.instance.logAudit(
        action: 'profile_update',
        metadata: {'fullName': fullName},
        targetUserId: _user!.uid,
      );
      await AuditService.instance.logUserActivity(
        type: 'profile_update',
        description: 'Updated profile details',
        userId: _user!.uid,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        _loadUserDoc(_user); // Reload data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await AuthService.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false);
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('This action cannot be undone. All your data will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() => _loading = true);
      try {
        // Delete user data from Firestore
        await FirebaseFirestore.instance.collection('users').doc(_user!.uid).delete();
        
        // Delete user from Firebase Auth
        await _user!.delete();
        
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting account: ${e.toString()}')),
          );
        }
      }
    }
  }

  Widget _buildStatCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userDocSub?.cancel();
    _nameController.dispose();
    _photoUrlController.dispose();
    _phoneController.dispose();
    _studentIdController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photoUrlRaw = _userDoc?['photoURL']?.toString();
    final photoUrl = (photoUrlRaw != null && photoUrlRaw.isNotEmpty)
      ? photoUrlRaw
      : _user?.photoURL;
    final displayName = (_userDoc?['fullName'] ?? _userDoc?['name'])?.toString().trim();
    final resolvedName = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : (_user?.email?.split('@').first ?? 'User');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_user != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _loading ? null : _updateProfile,
            ),
        ],
      ),
      body: _user == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Not Signed In', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/sign-in'),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Card(
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
                                        : 'U',
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
                                Text(_user!.email!, style: TextStyle(color: Colors.grey[600])),
                                const SizedBox(height: 4),
                                Chip(
                                  label: Text(
                                    _userDoc?['role']?.toString().toUpperCase() ?? 'USER',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  backgroundColor: _userDoc?['role'] == 'admin'
                                      ? Colors.purple.withValues(alpha: 0.2)
                                      : Colors.blue.withValues(alpha: 0.2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text('Account Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // Profile Form
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _photoUrlController,
                            decoration: const InputDecoration(
                              labelText: 'Profile Picture URL',
                              prefixIcon: Icon(Icons.image),
                            ),
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _studentIdController,
                            decoration: const InputDecoration(
                              labelText: 'Student ID',
                              prefixIcon: Icon(Icons.badge),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _departmentController,
                            decoration: const InputDecoration(
                              labelText: 'Department',
                              prefixIcon: Icon(Icons.school),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text('Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // Preferences
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Enable Notifications'),
                            subtitle: const Text('Receive updates and announcements'),
                            value: _notificationsEnabled,
                            onChanged: (value) {
                              setState(() => _notificationsEnabled = value);
                              _updatePreferences(notifications: value);
                            },
                          ),
                          SwitchListTile(
                            title: const Text('Dark Mode'),
                            subtitle: const Text('Use dark theme'),
                            value: _darkMode,
                            onChanged: (value) {
                              setState(() => _darkMode = value);
                              _updatePreferences(darkMode: value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text('Account Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth >= 500 ? 3 : 2;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 1.7,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          _buildStatCard('Member Since', _userDoc?['createdAt'] != null
                              ? '${_getMonth(_userDoc!['createdAt'])} ${_getYear(_userDoc!['createdAt'])}'
                              : '—'),
                          _buildStatCard('Last Active', _userDoc?['lastLogin'] != null
                              ? _formatTimestamp(_userDoc!['lastLogin'])
                              : '—'),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _loading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator())
                              : const Text('Save Changes'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _signOut,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Theme.of(context).colorScheme.error),
                          ),
                          child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _deleteAccount,
                        child: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  String _getMonth(dynamic timestamp) {
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.month}/${date.day}';
      }
    } catch (_) {}
    return '';
  }

  String _getYear(dynamic timestamp) {
    try {
      if (timestamp is Timestamp) {
        return timestamp.toDate().year.toString();
      }
    } catch (_) {}
    return '';
  }

  String _formatTimestamp(dynamic ts) {
    try {
      DateTime dt;
      if (ts is Timestamp) {
        dt = ts.toDate();
      } else if (ts is DateTime) {
        dt = ts;
      } else if (ts is String) {
        dt = DateTime.parse(ts);
      } else {
        return ts.toString();
      }
      return '${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return ts?.toString() ?? '';
    }
  }
}