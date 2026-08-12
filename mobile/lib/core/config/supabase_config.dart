import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  const SupabaseConfig._();

  static String get url {
    final value = dotenv.env['SUPABASE_URL'];

    if (value == null || value.isEmpty) {
      throw StateError('SUPABASE_URL is not configured.');
    }

    return value;
  }

  static String get publishableKey {
    final value = dotenv.env['SUPABASE_PUBLISHABLE_KEY'];

    if (value == null || value.isEmpty) {
      throw StateError('SUPABASE_PUBLISHABLE_KEY is not configured.');
    }

    return value;
  }
}
