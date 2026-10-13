  import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'office_detail.dart';

class OfficesScreen extends StatelessWidget {
  const OfficesScreen({super.key});

  static const List<Map<String, String>> _seedOffices = [
    {
      'name': 'ITSO',
      'role': 'Information Technology Services Office — manages campus IT systems, accounts and support.',
      'description': 'Supports student and staff technology needs, including account provisioning, Wi‑Fi access, email setup, NUIS access, lab resources, and troubleshooting for campus systems. Handles ID card activation and IT policy concerns.',
      'services': 'NUIS/Email access, Wi‑Fi support, device troubleshooting, ID validation, lab scheduling, software access',
      'location': 'IT Building, 2nd Floor',
      'hours': 'Mon–Fri 8:00 AM–5:00 PM',
      'email': 'itso@nu.edu',
      'phone': '+63 2 1234 0001'
    },
    {
      'name': 'SDAO',
      'role': 'Student Affairs Office — student support, activities and welfare.',
      'description': 'Oversees student engagement, co‑curricular activities, student welfare concerns, and coordination with student organizations. Guides students on conduct, discipline, and student leadership opportunities.',
      'services': 'Student orgs, activities, conduct concerns, student welfare',
      'location': 'Student Center, Ground Floor',
      'hours': 'Mon–Fri 8:00 AM–5:00 PM',
      'email': 'sdao@nu.edu',
      'phone': '+63 2 1234 0002'
    },
    {
      'name': 'Registrar',
      'role': 'Handles enrollment records, transcripts and academic scheduling.',
      'description': 'Manages student records, enrollment validation, certificates of registration, transcript requests, graduation processing, and academic records inquiries.',
      'services': 'Enrollment validation, TOR requests, COR issuance, graduation processing',
      'location': 'Admin Building, 1st Floor',
      'hours': 'Mon–Fri 8:00 AM–5:00 PM',
      'email': 'registrar@nu.edu',
      'phone': '+63 2 1234 0003'
    },
    {
      'name': 'Treasury',
      'role': 'Manages student billing, payments, and financial inquiries.',
      'description': 'Handles assessment of fees, payment confirmation, billing concerns, refunds, and student ledger questions. Coordinates payment channels and installment arrangements.',
      'services': 'Billing concerns, payment posting, refunds, installment plans',
      'location': 'Admin Building, 1st Floor',
      'hours': 'Mon–Fri 8:00 AM–5:00 PM',
      'email': 'treasury@nu.edu',
      'phone': '+63 2 1234 0004'
    },
    {
      'name': 'FMO',
      'role': 'Facilities Management Office — oversees campus facilities and maintenance.',
      'description': 'Ensures campus facilities are safe, clean, and functional. Handles maintenance requests, room reservations support, and facility-related concerns.',
      'services': 'Maintenance requests, facility concerns, room support',
      'location': 'Maintenance Wing, Ground Floor',
      'hours': 'Mon–Fri 8:00 AM–5:00 PM',
      'email': 'fmo@nu.edu',
      'phone': '+63 2 1234 0005'
    },
  ];

  static const Map<String, Map<String, String>> _officeDefaults = {
    'Information Technology Support Office': {
      'role': 'Information Technology Services Office — manages campus IT systems, accounts and support.',
      'description': 'Supports student and staff technology needs, including account provisioning, Wi‑Fi access, email setup, NUIS access, lab resources, and troubleshooting for campus systems. Handles ID card activation and IT policy concerns.',
      'services': 'NUIS/Email access, Wi‑Fi support, device troubleshooting, ID validation, lab scheduling, software access',
      'location': 'IT Building, 2nd Floor',
      'hours': 'Mon–Fri 8:00 AM–5:00 PM',
      'email': 'itso@nu.edu',
      'phone': '+63 2 1234 0001',
    },
    'Student Affairs Office': {
      'role': 'Student Affairs Office — student support, activities and welfare.',
      'description': 'Oversees student engagement, co‑curricular activities, student welfare, and student leadership opportunities. Guides students on conduct and discipline processes.',
      'services': 'Student orgs, activities, conduct concerns, student welfare',
      'location': 'Student Center, Ground Floor',
      'hours': 'Mon–Fri 8:00 AM–5:00 PM',
      'email': 'sdao@nu.edu',
      'phone': '+63 2 1234 0002',
    },
    'Students Affair Office': {
      'role': 'Student Affairs Office — student support, activities and welfare.',
      'description': 'Oversees student engagement, co‑curricular activities, student welfare, and student leadership opportunities. Guides students on conduct and discipline processes.',
      'services': 'Student orgs, activities, conduct concerns, student welfare',
      'location': 'Student Center, Ground Floor',
      'hours': 'Mon–Fri 8:00 AM–5:00 PM',
      'email': 'sdao@nu.edu',
      'phone': '+63 2 1234 0002',
    },
    'Students Affairs Office': {
      'role': 'Student Affairs Office — student support, activities and welfare.',
      'description': 'Oversees student engagement, co‑curricular activities, student welfare, and student leadership opportunities. Guides students on conduct and discipline processes.',
      'services': 'Student orgs, activities, conduct concerns, student welfare',
      'location': 'Student Center, Ground Floor',
      'hours': 'Mon–Fri 8:00 AM–5:00 PM',
      'email': 'sdao@nu.edu',
      'phone': '+63 2 1234 0002',
    },
    'Student Affairs and Development Office': {
      'role': 'Student Affairs Office — student support, activities and welfare.',
      'description': 'Oversees student engagement, co‑curricular activities, student welfare, and student leadership opportunities. Guides students on conduct and discipline processes.',
      'services': 'Student orgs, activities, conduct concerns, student welfare',
      'location': 'Student Center, Ground Floor',
      'hours': 'Mon–Fri 8:00 AM–5:00 PM',
      'email': 'sdao@nu.edu',
      'phone': '+63 2 1234 0002',
    },
    'Facilities Management Office': {
      'description': 'Ensures campus facilities are safe, clean, and functional. Handles maintenance requests, room reservations support, and facility-related concerns.',
      'services': 'Maintenance requests, facility concerns, room support',
      'location': 'Maintenance Wing, Ground Floor',
      'hours': 'Mon–Fri 8:00 AM–5:00 PM',
      'email': 'fmo@nu.edu',
      'phone': '+63 2 1234 0005',
    },
    'ITSO': {
      'role': 'Information Technology Services Office — manages campus IT systems, accounts and support.',
      'description': 'Supports student and staff technology needs, including account provisioning, Wi‑Fi access, email setup, NUIS access, lab resources, and troubleshooting for campus systems. Handles ID card activation and IT policy concerns.',
      'services': 'NUIS/Email access, Wi‑Fi support, device troubleshooting, ID validation, lab scheduling, software access',
      'location': 'IT Building, 2nd Floor',
      'hours': 'Mon–Fri 8:00 AM–5:00 PM',
      'email': 'itso@nu.edu',
      'phone': '+63 2 1234 0001',
    },
    'SDAO': {
      'role': 'Student Affairs Office — student support, activities and welfare.',
      'description': 'Oversees student engagement, co‑curricular activities, student welfare, and student leadership opportunities. Guides students on conduct and discipline processes.',
      'services': 'Student orgs, activities, conduct concerns, student welfare',
      'location': 'Student Center, Ground Floor',
      'hours': 'Mon–Fri 8:00 AM–5:00 PM',
      'email': 'sdao@nu.edu',
      'phone': '+63 2 1234 0002',
    },
    'Registrar': {
      'description': 'Manages student records, enrollment validation, certificates of registration, transcript requests, graduation processing, and academic records inquiries.',
      'services': 'Enrollment validation, TOR requests, COR issuance, graduation processing',
      'location': 'Admin Building, 1st Floor',
      'hours': 'Mon–Fri 8:00 AM–5:00 PM',
    },
    'Treasury': {
      'description': 'Handles assessment of fees, payment confirmation, billing concerns, refunds, and student ledger questions. Coordinates payment channels and installment arrangements.',
      'services': 'Billing concerns, payment posting, refunds, installment plans',
      'location': 'Admin Building, 1st Floor',
      'hours': 'Mon–Fri 8:00 AM–5:00 PM',
    },
    'FMO': {
      'description': 'Ensures campus facilities are safe, clean, and functional. Handles maintenance requests, room reservations support, and facility-related concerns.',
      'services': 'Maintenance requests, facility concerns, room support',
      'location': 'Maintenance Wing, Ground Floor',
      'hours': 'Mon–Fri 8:00 AM–5:00 PM',
      'email': 'fmo@nu.edu',
      'phone': '+63 2 1234 0005',
    },
  };

  Map<String, String> _resolveDefaults(String name) {
    if (_officeDefaults.containsKey(name)) return _officeDefaults[name]!;
    final key = _officeDefaults.keys.firstWhere(
      (k) => name.toLowerCase().contains(k.toLowerCase()),
      orElse: () => '',
    );
    if (key.isNotEmpty) return _officeDefaults[key]!;
    return const {};
  }

  Future<void> _seedSampleOffices() async {
    final batch = FirebaseFirestore.instance.batch();
    final col = FirebaseFirestore.instance.collection('offices');
    for (final office in _seedOffices) {
      final ref = col.doc();
      batch.set(ref, {
        ...office,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final royal = Theme.of(context).colorScheme.primary;
    final gold = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(title: const Text('Offices')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('offices')
              .orderBy('name')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No offices available'),
                    const SizedBox(height: 12),
                    FutureBuilder<bool>(
                      future: AuthService.instance.isAdmin(),
                      builder: (context, adminSnap) {
                        if (adminSnap.data != true) {
                          return const SizedBox();
                        }
                        return ElevatedButton.icon(
                          onPressed: () async {
                            await _seedSampleOffices();
                          },
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text('Seed sample offices'),
                        );
                      },
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final data = docs[i].data();
                final name = data['name']?.toString() ?? 'Office';
                final role = data['role']?.toString() ?? '';
                final defaults = _resolveDefaults(name);
                final description = (data['description'] ?? defaults['description'] ?? '').toString();
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => OfficeDetail(data: {...defaults, ...data})),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: gold,
                      child: Text(name.isNotEmpty ? name[0] : 'O', style: TextStyle(color: royal)),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      description.isNotEmpty ? description : role,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Icon(Icons.chevron_right, color: royal),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
