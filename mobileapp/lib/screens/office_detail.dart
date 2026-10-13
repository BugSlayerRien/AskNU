import 'package:flutter/material.dart';

class OfficeDetail extends StatelessWidget {
  final Map<String, dynamic> data;
  const OfficeDetail({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final royal = Theme.of(context).colorScheme.primary;
    final gold = Theme.of(context).colorScheme.secondary;
    final name = data['name']?.toString() ?? 'Office';
    final role = data['role']?.toString() ?? '';
    final description = data['description']?.toString() ?? '';
    final servicesRaw = data['services']?.toString() ?? '';
    final services = servicesRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final location = data['location']?.toString() ?? '';
    final hours = data['hours']?.toString() ?? '';
    final email = data['email']?.toString() ?? '';
    final phone = data['phone']?.toString() ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(radius: 30, backgroundColor: gold, child: Text(name.isNotEmpty ? name[0] : 'O', style: TextStyle(color: royal, fontSize: 20, fontWeight: FontWeight.w700))),
            const SizedBox(width: 12),
            Expanded(child: Text(name, style: Theme.of(context).textTheme.headlineSmall)),
          ]),
          const SizedBox(height: 16),
          if (role.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Role', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(role),
                ]),
              ),
            ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('About', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(description),
                ]),
              ),
            ),
          ],
          if (services.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Services', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: services.map((s) => Chip(label: Text(s))).toList(),
                  ),
                ]),
              ),
            ),
          ],
          if (location.isNotEmpty || hours.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Office Hours & Location', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  if (hours.isNotEmpty) Row(children: [Icon(Icons.access_time, color: royal), const SizedBox(width: 8), Expanded(child: Text(hours))]),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(children: [Icon(Icons.place, color: royal), const SizedBox(width: 8), Expanded(child: Text(location))]),
                  ],
                ]),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Contact', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Row(children: [Icon(Icons.email, color: royal), const SizedBox(width: 8), Expanded(child: Text(email.isNotEmpty ? email : 'Not available'))]),
                const SizedBox(height: 8),
                Row(children: [Icon(Icons.phone, color: royal), const SizedBox(width: 8), Expanded(child: Text(phone.isNotEmpty ? phone : 'Not available'))]),
              ]),
            ),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}
