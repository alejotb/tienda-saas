import 'package:baul_pandora/backend/supabase/supabase.dart';

Future<User?> emailSignInFunc(
  String email,
  String password,
) async {
  final AuthResponse res = await SupaFlow.client.auth
      .signInWithPassword(email: email, password: password);
  return res.user;
}

Future<User?> emailCreateAccountFunc(
  String email,
  String password, [
  Map<String, dynamic>? data,
]) async {
  final AuthResponse res = await SupaFlow.client.auth.signUp(
    email: email,
    password: password,
    data: data,
  );

  // Si Supabase devuelve sesión activa (confirmación de email desactivada), retornamos el usuario directamente.
  if (res.session != null) {
    return res.user;
  }
  return res.user?.lastSignInAt == null ? null : res.user;
}
