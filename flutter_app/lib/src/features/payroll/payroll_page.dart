import 'package:flutter/material.dart';

class PayrollPage extends StatelessWidget {
  const PayrollPage({super.key, this.businessId});
  final String? businessId;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.payments_outlined, size: 40),
                  const SizedBox(height: 16),
                  Text('Gaji Karyawan', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  const Text('Kelola periode dan pembayaran gaji karyawan.'),
                  const SizedBox(height: 20),
                  const Text('Belum ada data untuk ditampilkan.'),
                ],
              ),
            ),
          ),
        ],
      );
}
