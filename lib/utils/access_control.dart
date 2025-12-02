import 'package:flutter/material.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/utils/app_config.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';

class AccessControl {

  /// VERIFICA SE O USUÁRIO É PREMIUM (admin, dev ou premium no banco)
  static Future<bool> isPremium() async {
    final user = SupabaseConfig.client.auth.currentUser;

    // Visitante → não é premium
    if (user == null) return false;

    // Modo dev → premium liberado
    if (AppConfig.devMode) return true;

    // Admin por email → premium
    if (AppConfig.isAdmin(user.email)) return true;

    // Buscar premium no banco
    final profile = await SupabaseConfig.client
        .from('profiles')
        .select('is_premium')
        .eq('id', user.id)
        .maybeSingle();

    return profile?['is_premium'] == true;
  }

  /// VERIFICA SE O USUÁRIO É FREE / VISITANTE
  static bool isFree() {
    final user = SupabaseConfig.client.auth.currentUser;
    return user == null;
  }

  /// CHECAGEM AUTOMÁTICA USADA PELO PremiumProtectedPage
  static Future<void> checkAccess(BuildContext context) async {
    final premium = await isPremium();

    if (!premium) {
      showPremiumPopup(context);
    }
  }
}
