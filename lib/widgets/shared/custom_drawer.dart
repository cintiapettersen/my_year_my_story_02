import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import 'package:myyearmystory/services/profile_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({Key? key}) ;

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

    // Carrega o profile inicial
    loadProfile();

    // Atualiza automaticamente quando profileService mudar
    profileService.addListener(_onProfileUpdated);
  }

  @override
  void dispose() {
    profileService.removeListener(_onProfileUpdated);
    super.dispose();
  }

  // 🔄 Quando o ProfileService atualizar, atualizar o Drawer também
  void _onProfileUpdated() {
    if (!mounted) return;

    setState(() {
      profileData = profileService.profile; // ← CORRETO!
    });
  }

  Future<void> loadProfile() async {
    final user = supabase.auth.currentUser;

    if (user != null) {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      setState(() {
        profileData = response ??
            {
              'id': user.id,
              'full_name': user.userMetadata?['name'] ?? 'drawer.guest'.tr(),
              'email': user.email,
            };
        isLoading = false;
      });

      // Atualiza ProfileService corretamente
      profileService.profile = profileData; // ← SEM setProfile()
      profileService.notifyListeners();
    } else {
      setState(() {
        isLoading = false;
        profileData = null;
      });
    }
  }

  /// 🔐 Logout
  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('drawer.logout_title'.tr()),
        content: Text('drawer.logout_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('drawer.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'drawer.logout'.tr(),
              style: const TextStyle(color: Colors.pinkAccent),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    try {
      await supabase.auth.signOut(scope: SignOutScope.local);
      await supabase.removeAllChannels();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('remembered_email');
      await prefs.remove('remembered_password');
      await prefs.setBool('remember_me', false);

      if (!mounted) return;

      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('drawer.logout_success'.tr()),
          backgroundColor: Colors.pinkAccent,
        ),
      );
    } catch (e) {
      debugPrint('Erro ao sair: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = profileData?['full_name'] ?? 'drawer.guest'.tr();
    final isPremium = profileData?['is_premium'] ?? false;
    final photoUrl = profileData?['photo_url'];

    return Drawer(
      backgroundColor: const Color(0xFFFCEAF3),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // HEADER ORIGINAL — intacto 💗
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
                  ),

                  const SizedBox(height: 6),
                  const Text('My Year, My Story'),

                  const SizedBox(height: 16),

                  // PREMIUM BUTTON
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      navigatorKey.currentState?.pushNamed('/premium');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.pinkAccent, width: 2),
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFBE4ED), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          isPremium
                              ? 'drawer.premium_active'.tr()
                              : 'drawer.go_premium'.tr(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isPremium
                                ? Colors.green[800]
                                : Colors.pink[800],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // MENU ORIGINAL — intacto 💗
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

            ListTile(
              leading: const Icon(Icons.language),
              title: Text('drawer.language'.tr()),
              onTap: () {
                Navigator.pop(context);
                _showLanguageSelector(context);
              },
            ),

            const Divider(),

            ListTile(
              leading: Icon(profileData == null
                  ? Icons.login
                  : Icons.logout),
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
      ),
    );
  }

  // Language selector — mantido
  void _showLanguageSelector(BuildContext context) { /* ... */ }
}
