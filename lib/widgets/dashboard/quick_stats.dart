import 'package:flutter/material.dart';
import 'package:my_year_my_story/supabase/supabase_config.dart';

class QuickStats extends StatefulWidget {
  const QuickStats({super.key});

  @override
  State<QuickStats> createState() => _QuickStatsState();
}

class _QuickStatsState extends State<QuickStats> {
  int _activeDays = 0;
  int _diaryEntries = 0;
  int _photos = 0;
  String _moodAverage = '😊';
  
  @override
  void initState() {
    super.initState();
    _loadStats();
  }
  
  void _loadStats() async {
    try {
      // TODO: Implementar consultas reais ao Supabase
      // Por enquanto, usando dados simulados baseados no usuário
      final user = SupabaseConfig.getCurrentUser();
      if (user != null) {
        // Simular dados baseados no tempo de conta criada
        final createdAt = DateTime.tryParse(user.createdAt) ?? DateTime.now();
        final accountAge = DateTime.now().difference(createdAt).inDays;
        
        setState(() {
          _activeDays = (accountAge * 0.3).round().clamp(1, 365);
          _diaryEntries = (accountAge * 0.2).round().clamp(0, 100);
          _photos = (accountAge * 0.5).round().clamp(0, 200);
          _moodAverage = _calculateMoodEmoji(accountAge);
        });
      }
    } catch (e) {
      // Manter valores padrão se houver erro
    }
  }
  
  String _calculateMoodEmoji(int days) {
    final moods = ['😊', '😄', '😌', '🙂', '😍'];
    return moods[days % moods.length];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumo do Mês',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.calendar_today,
                title: 'Dias Ativos',
                value: '$_activeDays',
                subtitle: 'Desde o início',
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.edit,
                title: 'Entradas',
                value: '$_diaryEntries',
                subtitle: 'Diário',
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.photo_camera,
                title: 'Fotos',
                value: '$_photos',
                subtitle: 'Álbum',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.emoji_emotions,
                title: 'Humor Médio',
                value: '$_moodAverage',
                subtitle: 'Geral',
                color: Colors.pink,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}