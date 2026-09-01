import 'package:flutter/material.dart';

class ServicePage extends StatelessWidget {
  const ServicePage({super.key, this.businessId});
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
                  const Icon(Icons.phone_android_outlined, size: 40),
                  const SizedBox(height: 16),
                  Text('Service HP', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  const Text('Catat penerimaan perangkat dan pantau progres pengerjaan service.'),
                  const SizedBox(height: 20),
                  const Text('Belum ada tiket service.'),
                ],
              ),
            ),
          ),
        ],
      );
}
