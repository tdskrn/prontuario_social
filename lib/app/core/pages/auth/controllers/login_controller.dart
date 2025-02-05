import 'package:supabase_flutter/supabase_flutter.dart';

class LoginController {
  final SupabaseClient supabase;

  LoginController({
    required this.supabase,
  });

  Future signIn(String email, String password) async {
    await supabase.auth.signInWithPassword(email: email, password: password);

    print('depois do controller');
  }

  Future<void> signOut() async {
    supabase.auth.signOut();
  }
}
