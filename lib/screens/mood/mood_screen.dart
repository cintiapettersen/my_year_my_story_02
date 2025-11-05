import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_year_my_story/widgets/shared/main_scaffold.dart';

class MoodScreen extends StatefulWidget {
  final int month;
  final int year;

  const MoodScreen({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  final supabase = Supabase.instance.client;
  bool isSaving = false;

  final List<Map<String, dynamic>> moods = [
    {'emoji': '😊', 'label': 'Feliz', 'color': const Color(0xFF679bd3)},
    {'emoji': '😌', 'label': 'Calma', 'color': const Color(0xFFddbfef)},
    {'emoji': '😍', 'label': 'Amando', 'color': const Color(0xFFe2377d)},
    {'emoji': '🤔', 'label': 'Pensativa', 'color': const Color(0xFFea7acd)},
    {'emoji': '😬', 'label': 'Ansiosa', 'color': const Color(0xFFcf8ee8)},
    {'emoji': '😴', 'label': 'Cansada', 'color': const Color(0xFFd1c269)},
    {'emoji': '😭', 'label': 'Triste', 'color': const Color(0xFF679bd3)},
  ];

  Future<void> saveMood(String mood) async {
    if (isSaving) return;
    setState(() => isSaving = true);

    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Usuário não autenticado 😕'),
        backgroundColor: Colors.redAccent,
      ));
      setState(() => isSaving = false);
      return;
    }

    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));

    // Verifica quantos registros existem na última hora
    final response = await supabase
        .from('mood_entries')
        .select()
        .eq('user_id', user.id)
        .gte('created_at', oneHourAgo.toIso8601String())
        .lt('created_at', now.toIso8601String());

    if (response.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            '💖 Seu humor já foi registrado! Respira e volta daqui uma horinha...'),
        backgroundColor: Color(0xFFE91E63),
      ));
      setState(() => isSaving = false);
      return;
    }

    await supabase.from('mood_entries').insert({
      'user_id': user.id,
      'mood': mood,
      'date': now.toIso8601String(),
      'month': now.month,
      'year': now.year,
      'created_at': now.toIso8601String(),
    });

    // Mensagens personalizadas por humor 💕
    final motivationalMessages = {
      'Feliz': '🌞 Que alegria te ver assim! Espalhe essa energia pelo dia 💛',
      'Calma': '🌿 Um respiro de paz faz toda diferença. Continue leve 💚',
      'Amando': '💖 O amor é a melhor parte de nós — e hoje ele te escolheu 💕',
      'Pensativa':
      '🤔 Pensar demais às vezes pesa… mas é também sinal de sabedoria 🌙',
      'Ansiosa':
      '💫 Respira fundo, tá tudo bem. Um passo de cada vez é suficiente 🌸',
      'Cansada':
      '😴 Seu corpo e mente pedem pausa. Descansar também é produtividade 💙',
      'Triste':
      '💧 Tudo bem não estar bem. Chorar é limpar o coração — dias melhores vêm 💜',
    };

    final message = motivationalMessages[mood] ??
        'Seu humor "$mood" foi registrado 💖 Continue se cuidando!';

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 6),
      backgroundColor: const Color(0xFFE91E63),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
      ),
    ));

    setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final int month = widget.month;
    final int year = widget.year;

    return MainScaffold(
      currentIndex: 4,
      title: 'My Year, my Story ',
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Como você está se sentindo hoje?',
                style: GoogleFonts.outfit(
                  fontSize: 19
                  ,
                  color: Colors.pink.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    ...moods.map((mood) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => saveMood(mood['label']),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            decoration: BoxDecoration(
                              color: mood['color'],
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(1, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Text(
                                  mood['emoji'],
                                  style: const TextStyle(fontSize: 26),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  mood['label'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 17,
                                    color: Color(0xFFFFFFFF),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),

                    // 🌈 Rodapé fofo fixo
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        '🌈 Acompanhe como você se sentiu este mês lá no Dashboard!\n'
                            'Cada registro ajuda a entender seus dias com mais carinho 💖',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Color(0xFF2b2d30),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
