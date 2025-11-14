import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/screens/profile/profile_screen.dart';
import 'package:myyearmystory/screens/premium/premium_page.dart';
import 'package:myyearmystory/screens/help/help_screen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? userFullName;
  String? userEmail;
  String? userPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      final response = await SupabaseConfig.client
          .from('profiles')
          .select('full_name, photo_url')
          .eq('id', user.id)
          .single();

      setState(() {
        userFullName = response['full_name'];
        userPhotoUrl = response['photo_url'];
        userEmail = user.email;
      });
    } catch (e) {
      debugPrint('❌ Erro ao carregar dados do Drawer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(userFullName ?? 'Usuário'),
            accountEmail: Text(userEmail ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundImage: userPhotoUrl != null && userPhotoUrl!.isNotEmpty
                  ? NetworkImage(userPhotoUrl!)
                  : null,
              backgroundColor: Colors.purple,
              child: userPhotoUrl == null || userPhotoUrl!.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.pinkAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          _buildDrawerItem(
            context,
            icon: Icons.person_outline,
            title: 'Meu Perfil',
            screen: const ProfileScreen(),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.star_outline,
            title: 'Plano Premium',
            screen: PremiumPage(
              
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.help_outline,
            title: 'Ajuda / Suporte',
            screen: const HelpScreen(),
          ),

          const Divider(height: 30),
          ListTile(
            leading: const Icon(Icons.lock_reset_outlined),
            title: const Text('Recuperar senha'),
            onTap: () => _showResetPasswordDialog(context),
          ),

          const Spacer(),
          const Divider(),

          // 🔻 Botão de sair atualizado
          ListTile(
  leading: const Icon(Icons.logout, color: Colors.redAccent),
  title: const Text('Sair'),
  onTap: () async {
    try {
      final storage = const FlutterSecureStorage();

      // Faz logout do Supabase
      await SupabaseConfig.client.auth.signOut();

      // Limpa tudo o que o app salvou (inclusive a sessão biométrica)
      await storage.deleteAll();

      // Pequeno delay pra garantir que a limpeza finalize antes da navegação
      await Future.delayed(const Duration(milliseconds: 300));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sessão encerrada com sucesso 👋'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Redireciona pro login e remove histórico
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao sair: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao sair. Tente novamente.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  },
),


        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget screen,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
    );
  }

  void _showResetPasswordDialog(BuildContext context) {
    final emailController = TextEditingController(text: userEmail ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar senha'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'E-mail de recuperação',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Enviar link'),
            onPressed: () async {
              try {
                await SupabaseConfig.client.auth
                    .resetPasswordForEmail(emailController.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Link de recuperação enviado por e-mail!',
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                debugPrint('❌ Erro ao enviar reset: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Não foi possível enviar o e-mail de recuperação.',
                      ),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
