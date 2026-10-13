import 'dart:async';

import 'package:flutter/material.dart';

import '../models/faq.dart';
import '../services/faq_service.dart';
import '../services/conversation_service.dart';
import '../services/ai_chat_service.dart';
import '../widgets/notifications_modal.dart';
import 'faq_detail.dart';

class ChatScreen extends StatefulWidget {
  final FAQService service;
  final String? conversationId;
  final String? conversationTitle;
  const ChatScreen({super.key, required this.service, this.conversationId, this.conversationTitle});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  String? _conversationId;
  bool _typing = false;
  late final AnimationController _dotsController;
  List<FAQ> _lastMatches = [];
  static const _stopWords = <String>{
    'a', 'an', 'the', 'and', 'or', 'to', 'of', 'for', 'in', 'on', 'at', 'with', 'is', 'are', 'am', 'be',
    'do', 'does', 'did', 'can', 'could', 'should', 'would', 'may', 'might', 'will', 'shall',
    'i', 'you', 'we', 'they', 'he', 'she', 'it', 'me', 'my', 'your', 'our', 'their',
    'this', 'that', 'these', 'those', 'about', 'please', 'question', 'ask'
  };

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
    _conversationId = widget.conversationId;
    _loadFaqs();
    if (_conversationId != null) {
      _loadConversation(_conversationId!);
    } else {
      _ensureWelcome();
    }
  }

  void _ensureWelcome() {
    if (_messages.isNotEmpty) return;
    _insertMessage({
      'sender': 'bot',
      'text': 'Hi! I can help with enrollment, grading, documents, and more. Ask me a question to get started.',
    });
  }

  Future<void> _loadFaqs() async {
    final loaded = await widget.service.loadFromFirestore();
    if (!loaded) {
      await widget.service.loadFromAssets();
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadConversation(String id) async {
    try {
      final data = await ConversationService.instance.getConversation(id);
      if (data == null) return;
      final msgs = <Map<String, dynamic>>[];
      final raw = data['messages'];
      if (raw is List) {
        for (final m in raw) {
          if (m is Map<String, dynamic>) {
            msgs.add(m);
          } else if (m is Map) {
            msgs.add(Map<String, dynamic>.from(m));
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _messages.clear();
        _messages.addAll(msgs);
      });
      _ensureWelcome();
    } catch (_) {}
  }

  @override
  void dispose() {
    _dotsController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _insertMessage(Map<String, dynamic> msg) {
    setState(() {
      _messages.add(msg);
    });
  }

  List<String> _tokenize(String input) {
    final tokens = RegExp(r"\w+").allMatches(input.toLowerCase()).map((m) => m.group(0)!).toList();
    return tokens.where((t) => !_stopWords.contains(t) && t.length > 2).toSet().toList();
  }

  int _scoreMatch(String query, FAQ faq) {
    final qTokens = _tokenize(query);
    if (qTokens.isEmpty) return 0;

    final qText = faq.question.toLowerCase();
    final aText = faq.answer.toLowerCase();
    final dText = faq.description.toLowerCase();
    final tags = faq.tags.map((t) => t.toLowerCase()).toList();

    int score = 0;
    for (final t in qTokens) {
      if (qText.contains(t)) score += 3;
      if (aText.contains(t)) score += 1;
      if (dText.contains(t)) score += 1;
      if (tags.any((tg) => tg.contains(t))) score += 2;
    }
    return score;
  }

  void _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _insertMessage({'sender': 'user', 'text': text});
    setState(() => _typing = true);

    // simulate thinking
    await Future.delayed(const Duration(milliseconds: 700));

    String reply;
    FAQ? top;

    // If user selects from previous suggestions
    if (_lastMatches.isNotEmpty && (text == '1' || text == '2')) {
      final idx = int.parse(text) - 1;
      if (idx >= 0 && idx < _lastMatches.length) {
        top = _lastMatches[idx];
        reply = top.answer;
        _lastMatches = [];
      } else {
        reply = "Please reply with 1 or 2 to choose a match.";
      }
    } else {
      final results = widget.service.search(text);
      final tokens = _tokenize(text);
      final scored = results
          .map((f) => MapEntry(f, _scoreMatch(text, f)))
          .where((entry) => entry.value > 0)
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final minScore = tokens.length <= 2 ? 5 : 4;
      final confident = scored.where((e) => e.value >= minScore).toList();

      if (confident.isNotEmpty && tokens.length < 3) {
        final suggestions = confident.take(2).map((e) => e.key).toList();
        _lastMatches = suggestions;
        final lines = <String>[];
        for (var i = 0; i < suggestions.length; i++) {
          final f = suggestions[i];
          lines.add('${i + 1}) ${f.question} (${f.category})');
        }
        reply = 'Here are the top matches:\n${lines.join('\n')}\nReply with 1 or 2 to view the answer.';
      } else if (confident.isNotEmpty) {
        top = confident.first.key;
        reply = top.answer;
      } else {
        try {
          reply = await AIChatService.instance.generateAnswer(question: text);
        } catch (_) {
          reply = "I couldn't find a direct answer. Try different keywords or browse the FAQs.";
        }
      }
    }

    setState(() => _typing = false);
    _insertMessage({'sender': 'bot', 'text': reply, 'faq': top});

    // Persist message to conversation (create conversation if necessary)
    try {
      final convSvc = ConversationService.instance;
      if (_conversationId == null) {
        final doc = await convSvc.createConversation(title: widget.conversationTitle ?? 'Conversation');
        _conversationId = doc.id;
      }
      await ConversationService.instance.addMessage(_conversationId!, {'sender': 'user', 'text': text, 'createdAt': DateTime.now().toUtc().toIso8601String()});
      await ConversationService.instance.addMessage(_conversationId!, {'sender': 'bot', 'text': reply, 'createdAt': DateTime.now().toUtc().toIso8601String(), 'faq': top != null ? {'id': top.id, 'question': top.question} : null});
    } catch (_) {}
  }

  Widget _buildBubble(Map<String, dynamic> m, Animation<double> animation) {
    final isUser = m['sender'] == 'user';
    final bg = isUser ? Colors.grey.shade200 : Theme.of(context).colorScheme.primary;
    final fg = isUser ? Colors.black : Colors.white;

    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      axisAlignment: 0.0,
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: Offset(isUser ? 0.3 : -0.3, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: InkWell(
              onTap: () {
                if (!isUser && m['faq'] != null) {
                  final raw = m['faq'];
                  FAQ? faq;
                  if (raw is FAQ) {
                    faq = raw;
                  } else if (raw is Map) {
                    final id = raw['id']?.toString() ?? '';
                    faq = widget.service.getById(id);
                  }
                  if (faq != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => FAQDetail(faq: faq!, service: widget.service)),
                    );
                  }
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                padding: const EdgeInsets.all(12),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                child: Text(m['text'], style: TextStyle(color: fg)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Row(children: [Hero(tag: 'app-logo', child: Padding(padding: EdgeInsets.only(right: 8), child: Image(image: AssetImage('assets/logo.png'), width: 36, height: 36, errorBuilder: (c, e, s) => CircleAvatar(backgroundColor: Theme.of(context).colorScheme.secondary, child: Icon(Icons.school, color: Colors.white))))), const SizedBox(width: 6), const Text('Chat with AskNU')]), actions: [IconButton(icon: const Icon(Icons.notifications), onPressed: () => showNotificationsModal(context))]),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length + (_typing ? 1 : 0),
            itemBuilder: (context, i) {
              if (i >= _messages.length) {
                return _TypingWidget(controller: _dotsController);
              }
              final m = _messages[i];
              return _buildBubble(m, const AlwaysStoppedAnimation(1.0));
            },
          ),
        ),
        SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'Ask a question...'))),
              const SizedBox(width: 8),
              FloatingActionButton.small(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, onPressed: _send, child: const Icon(Icons.send)),
            ]),
          ),
        )
      ]),
    );
  }
}

class _TypingWidget extends StatelessWidget {
  final AnimationController controller;
  const _TypingWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          _DotsAnimation(controller: controller),
        ]),
      ),
    );
  }
}

class _DotsAnimation extends AnimatedWidget {
  // AnimatedWidget's constructor isn't const, so ignore the lint here.
  // ignore: prefer_const_constructors_in_immutables
  _DotsAnimation({required AnimationController controller}) : super(listenable: controller);

  Animation<double> get _anim => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    final progress = _anim.value;
    // create three dots with staggered opacity
    return Row(children: List.generate(3, (i) {
      final t = (progress + i * 0.2) % 1.0;
      final opacity = (t < 0.5) ? (t * 2) : ((1 - t) * 2);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.0),
        child: Opacity(
          opacity: opacity.clamp(0.2, 1.0),
          child: Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(4))),
        ),
      );
    }));
  }
}
