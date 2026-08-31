import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessSettings {
  const BusinessSettings({
    required this.address,
    required this.receiptHeader,
    required this.receiptFooter,
    required this.darkMode,
    required this.autoInput,
  });

  final String address;
  final String receiptHeader;
  final String receiptFooter;
  final bool darkMode;
  final bool autoInput;

  factory BusinessSettings.fromMap(Map<String, dynamic> row) => BusinessSettings(
        address: (row['address'] ?? '') as String,
        receiptHeader: (row['receipt_header'] ?? '') as String,
        receiptFooter: (row['receipt_footer'] ?? '') as String,
        darkMode: (row['dark_mode'] ?? false) as bool,
        autoInput: (row['auto_input'] ?? true) as bool,
      );
}

class BusinessSettingsRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<BusinessSettings?> load(String businessId) async {
    final row = await _client
        .from('irkop_cell_business_settings')
        .select()
        .eq('business_id', businessId)
        .maybeSingle();
    if (row == null) return null;
    return BusinessSettings.fromMap(row);
  }

  Future<void> save({
    required String businessId,
    required String address,
    required String receiptHeader,
    required String receiptFooter,
    required bool darkMode,
    required bool autoInput,
  }) async {
    await _client.from('irkop_cell_business_settings').upsert({
      'business_id': businessId,
      'address': address.trim(),
      'receipt_header': receiptHeader.trim(),
      'receipt_footer': receiptFooter.trim(),
      'dark_mode': darkMode,
      'auto_input': autoInput,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'business_id');
  }
}
