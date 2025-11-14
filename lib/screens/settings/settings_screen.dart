import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myyearmystory/services/user_service.dart';
import 'package:myyearmystory/screens/auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _dailyReminders = true;
  bool _weeklyReports = false;
  bool _darkMode = false;
  bool _rememberMeEnabled = false;
  String _selectedLanguage = 'Português';

  @override
  void initState() {
    super.initState();
    _loadRememberMeSettings();
  }

  Future<void> _loadRememberMeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMeEnabled = prefs.getBool('remember_me') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Configurações',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildNotificationSection(),
            const SizedBox(height: 16),
            _buildAppearanceSection(),
            const SizedBox(height: 16),
            _buildLanguageSection(),
            const SizedBox(height: 16),
            _buildLoginSecuritySection(),
            const SizedBox(height: 16),
            _buildPrivacySection(),
            const SizedBox(height: 16),
            _buildSupportSection(),
            const SizedBox(height: 16),
            _buildAboutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return _buildSettingsCard(
      title: 'Notificações',
      children: [
        _buildSwitchTile(
          title: 'Ativar Notificações',
          subtitle: 'Receba lembretes e atualizações',
          value: _notificationsEnabled,
          onChanged: (value) {
            setState(() {
              _notificationsEnabled = value;
            });
          },
        ),
        _buildSwitchTile(
          title: 'Lembretes Diários',
          subtitle: 'Lembrete para escrever no diário',
          value: _dailyReminders,
          onChanged: _notificationsEnabled ? (value) {
            setState(() {
              _dailyReminders = value;
            });
          } : null,
        ),
        _buildSwitchTile(
          title: 'Relatórios Semanais',
          subtitle: 'Resumo semanal das atividades',
          value: _weeklyReports,
          onChanged: _notificationsEnabled ? (value) {
            setState(() {
              _weeklyReports = value;
            });
          } : null,
        ),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return _buildSettingsCard(
      title: 'Aparência',
      children: [
        _buildSwitchTile(
          title: 'Modo Escuro',
          subtitle: 'Usar tema escuro no aplicativo',
          value: _darkMode,
          onChanged: (value) {
            setState(() {
              _darkMode = value;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Funcionalidade em desenvolvimento!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLanguageSection() {
    return _buildSettingsCard(
      title: 'Idioma',
      children: [
        ListTile(
          leading: Icon(Icons.language, color: Theme.of(context).primaryColor),
          title: const Text('Idioma do App'),
          subtitle: Text(_selectedLanguage),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showLanguageSelector,
        ),
      ],
    );
  }

  Widget _buildLoginSecuritySection() {
    return _buildSettingsCard(
      title: 'Login e Segurança',
      children: [
        SwitchListTile(
          title: const Text('Lembrar de mim'),
          subtitle: Text(_rememberMeEnabled 
              ? 'Login automático ativado'
              : 'Fazer login automático ao abrir o app'),
          value: _rememberMeEnabled,
          onChanged: (value) => _toggleRememberMe(value),
          activeColor: Theme.of(context).primaryColor,
          secondary: Icon(
            _rememberMeEnabled ? Icons.login : Icons.logout,
            color: _rememberMeEnabled ? Theme.of(context).primaryColor : Colors.grey,
          ),
        ),
        ListTile(
          leading: Icon(Icons.cleaning_services, color: Theme.of(context).primaryColor),
          title: const Text('Limpar dados de login'),
          subtitle: const Text('Remover credenciais salvas'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _clearLoginData,
        ),
        ListTile(
          leading: Icon(Icons.logout, color: Colors.orange),
          title: const Text('Sair da conta', style: TextStyle(color: Colors.orange)),
          subtitle: const Text('Fazer logout do aplicativo'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.orange),
          onTap: _signOut,
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    return _buildSettingsCard(
      title: 'Privacidade e Segurança',
      children: [
        ListTile(
          leading: Icon(Icons.lock_outline, color: Theme.of(context).primaryColor),
          title: const Text('Alterar Senha'),
          subtitle: const Text('Atualize sua senha de acesso'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showChangePassword,
        ),
        ListTile(
          leading: Icon(Icons.backup, color: Theme.of(context).primaryColor),
          title: const Text('Backup de Dados'),
          subtitle: const Text('Faça backup dos seus dados'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showBackupOptions,
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text('Excluir Conta', style: TextStyle(color: Colors.red)),
          subtitle: const Text('Remover permanentemente sua conta'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
          onTap: _showDeleteAccount,
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return _buildSettingsCard(
      title: 'Suporte',
      children: [
        ListTile(
          leading: Icon(Icons.help_outline, color: Theme.of(context).primaryColor),
          title: const Text('Central de Ajuda'),
          subtitle: const Text('Perguntas frequentes e tutoriais'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showHelpCenter,
        ),
        ListTile(
          leading: Icon(Icons.email_outlined, color: Theme.of(context).primaryColor),
          title: const Text('Entre em Contato'),
          subtitle: const Text('Envie feedback ou reporte problemas'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showContact,
        ),
        ListTile(
          leading: Icon(Icons.star_outline, color: Theme.of(context).primaryColor),
          title: const Text('Avaliar App'),
          subtitle: const Text('Deixe sua avaliação na loja'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showRateApp,
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSettingsCard(
      title: 'Sobre',
      children: [
        ListTile(
          leading: Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
          title: const Text('Versão do App'),
          subtitle: const Text('1.0.0'),
        ),
        ListTile(
          leading: Icon(Icons.privacy_tip_outlined, color: Theme.of(context).primaryColor),
          title: const Text('Política de Privacidade'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showPrivacyPolicy,
        ),
        ListTile(
          leading: Icon(Icons.article_outlined, color: Theme.of(context).primaryColor),
          title: const Text('Termos de Uso'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showTermsOfService,
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).primaryColor,
      secondary: Icon(
        value ? Icons.notifications_active : Icons.notifications_off,
        color: onChanged != null 
            ? (value ? Theme.of(context).primaryColor : Colors.grey)
            : Colors.grey[400],
      ),
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecionar Idioma',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('Português'),
              trailing: _selectedLanguage == 'Português' 
                  ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                  : null,
              onTap: () {
                setState(() {
                  _selectedLanguage = 'Português';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('English'),
              trailing: _selectedLanguage == 'English' 
                  ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                  : null,
              onTap: () {
                setState(() {
                  _selectedLanguage = 'English';
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Idioma em desenvolvimento!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar Senha'),
        content: const Text('Funcionalidade em desenvolvimento!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showBackupOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup de Dados'),
        content: const Text('Funcionalidade em desenvolvimento!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Conta'),
        content: const Text(
          'Tem certeza que deseja excluir permanentemente sua conta? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidade em desenvolvimento!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showHelpCenter() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Central de Ajuda em desenvolvimento!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showContact() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contato em desenvolvimento!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showRateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de avaliação em desenvolvimento!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Política de Privacidade em desenvolvimento!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showTermsOfService() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Termos de Uso em desenvolvimento!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (value) {
      // Ativando "lembrar de mim"
      await prefs.setBool('remember_me', true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login automático ativado! Suas credenciais serão salvas no próximo login.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Desativando "lembrar de mim" - limpar todas as credenciais
      await prefs.setBool('remember_me', false);
      await prefs.remove('remembered_email');
      await prefs.remove('remembered_password');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login automático desativado e credenciais removidas.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    
    setState(() {
      _rememberMeEnabled = value;
    });
  }

  Future<void> _clearLoginData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar dados de login'),
        content: const Text(
          'Isto irá remover todas as credenciais salvas e desativar o login automático. '
          'Você precisará fazer login novamente na próxima vez que abrir o app.\n\n'
          'Deseja continuar?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('remembered_email');
              await prefs.remove('remembered_password');
              await prefs.setBool('remember_me', false);
              
              setState(() {
                _rememberMeEnabled = false;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dados de login removidos com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Limpar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text(
          'Deseja sair da sua conta? Você precisará fazer login novamente '
          'para acessar o aplicativo.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                // Fazer logout do Supabase
                await UserService.signOut();
                
                // Limpar preferências se solicitado
                final prefs = await SharedPreferences.getInstance();
                if (!_rememberMeEnabled) {
                  await prefs.remove('remembered_email');
                  await prefs.remove('remembered_password');
                }
                
                // Navegar para tela de login
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao sair: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Sair', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}