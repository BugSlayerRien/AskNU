import 'package:flutter/material.dart';

import '../utils/category_icons.dart';

class CategoryGrid extends StatelessWidget {
  final List<String> categories;
  final ValueChanged<String> onTap;

  const CategoryGrid({super.key, required this.categories, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(child: Text('No categories available')),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900
          ? 4
          : constraints.maxWidth >= 600
            ? 3
            : 2;
        final primary = Theme.of(context).colorScheme.primary;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 2.6,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];
            final icon = categoryIcons[category] ?? Icons.folder;
            return Card(
              color: primary,
              child: InkWell(
                onTap: () => onTap(category),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          category,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
