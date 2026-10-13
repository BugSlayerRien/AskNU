import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/audit_service.dart';
import '../../services/auth_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final col = FirebaseFirestore.instance.collection('users');
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs = [];
  String? _error;
  bool _loading = true;
  bool _isAdmin = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Future<void> _setRole(String uid, String role) async {
    await col.doc(uid).set({'role': role}, SetOptions(merge: true));
    await AuditService.instance.logAudit(
      action: 'user_role_update',
      metadata: {'role': role},
      targetUserId: uid,
    );
    await AuditService.instance.logUserActivity(
      type: 'role_update',
      description: 'Role updated to $role',
      userId: uid,
    );
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final ok = await AuthService.instance.isAdmin();
    if (!mounted) return;
    setState(() => _isAdmin = ok);
    if (!ok) return;

    col.snapshots().listen((snap) {
      if (!mounted) return;
      setState(() {
        _docs = snap.docs;
        _error = null;
        _loading = false;
      });
    }, onError: (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.toLowerCase();
    final filtered = query.isEmpty
        ? _docs
        : _docs.where((d) {
            final data = d.data();
            final email = (data['email']?.toString() ?? '').toLowerCase();
            final name = (data['fullName']?.toString() ?? '').toLowerCase();
            final role = (data['role']?.toString() ?? '').toLowerCase();
            return email.contains(query) || name.contains(query) || role.contains(query);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Users'),
      ),
      body: !_isAdmin
          ? const Center(child: Text('Admin access required'))
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search users...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) => setState(() => _searchQuery = value),
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'Unable to load users. ${_error ?? ''}\nCheck Firestore rules for admin access to users.',
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No users'))
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (c, i) => const Divider(height: 1),
                              itemBuilder: (c, i) {
                                final d = filtered[i];
                                final data = d.data();
                                final role = (data['role']?.toString() ?? 'user');
                                return ListTile(
                                  title: Text(data['email'] ?? d.id),
                                  subtitle: Text('Role: $role'),
                                  trailing: DropdownButton<String>(
                                    value: role,
                                    items: const [
                                      DropdownMenuItem(value: 'user', child: Text('user')),
                                      DropdownMenuItem(value: 'admin', child: Text('admin')),
                                    ],
                                    onChanged: (v) async {
                                      if (v == null) return;
                                      await _setRole(d.id, v);
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
