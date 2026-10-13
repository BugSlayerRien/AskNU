import 'package:flutter/material.dart';

import '../models/faq.dart';
import '../services/faq_service.dart';
import 'faq_detail.dart';

class CategoryPage extends StatelessWidget {
  final String category;
  final List<FAQ> faqs;
  final FAQService service;

  const CategoryPage({super.key, required this.category, required this.faqs, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: ListView.builder(
        itemCount: faqs.length,
        itemBuilder: (context, i) {
          final f = faqs[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FAQDetail(faq: f, service: service))),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withAlpha(40), shape: BoxShape.circle),
                          child: Icon(Icons.help_outline, color: Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(f.question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withAlpha(18), borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        f.answer,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha((0.85 * 255).round())),
                      ),
                    ),
                    if (f.tags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(spacing: 6, runSpacing: 6, children: f.tags.map((t) => Chip(label: Text(t), visualDensity: VisualDensity.compact)).toList()),
                    ]
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
