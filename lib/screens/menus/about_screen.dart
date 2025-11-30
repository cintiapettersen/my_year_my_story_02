import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appName = 'My Year, My Story';
  String _version = '—';
  String _build = '—';
  String _package = '—';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _appName = info.appName.isNotEmpty ? info.appName : _appName;
        _version = info.version;
        _build = info.buildNumber;
        _package = info.packageName;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false); // Fallback silencioso
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre o App'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header bonitinho
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor,
                    theme.primaryColor.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_stories, size: 44, color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    _appName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _loading ? 'Carregando…' : 'Versão $_version (build $_build)',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Cartão: informações técnicas
            _InfoCard(
              title: 'Informações do Pacote',
              children: [
                _InfoRow(label: 'Nome do pacote', value: _package),
                _InfoRow(label: 'Versão', value: _version),
                _InfoRow(label: 'Build', value: _build),
              ],
            ),

            const SizedBox(height: 16),

            // Cartão: proposta
            _InfoCard(
              title: 'Propósito do App',
              children: const [
                Text(
                  'Registrar seu ano de forma leve e divertida: metas, gratidão, '
                      'humor, entrevistas, listas e um álbum mensal – tudo em um só lugar.',
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Cartão: créditos
            _InfoCard(
              title: 'Créditos',
              children: const [
                _InfoRow(label: 'Design & Produto', value: 'Você ✨'),
                _InfoRow(label: 'Desenvolvimento', value: 'Projeto Flutter + Supabase'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                )),
          ),
          Text(value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              )),
        ],
      ),
    );
  }
}
