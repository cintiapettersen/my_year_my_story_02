import 'package:flutter/material.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';

class AchievementsSection extends StatefulWidget {
  const AchievementsSection({super.key});

  @override
  State<AchievementsSection> createState() => _AchievementsSectionState();
}

class _AchievementsSectionState extends State<AchievementsSection> {
  List<Map<String, dynamic>> _achievements = [];

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  void _loadAchievements() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      // Simular dados baseados no progresso do usuário
      final createdAt = DateTime.tryParse(user.createdAt) ?? DateTime.now();
      final accountAge = DateTime.now().difference(createdAt).inDays;
      final hasProfile = user.userMetadata?['full_name']?.isNotEmpty == true;
      final hasBirthDate = user.userMetadata?['birth_date'] != null;

      final achievements = <Map<String, dynamic>>[
        {
          'title': '🎉 Primeira Entrada',
          'description': 'Bem-vinda ao My Year!',
          'achieved': true,
          'progress': 1.0,
        },
        {
          'title': '👤 Perfil Completo',
          'description': 'Preencheu informações pessoais',
          'achieved': hasProfile && hasBirthDate,
          'progress': hasProfile && hasBirthDate ? 1.0 : (hasProfile ? 0.5 : 0.0),
        },
        {
          'title': '🗓️ Uma Semana Ativa',
          'description': '7 dias usando o app',
          'achieved': accountAge >= 7,
          'progress': (accountAge / 7).clamp(0.0, 1.0),
        },
        {
          'title': '📖 Escritora Iniciante',
          'description': '5 entradas no diário',
          'achieved': accountAge >= 5, // Simular baseado na idade da conta
          'progress': ((accountAge * 0.2) / 5).clamp(0.0, 1.0),
        },
        {
          'title': '📸 Colecionadora',
          'description': '10 fotos no álbum',
          'achieved': accountAge >= 3, // Simular
          'progress': ((accountAge * 0.5) / 10).clamp(0.0, 1.0),
        },
        {
          'title': '🌟 Mês Completo',
          'description': '30 dias consecutivos',
          'achieved': accountAge >= 30,
          'progress': (accountAge / 30).clamp(0.0, 1.0),
        },
      ];

      setState(() {
        _achievements = achievements;
      });
    } catch (e) {
      // Manter vazio se houver erro
    }
  }

  @override
  Widget build(BuildContext context) {
    final achievedCount = _achievements.where((a) => a['achieved'] == true).length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Conquistas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$achievedCount/${_achievements.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
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
            children: _achievements.map((achievement) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildAchievementItem(achievement),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementItem(Map<String, dynamic> achievement) {
    final bool achieved = achievement['achieved'];
    final double progress = achievement['progress'];
    
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: achieved 
                ? Colors.amber.withValues(alpha: 0.1)
                : Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: achieved
                ? const Icon(
                    Icons.check_circle,
                    color: Colors.amber,
                    size: 24,
                  )
                : Stack(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 2,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      if (progress > 0)
                        Positioned.fill(
                          child: Center(
                            child: Text(
                              '${(progress * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement['title'],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: achieved ? Colors.black87 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                achievement['description'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        if (achieved)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '✨ Completa',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.amber[700],
              ),
            ),
          ),
      ],
    );
  }
}