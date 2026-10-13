import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/audit_service.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRole = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users by email or name...',
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
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedRole == 'All',
                        onSelected: (selected) =>
                            setState(() => _selectedRole = 'All'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Admin'),
                        selected: _selectedRole == 'admin',
                        onSelected: (selected) =>
                            setState(() => _selectedRole = 'admin'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('User'),
                        selected: _selectedRole == 'user',
                        onSelected: (selected) =>
                            setState(() => _selectedRole = 'user'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs;
                final sortedUsers = [...users];
                sortedUsers.sort((a, b) {
                  final ad = a.data() as Map<String, dynamic>;
                  final bd = b.data() as Map<String, dynamic>;
                  final at = ad['createdAt'];
                  final bt = bd['createdAt'];
                  DateTime? aDate;
                  DateTime? bDate;
                  if (at is Timestamp) aDate = at.toDate();
                  if (bt is Timestamp) bDate = bt.toDate();
                  if (at is String) aDate = DateTime.tryParse(at);
                  if (bt is String) bDate = DateTime.tryParse(bt);
                  aDate ??= DateTime.fromMillisecondsSinceEpoch(0);
                  bDate ??= DateTime.fromMillisecondsSinceEpoch(0);
                  return bDate.compareTo(aDate);
                });
                final filteredUsers = sortedUsers.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final email = data['email']?.toString().toLowerCase() ?? '';
                  final fullName = data['fullName']?.toString().toLowerCase() ?? '';
                  final firstName = data['firstName']?.toString().toLowerCase() ?? '';
                  final lastName = data['lastName']?.toString().toLowerCase() ?? '';
                  final role = data['role']?.toString().toLowerCase() ?? 'user';
                  final search = _searchQuery.toLowerCase();
                  
                  // Search filter
                  final matchesSearch = search.isEmpty ||
                      email.contains(search) ||
                      fullName.contains(search) ||
                      firstName.contains(search) ||
                      lastName.contains(search);
                  
                  // Role filter
                  final matchesRole = _selectedRole == 'All' || role == _selectedRole;
                  
                  return matchesSearch && matchesRole;
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text('No users found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final doc = filteredUsers[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final id = doc.id;
                    final isAdmin = (data['role']?.toString().toLowerCase() ?? '') == 'admin';
                    final fullName = data['fullName']?.toString().trim() ?? '';
                    final firstName = data['firstName']?.toString().trim() ?? '';
                    final email = data['email']?.toString().trim() ?? '';
                    final displayName = fullName.isNotEmpty
                      ? fullName
                      : firstName.isNotEmpty
                        ? firstName
                        : (email.isNotEmpty ? email.split('@').first : 'Unknown User');
                    final initial = displayName.isNotEmpty
                      ? displayName.substring(0, 1).toUpperCase()
                      : '?';
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isAdmin ? Colors.purple : Colors.blue,
                          child: Text(
                            initial,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(displayName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(email.isNotEmpty ? email : 'No email'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Chip(
                                  label: Text(
                                    isAdmin ? 'Admin' : 'User',
                                    style: TextStyle(
                                      color: isAdmin ? Colors.purple : Colors.blue,
                                    ),
                                  ),
                                  backgroundColor: isAdmin 
                                      ? Colors.purple[50] 
                                      : Colors.blue[50],
                                ),
                                const SizedBox(width: 8),
                                if (data['studentId']?.isNotEmpty == true)
                                  Chip(
                                    label: Text('ID: ${data['studentId']}'),
                                    backgroundColor: Colors.grey[100],
                                  ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            if (!isAdmin)
                              const PopupMenuItem(
                                value: 'make_admin',
                                child: ListTile(
                                  leading: Icon(Icons.admin_panel_settings),
                                  title: Text('Make Admin'),
                                ),
                              ),
                            if (isAdmin)
                              const PopupMenuItem(
                                value: 'remove_admin',
                                child: ListTile(
                                  leading: Icon(Icons.person_off),
                                  title: Text('Remove Admin'),
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'view_details',
                              child: ListTile(
                                leading: Icon(Icons.info),
                                title: Text('View Details'),
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'make_admin') {
                              _showMakeAdminDialog(id, data['email']);
                            } else if (value == 'remove_admin') {
                              _showRemoveAdminDialog(id, data['email']);
                            } else if (value == 'view_details') {
                              _showUserDetails(doc);
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showMakeAdminDialog(String userId, String? userEmail) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Make Admin'),
        content: Text('Are you sure you want to make $userEmail an administrator?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection('users').doc(userId).update({
                'role': 'admin',
                'adminSince': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
              await AuditService.instance.logAudit(
                action: 'user_role_update',
                metadata: {'role': 'admin'},
                targetUserId: userId,
              );
              await AuditService.instance.logUserActivity(
                type: 'role_update',
                description: 'Role updated to admin',
                userId: userId,
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(content: Text('$userEmail is now an admin')),
              );
            },
            child: const Text('Make Admin'),
          ),
        ],
      ),
    );
  }

  void _showRemoveAdminDialog(String userId, String? userEmail) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Admin'),
        content: Text('Are you sure you want to remove admin privileges from $userEmail?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection('users').doc(userId).update({
                'role': 'user',
                'updatedAt': FieldValue.serverTimestamp(),
              });
              await AuditService.instance.logAudit(
                action: 'user_role_update',
                metadata: {'role': 'user'},
                targetUserId: userId,
              );
              await AuditService.instance.logUserActivity(
                type: 'role_update',
                description: 'Role updated to user',
                userId: userId,
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(content: Text('Admin privileges removed from $userEmail')),
              );
            },
            child: const Text('Remove Admin'),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailItem(label: 'Email', value: data['email'] ?? 'N/A'),
              _DetailItem(label: 'Full Name', value: data['fullName'] ?? 'N/A'),
              _DetailItem(label: 'First Name', value: data['firstName'] ?? 'N/A'),
              _DetailItem(label: 'Last Name', value: data['lastName'] ?? 'N/A'),
              _DetailItem(label: 'Student ID', value: data['studentId'] ?? 'N/A'),
              _DetailItem(label: 'Department', value: data['department'] ?? 'N/A'),
              _DetailItem(label: 'Role', value: data['role'] ?? 'user'),
              _DetailItem(
                label: 'Email Verified', 
                value: data['isEmailVerified'] == true ? 'Yes' : 'No'
              ),
              _DetailItem(
                label: 'Created', 
                value: _formatDate(data['createdAt'])
              ),
              if (data['lastLogin'] != null)
                _DetailItem(
                  label: 'Last Login', 
                  value: _formatDate(data['lastLogin'])
                ),
              if (data['adminSince'] != null)
                _DetailItem(
                  label: 'Admin Since', 
                  value: _formatDate(data['adminSince'])
                ),
              _DetailItem(
                label: 'Notifications', 
                value: data['notifications'] == true ? 'Enabled' : 'Disabled'
              ),
              _DetailItem(
                label: 'Questions Asked', 
                value: '${data['questionsAsked'] ?? 0}'
              ),
              _DetailItem(
                label: 'FAQs Viewed', 
                value: '${data['faqsViewed'] ?? 0}'
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
    return 'N/A';
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}