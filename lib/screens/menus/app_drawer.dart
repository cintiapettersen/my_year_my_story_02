import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:myyearmystory/main.dart';
import 'package:myyearmystory/services/profile_service.dart';

import 'glass_drawer.dart';
import 'glass_drawer_item.dart';
import 'premium_button_glass.dart';
import 'about_modal.dart';

import '../menus/help_screen.dart';
import '../premium/premium_page.dart';
import '../menus/language_screen.dart';

import 'package:myyearmystory/services/app_session.dart';
import 'package:myyearmystory/screens/auth/login_screen.dart';
import 'package:myyearmystory/screens/auth/signup_screen.dart';
import '../menus/profile_screen.dart';


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
    _loadProfile();
  }

  // ------------------------------------------------------
  // LOAD PROFILE
  // ------------------------------------------------------
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

  // ------------------------------------------------------
  // EMOJI BUTTON (AGORA NO LUGAR CERTO!)
  // ------------------------------------------------------
  Widget _emojiButton(String emoji) {
    final bool isSelected = (emoji == avatarEmoji);

    return GestureDetector(
      onTap: () async {
        setState(() => avatarEmoji = emoji);

        // salvar local
        await storage.write(key: "avatar_icon", value: emoji);

        // salvar no supabase
        try {
          final user = profileService.profile;
          if (user != null && user["id"] != null) {
            await Supabase.instance.client
                .from("profiles")
                .update({"avatar_emoji": emoji})
                .eq("id", user["id"]);
          }
        } catch (e) {
          debugPrint("Erro ao salvar emoji: $e");
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(isSelected ? 0.40 : 0.18),
          border: Border.all(
            color: Colors.white.withOpacity(isSelected ? 0.9 : 0.5),
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }

  // ------------------------------------------------------
  // UI
  // ------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final bool isGuest = user == null;

    return GlassDrawer(
      children: [
        const SizedBox(height: 54),

        // ------------------------------------------------------
        // HEADER
        // ------------------------------------------------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
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

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?['full_name'] ?? "drawer.guest_name".tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      profile?['email'] ?? "email",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ------------------------------------------------------
        // TROCAR ÍCONE
        // ------------------------------------------------------
        Padding(
          padding: const EdgeInsets.only(left: 24, top: 8, bottom: 10),
          child: Text(
            "drawer.change_icon".tr(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
            ),
          ),
        ),

        // Lista horizontal de emojis
        Padding(
          padding: const EdgeInsets.only(left: 24, bottom: 18),
          child: SizedBox(
            height: 62,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _emojiButton("🌸"),
                _emojiButton("👑"),
                _emojiButton("💖"),
                _emojiButton("🌙"),
                _emojiButton("⭐"),
                _emojiButton("🍒"),
                _emojiButton("🦋"),
                _emojiButton("🌼"),
              ],
            ),
          ),
        ),

        // ------------------------------------------------------
        // PREMIUM BUTTON
        // ------------------------------------------------------
        PremiumButtonGlass(
          onTap: () {
            Navigator.pop(context);

            Future.delayed(const Duration(milliseconds: 40), () {
              showGeneralDialog(
                context: navigatorKey.currentContext!,
                barrierDismissible: true,
                barrierLabel: "premium",
                barrierColor: Colors.black.withOpacity(0.05),
                transitionBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                pageBuilder: (context, animation, secondaryAnimation) {
                  return const PremiumPage();
                 
                },
              );
            });
          },
        ),

         const SizedBox(height: 24), // ou 32 se quiser maior

         
        // ------------------------------------------------------
        // MENU ITEMS
        // ------------------------------------------------------
        if (!isGuest)
       GlassDrawerItem(
      icon: Icons.person_outline,
       color: Colors.white,
       text: "drawer.profile".tr(),
         onTap: () => _open(context, const ProfileScreen()),
  ),

        GlassDrawerItem(
           icon:  Icons.translate,
           color: Colors.white,
           text: "drawer.language".tr(),
           onTap: () => _open(context, const LanguageScreen()),
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
          onTap: () => _open(context, const AboutAppScreen()),

        ),

        
        

      

         const SizedBox(height: 240),

if (isGuest)
  GlassDrawerItem(
    icon: Icons.login,
    color: Colors.white,
    text: "drawer.login_or_create".tr(),
    onTap: () {
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            onCreateAccountTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SignupScreen(),
                ),
              );
            },
          ),
        ),
      );
    },
  )
else
  GlassDrawerItem(
    icon: Icons.logout,
    color: Colors.pinkAccent,
    text: "drawer.logout".tr(),
    onTap: () => _logout(context),
  ),


        
      ],
    );
  }

  // ------------------------------------------------------
  // Navegação
  // ------------------------------------------------------
  void _open(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

 Future<void> _logout(BuildContext context) async {
  // 1. Marca que estamos saindo
  AppSession.flow = AppAuthFlow.loggingOut;

  // 2. Fecha o drawer
  Navigator.pop(context);

  // 3. Chama o logout REAL
  await Supabase.instance.client.auth.signOut();

  // ❌ NÃO navega
  // ❌ NÃO chama /login
  // ❌ NÃO limpa storage aqui
}

}