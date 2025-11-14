import 'package:flutter/material.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/screens/premium/premium_page.dart';

class AccessControl {
  static final _client = SupabaseConfig.client;

  /// 💎 Verifica no Supabase se o usuário tem plano Premium
  static Future<bool> checkPremiumStatus(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('plan_type')
          .eq('id', userId)
          .maybeSingle();

      final plan = response?['plan_type'] ?? 'free';
      return plan == 'premium';
    } catch (e) {
      debugPrint('❌ Erro ao verificar status premium: $e');
      return false;
    }
  }

  /// 💎 Checa plano premium pelo perfil local
  static bool isPremium(Map<String, dynamic>? userProfile) {
    if (userProfile == null) return false;
    return userProfile['plan_type'] == 'premium';
  }

  /// 💬 Checa se é plano free ou convidado
  static bool isFree(Map<String, dynamic>? userProfile) {
    if (userProfile == null) return true;
    return userProfile['plan_type'] == 'free' ||
        userProfile['plan_type'] == 'guest';
  }

  /// 🔄 Compatibilidade com versões antigas (usa isPremium internamente)
  static bool canAccessPremium(Map<String, dynamic>? userProfile) {
    return isPremium(userProfile);
  }

  /// 💬 Mostra popup de login (usuários não logados)
  static void showLoginPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            backgroundColor: const Color(0xFFFDF3F6),
            title: const Text(
              "Faça login ✨",
              style: TextStyle(
                color: Color(0xFFE569BF),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            content: const Text(
              "Para salvar suas metas e continuar acompanhando suas conquistas, entre ou crie uma conta.",
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Agora não",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffe569bf),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Fazer login"),
              ),
            ],
          ),
    );
  }

  /// 💖 Mostra popup Premium (mantém o antigo e adiciona botão "Conhecer Premium")
  static void showPremiumPopup(BuildContext context, [int? month, int? year]) {
    showDialog(
      context: context,
      builder: (context) {
        // 🔹 Usa o novo popup estilizado com botão para página Premium
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFFFFEEF1),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 28),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite,
                color: Color(0xFFC03B66),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                "Premium Feature",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFC03B66),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                "Com o plano Premium, você desbloqueia todas as perguntas e pode salvar quantas memórias quiser! 🌟",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4F4F4F),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Agora não",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PremiumPage(
                                
                              ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC03B66),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                    ),
                    child: const Text(
                      "Conhecer Premium",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}