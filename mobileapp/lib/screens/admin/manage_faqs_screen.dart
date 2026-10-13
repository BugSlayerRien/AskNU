import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/audit_service.dart';
import '../../services/faq_service.dart';

class ManageFAQScreen extends StatefulWidget {
  const ManageFAQScreen({super.key});

  @override
  State<ManageFAQScreen> createState() => _ManageFAQScreenState();
}

class _ManageFAQScreenState extends State<ManageFAQScreen> {
  final FAQService _faqService = FAQService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage FAQs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddFAQDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
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
            child: StreamBuilder<QuerySnapshot>(
              stream: _faqService.faqsCollection
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final faqs = snapshot.data!.docs;
                final filteredFaqs = faqs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final question = data['question']?.toString().toLowerCase() ?? '';
                  final answer = data['answer']?.toString().toLowerCase() ?? '';
                      final description = data['description']?.toString().toLowerCase() ?? '';
                  final category = data['category']?.toString().toLowerCase() ?? '';
                  final search = _searchQuery.toLowerCase();
                  
                  return question.contains(search) || 
                        answer.contains(search) || 
                        description.contains(search) ||
                         category.contains(search);
                }).toList();

                if (filteredFaqs.isEmpty) {
                  return const Center(child: Text('No FAQs found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredFaqs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredFaqs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final id = doc.id;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: ListTile(
                        title: Text(
                          data['question'] ?? 'No question',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['answer'] ?? 'No answer',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Chip(
                                  label: Text(data['category'] ?? 'General'),
                                  backgroundColor: Colors.blue[50],
                                ),
                                const Spacer(),
                                Text(
                                  'Views: ${data['viewCount'] ?? 0}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Edit'),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete, color: Colors.red),
                                title: Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditFAQDialog(id, data);
                            } else if (value == 'delete') {
                              _showDeleteDialog(id);
                            }
                          },
                        ),
                        onTap: () => _showFAQDetails(doc),
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

  void _showAddFAQDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => FAQDialog(
        onSave: (question, answer, category, description) async {
          await _faqService.createFaq({
            'question': question,
            'answer': answer,
            'category': category,
            'description': description,
          });
          await AuditService.instance.logAudit(
            action: 'faq_create',
            metadata: {'question': question, 'category': category},
          );
          if (!dialogContext.mounted) return;
          Navigator.pop(dialogContext);
        },
      ),
    );
  }

  void _showEditFAQDialog(String id, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (dialogContext) => FAQDialog(
        question: data['question'],
        answer: data['answer'],
        category: data['category'],
        description: data['description'],
        onSave: (question, answer, category, description) async {
          await _faqService.updateFaq(id, {
            'question': question,
            'answer': answer,
            'category': category,
            'description': description,
          });
          await AuditService.instance.logAudit(
            action: 'faq_update',
            metadata: {'id': id, 'question': question, 'category': category},
          );
          if (!dialogContext.mounted) return;
          Navigator.pop(dialogContext);
        },
      ),
    );
  }

  void _showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete FAQ'),
        content: const Text('Are you sure you want to delete this FAQ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _faqService.deleteFaq(id);
              await AuditService.instance.logAudit(
                action: 'faq_delete',
                metadata: {'id': id},
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFAQDetails(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FAQDetailsSheet(faq: data, id: doc.id),
    );
  }
}

class FAQDialog extends StatefulWidget {
  final String? question;
  final String? answer;
  final String? category;
  final String? description;
  final Function(String, String, String, String) onSave;

  const FAQDialog({
    super.key,
    this.question,
    this.answer,
    this.category,
    this.description,
    required this.onSave,
  });

  @override
  State<FAQDialog> createState() => _FAQDialogState();
}

class _FAQDialogState extends State<FAQDialog> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<String> _categories = [
    'General',
    'Academic',
    'Technical',
    'Financial',
    'Student Life',
    'Housing',
    'Registration',
    'Graduation',
  ];

  @override
  void initState() {
    super.initState();
    _questionController.text = widget.question ?? '';
    _answerController.text = widget.answer ?? '';
    _categoryController.text = widget.category ?? _categories.first;
    _descriptionController.text = widget.description ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.question == null ? 'Add FAQ' : 'Edit FAQ'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a question'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _answerController,
                decoration: const InputDecoration(
                  labelText: 'Answer',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter an answer'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _categoryController.text,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _categoryController.text = value;
                  }
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'Please select a category'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(
                _questionController.text,
                _answerController.text,
                _categoryController.text,
                _descriptionController.text.trim(),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class FAQDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> faq;
  final String id;

  const FAQDetailsSheet({
    super.key,
    required this.faq,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.question_answer, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  faq['question'] ?? 'No question',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Answer:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            faq['answer'] ?? 'No answer',
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          if ((faq['description'] ?? '').toString().trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Description:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              faq['description'].toString(),
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Chip(
                label: Text(faq['category'] ?? 'General'),
                backgroundColor: Colors.blue[50],
              ),
              const SizedBox(width: 16),
              const Icon(Icons.visibility, size: 16),
              const SizedBox(width: 4),
              Text('${faq['viewCount'] ?? 0} views'),
            ],
          ),
          const SizedBox(height: 16),
          if (faq['createdAt'] != null)
            Text(
              'Created: ${_formatDate(faq['createdAt'])}',
              style: const TextStyle(color: Colors.grey),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate().toString().split(' ')[0];
    }
    return 'Unknown date';
  }
}