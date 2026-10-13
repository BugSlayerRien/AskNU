import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/audit_service.dart';
import '../services/analytics_store_service.dart';

class DocumentRequestsScreen extends StatefulWidget {
  const DocumentRequestsScreen({super.key});

  @override
  State<DocumentRequestsScreen> createState() => _DocumentRequestsScreenState();
}

class _DocumentRequestsScreenState extends State<DocumentRequestsScreen> {
  final _purposeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _docType = 'Transcript of Records';
  String _delivery = 'Registrar';
  bool _submitting = false;
  bool _isAdmin = false;

  final _types = const [
    'Transcript of Records',
    'Certificate of Enrollment',
    'Certificate of Grades',
    'Good Moral Certificate',
    'Honorable Dismissal',
  ];

  final _deliveries = const [
    'Registrar',
    'Treasury',
    'Student Affairs Office',
    'Courier',
  ];
  final _statuses = const ['submitted', 'processing', 'ready', 'released', 'rejected', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final ok = await AuthService.instance.isAdmin();
    if (!mounted) return;
    setState(() => _isAdmin = ok);
  }

  Future<int> _countActiveRequests(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('document_requests')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: const ['submitted', 'processing', 'ready'])
        .get();
    return snapshot.docs.length;
  }

  Future<void> _submitRequest() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    final purpose = _purposeCtrl.text.trim();
    if (purpose.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the purpose of your request')),
      );
      return;
    }

    final activeCount = await _countActiveRequests(user.uid);
    if (activeCount >= 2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Limit reached: only 2 active requests at a time.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final ref = await FirebaseFirestore.instance.collection('document_requests').add({
        'userId': user.uid,
        'userEmail': user.email,
        'type': _docType,
        'purpose': purpose,
        'delivery': _delivery,
        'notes': _notesCtrl.text.trim(),
        'status': 'submitted',
        'statusHistory': [
          {'status': 'submitted', 'at': Timestamp.now()}
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': user.uid,
        'title': 'Document request submitted',
        'body': 'Your request for "$_docType" has been submitted. Ref: ${ref.id}.',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await AnalyticsStoreService.instance.incrementDaily('documentRequests');
      _purposeCtrl.clear();
      _notesCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _updateStatus(String id, String status, String userId, String type) async {
    await FirebaseFirestore.instance
        .collection('document_requests')
        .doc(id)
        .set({
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
          'statusHistory': FieldValue.arrayUnion([
            {'status': status, 'at': Timestamp.now()}
          ]),
        }, SetOptions(merge: true));
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'title': 'Document request update',
      'body': 'Your request for "$type" is now "$status".',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await AuditService.instance.logAudit(
      action: 'document_request_status',
      metadata: {'requestId': id, 'status': status},
      targetUserId: userId,
    );
    await AuditService.instance.logUserActivity(
      type: 'document_request_status',
      description: 'Updated document request status to $status',
      userId: userId,
    );
    await AnalyticsStoreService.instance.incrementDaily('documentStatusChanges');
  }

  Future<void> _cancelRequest(String id, String userId, String type) async {
    await FirebaseFirestore.instance.collection('document_requests').doc(id).set({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([
        {'status': 'cancelled', 'at': Timestamp.now()}
      ]),
    }, SetOptions(merge: true));
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'title': 'Document request cancelled',
      'body': 'Your request for "$type" was cancelled.',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await AuditService.instance.logAudit(
      action: 'document_request_cancel',
      metadata: {'requestId': id},
      targetUserId: userId,
    );
    await AuditService.instance.logUserActivity(
      type: 'document_request_cancel',
      description: 'Cancelled a document request',
      userId: userId,
    );
    await AnalyticsStoreService.instance.incrementDaily('documentCancels');
  }

  Future<void> _deleteRequest(String id, String userId) async {
    await FirebaseFirestore.instance.collection('document_requests').doc(id).delete();
    await AuditService.instance.logAudit(
      action: 'document_request_delete',
      metadata: {'requestId': id},
      targetUserId: userId,
    );
    await AuditService.instance.logUserActivity(
      type: 'document_request_delete',
      description: 'Deleted a document request',
      userId: userId,
    );
  }

  String _formatTimestamp(dynamic value) {
    if (value is Timestamp) {
      final d = value.toDate();
      return '${d.month}/${d.day}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '';
  }

  @override
  void dispose() {
    _purposeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Document Requests')),
      body: user == null
          ? const Center(child: Text('Please sign in to request documents'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (!_isAdmin) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Create Request', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          const Text(
                            'Limit: 2 active requests at a time.',
                            style: TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _docType,
                            decoration: const InputDecoration(labelText: 'Document Type'),
                            items: _types
                                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                .toList(),
                            onChanged: (v) => setState(() => _docType = v ?? _docType),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _delivery,
                            decoration: const InputDecoration(labelText: 'Method'),
                            items: _deliveries
                                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                .toList(),
                            onChanged: (v) => setState(() => _delivery = v ?? _delivery),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _purposeCtrl,
                            decoration: const InputDecoration(labelText: 'Purpose'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notesCtrl,
                            decoration: const InputDecoration(labelText: 'Notes (optional)'),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _submitting ? null : _submitRequest,
                              icon: _submitting
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.send),
                              label: const Text('Submit Request'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(_isAdmin ? 'All Requests' : 'Your Requests', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _isAdmin
                      ? FirebaseFirestore.instance
                          .collection('document_requests')
                          .orderBy('createdAt', descending: true)
                          .snapshots()
                      : FirebaseFirestore.instance
                          .collection('document_requests')
                      .where('userId', isEqualTo: user.uid)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (!_isAdmin) {
                      docs.sort((a, b) {
                        final aTime = a.data()['createdAt'] as Timestamp?;
                        final bTime = b.data()['createdAt'] as Timestamp?;
                        return (bTime?.millisecondsSinceEpoch ?? 0)
                            .compareTo(aTime?.millisecondsSinceEpoch ?? 0);
                      });
                    }
                    if (docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No requests yet'),
                      );
                    }
                    return Column(
                      children: docs.map((d) {
                        final data = d.data();
                        final status = (data['status'] ?? 'submitted').toString();
                        final type = data['type']?.toString() ?? 'Document';
                        final purpose = data['purpose']?.toString() ?? '';
                        final delivery = data['delivery']?.toString() ?? '';
                        final email = data['userEmail']?.toString() ?? '';
                        final userId = data['userId']?.toString() ?? '';
                        final updatedAt = _formatTimestamp(data['updatedAt']);
                        final canCancel = status == 'submitted' || status == 'processing' || status == 'ready';
                        final canDelete = status == 'cancelled' || status == 'rejected';
                        return Card(
                          child: ListTile(
                            title: Text(type),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (purpose.isNotEmpty) Text(purpose),
                                if (delivery.isNotEmpty) Text('Method: $delivery'),
                                if (_isAdmin && email.isNotEmpty) Text('User: $email'),
                                if (updatedAt.isNotEmpty) Text('Updated: $updatedAt'),
                              ],
                            ),
                            trailing: _isAdmin
                                ? DropdownButton<String>(
                                    value: status,
                                    items: _statuses
                                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v == null) return;
                                      if (userId.isNotEmpty) {
                                        _updateStatus(d.id, v, userId, type);
                                      }
                                    },
                                  )
                                : (canCancel || canDelete)
                                    ? PopupMenuButton<String>(
                                        tooltip: 'Actions',
                                        itemBuilder: (context) => [
                                          if (canCancel)
                                            const PopupMenuItem(
                                              value: 'cancel',
                                              child: Text('Cancel request'),
                                            ),
                                          if (canDelete)
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Text('Delete request'),
                                            ),
                                        ],
                                        onSelected: (value) async {
                                          if (value == 'cancel') {
                                            final ok = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('Cancel request'),
                                                content: const Text('Cancel this document request?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.of(ctx).pop(false),
                                                    child: const Text('No'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.of(ctx).pop(true),
                                                    child: const Text('Yes'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (ok == true && userId.isNotEmpty) {
                                              await _cancelRequest(d.id, userId, type);
                                            }
                                          } else if (value == 'delete') {
                                            final ok = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('Delete request'),
                                                content: const Text('Delete this document request?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.of(ctx).pop(false),
                                                    child: const Text('No'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.of(ctx).pop(true),
                                                    child: const Text('Yes'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (ok == true && userId.isNotEmpty) {
                                              await _deleteRequest(d.id, userId);
                                            }
                                          }
                                        },
                                        child: Chip(label: Text(status)),
                                      )
                                    : Chip(label: Text(status)),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
