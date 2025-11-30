import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Future<void> _launchSupport() async {
    final Uri url = Uri.parse('mailto:contato@sonhodepapel.com?subject=Ajuda%20-%20MyYearMyStory');
    if (!await launchUrl(url)) {
      throw Exception('Não foi possível abrir o e-mail');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajuda e Suporte'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[50],
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _faqItem(
            icon: Icons.edit_note,
            title: 'Como preencher as páginas do mês?',
            description: 'Acesse o menu principal e escolha o mês atual. Cada seção é interativa e salva automaticamente.',
          ),
          _faqItem(
            icon: Icons.person_outline,
            title: 'Como editar meu perfil?',
            description: 'No menu lateral, vá em “Meu Perfil” e toque em “Editar”. Você pode alterar nome e foto.',
          ),
          _faqItem(
            icon: Icons.logout,
            title: 'Como sair do app?',
            description: 'Abra o menu lateral e toque em “Sair”. Seu progresso ficará salvo na nuvem.',
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: _launchSupport,
              icon: const Icon(Icons.email_outlined),
              label: const Text('Falar com o suporte'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _faqItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.purple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[700], height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
