import 'package:supabase_flutter/supabase_flutter.dart';

class ManagerAuth {
  final SupabaseClient supabase;

  ManagerAuth({required this.supabase});

  Future<bool> isAuthenticated() async {
    final response = await supabase.auth.currentUser?.id != null;
    return response;
  }
}
