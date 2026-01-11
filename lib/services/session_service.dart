import 'package:myyearmystory/supabase/supabase_config.dart';

class SessionService {
  static String? get userId =>
      SupabaseConfig.client.auth.currentUser?.id;

  static String? get email =>
      SupabaseConfig.client.auth.currentUser?.email;

  static bool get isLogged =>
      SupabaseConfig.client.auth.currentUser != null;

  static bool get isGuest => !isLogged;
}
