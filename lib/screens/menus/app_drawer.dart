import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:myyearmystory/services/profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


import 'glass_drawer.dart';
import 'glass_drawer_item.dart';
import 'premium_button_glass.dart';
import 'about_modal.dart';

// telas
import 'profile_screen.dart';
import 'help_screen.dart';

// storage local para salvar avatar
final storage = const FlutterSecureStorage();

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final profileService = ProfileService();

  Map<String, dynamic>? profile;
  String avatarEmoji = "🌸";

  @override
  void initState() {
    super.initState();
    _loadProfile();      // ← agora carrega nome + email + avatar
  }

  /// Carrega nome, email e avatar do Supabase
  Future<void> _loadProfile() async {
    await profileService.load();
    final data = profileService.profile;

    if (data != null) {
      setState(() {
        profile = data;
        avatarEmoji = data["avatar_emoji"] ?? "🌸";
      });
    }
  }

  /// Salva avatar no Supabase
  Future<void> _saveAvatarEmoji(String emoji) async {
  setState(() => avatarEmoji = emoji);

  // salva local
  await storage.write(key: "avatar_icon", value: emoji);

  try {
    final user = profileService.profile;

    if (user != null && user["id"] != null) {
      await Supabase.instance.client
          .from("profiles")
          .update({"avatar_emoji": emoji})
          .eq("id", user["id"]);
    }
  } catch (e) {
    debugPrint("Erro ao atualizar avatar no Supabase: $e");
  }

  if (mounted) Navigator.pop(context);
}





  @override
  Widget build(BuildContext context) {
    return GlassDrawer(
      children: [
        const SizedBox(height: 54),

        // -------------------------------------------------------
        // HEADER
        // -------------------------------------------------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // Avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.7),
                        width: 1.4,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        avatarEmoji,
                        style: const TextStyle(fontSize: 38),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Nome + Email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?['full_name'] ?? "Seu nome",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      profile?['email'] ?? "Seu e-mail",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // -------------------------------------------------------
        // TEXTO "TROCAR ÍCONE" — alinhado à esquerda
        // -------------------------------------------------------
        Padding(
          padding: const EdgeInsets.only(left: 24, top: 8, bottom: 10),
          child: GestureDetector(
            onTap: _showIconSelector,
            child: Text(
              "drawer.change_icon".tr(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ),

        // botão premium
        PremiumButtonGlass(
          onTap: () => Navigator.pushNamed(context, "/premium"),
        ),

        // itens do menu
        GlassDrawerItem(
          icon: Icons.person_outline,
          color: Colors.white,
          text: "drawer.profile".tr(),
          onTap: () => _open(context, const ProfileScreen()),
        ),

        GlassDrawerItem(
          icon: Icons.help_outline,
          color: Colors.white,
          text: "drawer.help".tr(),
          onTap: () => _open(context, const HelpScreen()),
        ),

        GlassDrawerItem(
          icon: Icons.info_outline,
          color: Colors.white,
          text: "drawer.about".tr(),
          onTap: () => showAboutAppModal(context),
        ),

        const Spacer(),

        GlassDrawerItem(
          icon: Icons.logout,
          color: Colors.pinkAccent,
          text: "drawer.logout".tr(),
          onTap: () => _logout(context),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  // -------------------------------------------------------
  // Navegação
  // -------------------------------------------------------
  void _open(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  // -------------------------------------------------------
  // Logout
  // -------------------------------------------------------
  Future<void> _logout(BuildContext context) async {
    await storage.deleteAll();
    Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
  }

  // -------------------------------------------------------
  // MODAL DE SELEÇÃO DE ÍCONE
  // -------------------------------------------------------
  void _showIconSelector() {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (_) {
        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 280,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1.2,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Escolha seu ícone",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _iconOption("🌸"),
                        _iconOption("⭐"),
                        _iconOption("💎"),
                        _iconOption("👑"),
                        _iconOption("🌙"),
                        _iconOption("✨"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------
  // COMPONENTE DO ÍCONE
  // -------------------------------------------------------
  Widget _iconOption(String emoji) {
    return GestureDetector(
      onTap: () => _saveAvatarEmoji(emoji),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(0.30),
          ),
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 32),
          ),
        ),
      ),
    );
  }
}
