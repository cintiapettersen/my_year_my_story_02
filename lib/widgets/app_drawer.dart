import 'package:flutter/material.dart';
import 'package:my_year_my_story/screens/profile/profile_screen.dart';
import 'package:my_year_my_story/screens/settings/settings_screen.dart';
import 'package:my_year_my_story/screens/about/about_screen.dart';
import 'package:my_year_my_story/screens/help/help_screen.dart';
import 'package:my_year_my_story/widgets/app_drawer.dart';


class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const UserAccountsDrawerHeader(
            accountName: Text('Cíntia'),
            accountEmail: Text('email@sonhodepapel.com'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.purple,
              child: Icon(Icons.person, color: Colors.white),
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
            icon: Icons.settings_outlined,
            title: 'Configurações',
            screen: const SettingsScreen(),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.info_outline,
            title: 'Sobre o App',
            screen: const AboutScreen(),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.help_outline,
            title: 'Ajuda / Suporte',
            screen: const HelpScreen(),
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Sair'),
            onTap: () {
              Navigator.pop(context);
              // TODO: conectar logout com Supabase
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context,
      {required IconData icon,
        required String title,
        required Widget screen}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
    );
  }
}
