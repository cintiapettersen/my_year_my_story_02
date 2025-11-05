import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? profileData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final user = supabase.auth.currentUser;

    if (user != null) {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          profileData = response ?? {
            'id': user.id,
            'full_name': user.userMetadata?['name'] ?? 'Usuário',
            'email': user.email,
          };
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
        profileData = null;
      });
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('drawer.logout_title'.tr()),
        content: Text('drawer.logout_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('drawer.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('drawer.logout'.tr()),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await supabase.auth.signOut();

      if (mounted) {
        setState(() {
          profileData = null;
        });
      }

      navigatorKey.currentState?.pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = profileData?['full_name'] ?? 'drawer.guest'.tr();
    final isPremium = profileData?['is_premium'] ?? false;
    final photoUrl = profileData?['photo_url'];

    return Drawer(
      backgroundColor: const Color(0xFFFCEAF3),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.all(54),
            decoration: const BoxDecoration(
              color: Color(0xFFF8DDE7),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage:
                  photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? const Text('🌸', style: TextStyle(fontSize: 40))
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  '${'drawer.hello'.tr()} $fullName!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text('My Year, My Story'),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    navigatorKey.currentState?.pushNamed('/premium');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.pinkAccent, width: 2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      isPremium
                          ? 'drawer.premium_active'.tr()
                          : 'drawer.go_premium'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isPremium ? Colors.green[800] : Colors.pink[800],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 🌸 Itens do menu
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text('drawer.profile'.tr()),
            onTap: () {
              Navigator.pop(context);
              navigatorKey.currentState?.pushNamed('/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text('drawer.help'.tr()),
            onTap: () {
              Navigator.pop(context);
              navigatorKey.currentState?.pushNamed('/help');
            },
          ),

          // 🌍 Idioma
          ListTile(
            leading: const Icon(Icons.language),
            title: Text('drawer.language'.tr()),
            onTap: () {
              Navigator.pop(context);
              _showLanguageSelector(context);
            },
          ),

          const Divider(thickness: 1.2),

          // 🌸 Login / Logout
          ListTile(
            leading:
            Icon(profileData == null ? Icons.login : Icons.logout),
            title: Text(profileData == null
                ? 'drawer.login'.tr()
                : 'drawer.logout'.tr()),
            onTap: () async {
              Navigator.pop(context);
              if (profileData != null) {
                await _confirmLogout();
              } else {
                navigatorKey.currentState?.pushNamed('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    final currentLocale = context.locale; // pega o idioma atual

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'drawer.select_language'.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // 🇧🇷 Português
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  await EasyLocalization.of(navigatorKey.currentContext!)
                      ?.setLocale(const Locale('pt',));

                  if (navigatorKey.currentContext != null) {
                    ScaffoldMessenger.of(navigatorKey.currentContext!)
                        .showSnackBar(
                      const SnackBar(
                        content: Text('Idioma alterado para Português 🇧🇷'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }

                  Navigator.pop(sheetContext);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: currentLocale.languageCode == 'pt'
                        ? const Color(0xFFF8DDE7) // rosado suave quando selecionado
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Text('🇧🇷', style: TextStyle(fontSize: 22)),
                          SizedBox(width: 12),
                          Text(
                            'Português',
                            style:
                            TextStyle(fontSize: 18, color: Colors.black87),
                          ),
                        ],
                      ),
                      if (currentLocale.languageCode == 'pt')
                        const Icon(Icons.check, color: Colors.pinkAccent),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 🇺🇸 English
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  await EasyLocalization.of(navigatorKey.currentContext!)
                      ?.setLocale(const Locale('en',));

                  if (navigatorKey.currentContext != null) {
                    ScaffoldMessenger.of(navigatorKey.currentContext!)
                        .showSnackBar(
                      const SnackBar(
                        content: Text('Language changed to English 🇺🇸'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }

                  Navigator.pop(sheetContext);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: currentLocale.languageCode == 'en'
                        ? const Color(0xFFF8DDE7)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Text('🇺🇸', style: TextStyle(fontSize: 22)),
                          SizedBox(width: 12),
                          Text(
                            'English',
                            style:
                            TextStyle(fontSize: 18, color: Colors.black87),
                          ),
                        ],
                      ),
                      if (currentLocale.languageCode == 'en')
                        const Icon(Icons.check, color: Colors.pinkAccent),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}
