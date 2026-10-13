import 'package:flutter/material.dart';
import '../services/conversation_service.dart';
import 'chat_screen.dart';
import '../services/auth_service.dart';
import '../services/faq_service.dart';
import 'dart:async';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final ConversationService _svc = ConversationService.instance;
  bool _signedIn = false;
  StreamSubscription? _authSub;

  @override
  void initState() {
    super.initState();
    _signedIn = AuthService.instance.currentUser != null;
    _authSub = AuthService.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      setState(() {
        _signedIn = user != null;
      });
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _createNew() async {
    final titleCtrl = TextEditingController(text: 'New conversation');
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('New conversation'), content: TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Create'))]));
    if (ok != true) return;
    if (!_signedIn) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to start a conversation')));
      return;
    }
    final doc = await _svc.createConversation(title: titleCtrl.text.trim());
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(service: FAQService(), conversationId: doc.id, conversationTitle: titleCtrl.text.trim())));
  }

  @override
  Widget build(BuildContext context) {
    if (!_signedIn) return Scaffold(appBar: AppBar(title: const Text('Conversations')), body: const Center(child: Text('Sign in to see your conversations')));
    return Scaffold(
      appBar: AppBar(title: const Text('Conversations')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _svc.streamConversations(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final items = snap.data ?? [];
          if (items.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const SizedBox(height: 24), ElevatedButton.icon(onPressed: _createNew, icon: const Icon(Icons.add), label: const Text('Start a conversation'))]));
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final it = items[i];
              return ListTile(
                title: Text(it['title'] ?? ''),
                subtitle: Text(_buildSubtitle(it)),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(service: FAQService(), conversationId: it['id'] as String, conversationTitle: it['title'] as String?))),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.edit), onPressed: () async {
                    final ctrl = TextEditingController(text: it['title'] ?? '');
                    final ok = await showDialog<bool>(context: context, builder: (dCtx) => AlertDialog(title: const Text('Rename'), content: TextField(controller: ctrl), actions: [TextButton(onPressed: () => Navigator.of(dCtx).pop(false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(dCtx).pop(true), child: const Text('Save'))]));
                    if (ok == true) await _svc.renameConversation(it['id'] as String, ctrl.text.trim());
                  }),
                  IconButton(icon: const Icon(Icons.delete), onPressed: () async {
                    final ok = await showDialog<bool>(context: context, builder: (dCtx) => AlertDialog(title: const Text('Delete'), content: const Text('Delete this conversation?'), actions: [TextButton(onPressed: () => Navigator.of(dCtx).pop(false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(dCtx).pop(true), child: const Text('Delete'))]));
                    if (ok == true) await _svc.deleteConversation(it['id'] as String);
                  })
                ]),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: _createNew, child: const Icon(Icons.add)),
    );
  }

  String _buildSubtitle(Map<String, dynamic> it) {
    final last = it['lastMessageText']?.toString().trim() ?? '';
    final count = it['messageCount'] is int
        ? it['messageCount'] as int
        : (it['messages'] as List?)?.length ?? 0;
    final countText = '$count message${count == 1 ? '' : 's'}';
    if (last.isEmpty) return countText;
    return '$countText · $last';
  }
}
