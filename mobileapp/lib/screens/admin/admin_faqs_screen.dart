import 'package:flutter/material.dart';
import '../../services/faq_service.dart';
import '../../services/auth_service.dart';
import '../../services/audit_service.dart';

class AdminFaqsScreen extends StatefulWidget {
  const AdminFaqsScreen({super.key});

  @override
  State<AdminFaqsScreen> createState() => _AdminFaqsScreenState();
}

class _AdminFaqsScreenState extends State<AdminFaqsScreen> {
  final FAQService _faqService = FAQService();
  bool _isAdmin = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

  Future<void> _showEditDialog({Map<String, dynamic>? item}) async {
    final qCtrl = TextEditingController(text: item?['question'] ?? '');
    final aCtrl = TextEditingController(text: item?['answer'] ?? '');
    final catCtrl = TextEditingController(text: item?['category'] ?? 'General');
    final descCtrl = TextEditingController(text: item?['description'] ?? '');
    final title = item == null ? 'Create FAQ' : 'Edit FAQ';
    final res = await showDialog<bool>(context: context, builder: (ctx) {
      return AlertDialog(
        title: Text(title),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: qCtrl, decoration: const InputDecoration(labelText: 'Question')),
          TextField(controller: aCtrl, decoration: const InputDecoration(labelText: 'Answer')),
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (optional)')),
          TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Category')),
        ]),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Save'))],
      );
    });

    if (res != true) return;
    final payload = {
      'question': qCtrl.text.trim(),
      'answer': aCtrl.text.trim(),
      'description': descCtrl.text.trim(),
      'category': catCtrl.text.trim(),
    };
    if (item == null) {
      await _faqService.createFaq(payload);
      await AuditService.instance.logAudit(action: 'faq_create', metadata: payload);
    } else {
      await _faqService.updateFaq(item['id'] as String, payload);
      await AuditService.instance.logAudit(action: 'faq_update', metadata: {'id': item['id'], ...payload});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) return Scaffold(appBar: AppBar(title: const Text('Admin - FAQs')), body: const Center(child: Text('Admin access required')));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - FAQs'),
        actions: [IconButton(icon: const Icon(Icons.group), onPressed: () => Navigator.pushNamed(context, '/admin/users'))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search FAQs...',
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
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _faqService.streamRemoteFaqs(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final items = snap.data ?? [];
                final q = _searchQuery.toLowerCase();
                final filtered = q.isEmpty
                    ? items
                    : items.where((it) {
                        final question = (it['question'] ?? '').toString().toLowerCase();
                        final answer = (it['answer'] ?? '').toString().toLowerCase();
                        final description = (it['description'] ?? '').toString().toLowerCase();
                        final category = (it['category'] ?? '').toString().toLowerCase();
                        return question.contains(q) || answer.contains(q) || description.contains(q) || category.contains(q);
                      }).toList();
                if (filtered.isEmpty) return const Center(child: Text('No FAQs yet'));
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final it = filtered[i];
                    return ListTile(
                      title: Text(it['question'] ?? ''),
                      subtitle: Text(it['category'] ?? ''),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.edit), onPressed: () => _showEditDialog(item: it)),
                        IconButton(icon: const Icon(Icons.delete), onPressed: () async {
                          final ok = await showDialog<bool>(context: context, builder: (dCtx) => AlertDialog(title: const Text('Delete'), content: const Text('Delete this FAQ?'), actions: [TextButton(onPressed: () => Navigator.of(dCtx).pop(false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(dCtx).pop(true), child: const Text('Delete'))]));
                          if (ok == true) {
                            await _faqService.deleteFaq(it['id'] as String);
                            await AuditService.instance.logAudit(action: 'faq_delete', metadata: {'id': it['id'], 'question': it['question']});
                          }
                        })
                      ]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(child: const Icon(Icons.add), onPressed: () => _showEditDialog()),
    );
  }
}
