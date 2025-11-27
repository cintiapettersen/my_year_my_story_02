import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myyearmystory/widgets/shared/main_scaffold.dart';

// IMPORTA O CALENDÁRIO
import 'package:myyearmystory/screens/mood/mood_calendar.dart';

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

  // Tradução automática
  String safeTr(String key) => 'mood.$key'.tr();

  // Cores dos humores
  final Map<String, Color> moodColors = {
    "happy": Color(0xFFE04CB7),
    "calm": Color(0xFFC79FE2),
    "loving": Color(0xFFDD97B7),
    "thoughtful": Color(0xFF7654A3),
    "anxious": Color(0xFF686DAD),
    "tired": Color(0xFFA1A8F0),
    "sad": Color(0xFF627FDD),
    "irritated": Color(0xFFE2377D),
    "embarrassed": Color(0xFFB71691),
    "comforted": Color(0xFFDBAF35),
    "bored": Color(0xFFCF78F7),
    "excited": Color(0xFFE04CB7),
    "overwhelmed": Color(0xFF7654A3),
    "proud": Color(0xFFDD97B7),
    "surprised": Color(0xFFC79FE2),
    "confused": Color(0xFFB539BC),
  };

  // Lista de humores
  final List<Map<String, dynamic>> moods = [
    {'emoji': '😊', 'key': 'happy'},
    {'emoji': '😌', 'key': 'calm'},
    {'emoji': '😍', 'key': 'loving'},
    {'emoji': '🤔', 'key': 'thoughtful'},
    {'emoji': '😬', 'key': 'anxious'},
    {'emoji': '😴', 'key': 'tired'},
    {'emoji': '😭', 'key': 'sad'},
    {'emoji': '😡', 'key': 'irritated'},
    {'emoji': '😳', 'key': 'embarrassed'},
    {'emoji': '🤗', 'key': 'comforted'},
    {'emoji': '😑', 'key': 'bored'},
    {'emoji': '🤩', 'key': 'excited'},
    {'emoji': '😵', 'key': 'overwhelmed'},
    {'emoji': '😇', 'key': 'proud'},
    {'emoji': '🤯', 'key': 'surprised'},
    {'emoji': '😕', 'key': 'confused'},
  ];

  // Motivacionais
  final motivationalMessages = {
    'happy': '🌞 Continue espalhando essa luz!',
    'calm': '🌿 Aproveite essa paz.',
    'loving': '💖 Seu coração tá quentinho hoje.',
    'thoughtful': '🌙 Pensar é essencial.',
    'anxious': '🌸 Respira… vai ficar tudo bem.',
    'tired': '💙 Seu corpo pede descanso.',
    'sad': '💜 Você não está sozinha.',
    'irritated': '🔥 Respira antes de reagir.',
    'embarrassed': '😳 Todo mundo passa por isso.',
    'comforted': '🤗 Que delícia esse acolhimento.',
    'bored': '😑 Talvez tentar algo novo?',
    'excited': '🤩 AMO ver você animada!',
    'overwhelmed': '😵 Uma coisa por vez.',
    'proud': '😇 E com razão! Continue assim.',
    'surprised': '🤯 A vida surpreende mesmo!',
    'confused': '😕 Vai clareando aos poucos.',
  };

  // Salvar humor
  Future<void> saveMood(String moodKey) async {
    if (isSaving) return;

    setState(() => isSaving = true);

    final user = supabase.auth.currentUser;
    if (user == null) {
      _showSnack('user.not_authenticated'.tr(), Colors.redAccent);
      isSaving = false;
      return;
    }

    final now = DateTime.now();

    await supabase.from('mood_entries').insert({
      'user_id': user.id,
      'mood': moodKey,
      'entry_date': now.toIso8601String(),
      'month': now.month,
      'year': now.year,
      'created_at': now.toIso8601String(),
    });

    _showSnack(motivationalMessages[moodKey] ?? 'mood.saved'.tr(),
        Color(0xFFE91E63));

    isSaving = false;
    fetchMonthlySummary();
    setState(() {}); // Atualiza o calendário
  }

  List<Map<String, dynamic>> topMoods = [];

  // Carregar resumo
  Future<void> fetchMonthlySummary() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('mood_entries')
        .select()
        .eq('user_id', user.id)
        .eq('month', DateTime.now().month)
        .eq('year', DateTime.now().year);

    if (response.isEmpty) {
      setState(() => topMoods = []);
      return;
    }

    final counts = <String, int>{};

    for (var entry in response) {
      final moodKey = entry['mood'];
      counts[moodKey] = (counts[moodKey] ?? 0) + 1;
    }

    final total = counts.values.fold(0, (a, b) => a + b);

    final list = counts.entries.map((e) {
      final moodData = moods.firstWhere(
        (m) => m['key'] == e.key,
        orElse: () => {'emoji': '❓'},
      );

      return {
        'key': e.key,
        'emoji': moodData['emoji'],
        'percent': (e.value / total) * 100,
      };
    }).toList();

    list.sort((a, b) => b['percent'].compareTo(a['percent']));

    setState(() => topMoods = list.take(4).toList());
  }

  void _showSnack(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: color,
        duration: Duration(seconds: 4),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchMonthlySummary();
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 3,
      title: 'My Year, My Story',
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 22, vertical: 22),
          child: Column(
            children: [
              _buildHeader(),
              SizedBox(height: 25),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 36),

                      // 🌸 Texto explicativo acima do calendário
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: Text(
                          'mood.calendar_description'.tr(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // 🌈 Calendário
                      MoodCalendar(
                        userId: supabase.auth.currentUser!.id,
                        month: widget.month,
                        year: widget.year,
                        moodEmojis: {
                          for (var m in moods) m['key']: m['emoji'],
                        },
                        moodColors: moodColors,
                      ),

                      const SizedBox(height: 26),

                      // —— separador ——
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Divider(thickness: 1, color: Colors.black26),
                      ),

                      const SizedBox(height: 12),

                      // Texto antes dos botões
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'mood.calendar_register_hint'.tr(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Divider(thickness: 1, color: Colors.black26),
                      ),

                      const SizedBox(height: 32),

                      // 🌸 GRID DOS BOTÕES
                      _buildMoodGrid(),

                      const SizedBox(height: 30),

                      if (topMoods.isNotEmpty) _buildMoodSummaryGlass(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // HEADER
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 230, 187, 234),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'mood.how_are_you_feeling'.tr(),
        textAlign: TextAlign.center,
        style: GoogleFonts.courierPrime(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // GRID dos botões
  Widget _buildMoodGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: moods.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 26,
        childAspectRatio: 2.3,
      ),
      itemBuilder: (context, index) {
        final mood = moods[index];
        final emoji = mood['emoji'];
        final key = mood['key'];
        final color = moodColors[key]!;

        return _moodButton(
          emoji,
          safeTr(key),
          color,
          () => saveMood(key),
        );
      },
    );
  }

  // BOTÃO com emoji
  Widget _moodButton(
    String emoji,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.only(top: 22),
            decoration: BoxDecoration(
              color: color.withOpacity(0.30),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                )
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.3,
                color: Colors.black87,
              ),
            ),
          ),
        ),

        Positioned(
          top: -18,
          left: 0,
          right: 0,
          child: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withOpacity(0.6),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: color,
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // CARD RESUMO
  Widget _buildMoodSummaryGlass() {
    final top = topMoods.first;
    final others = topMoods.skip(1).toList();

    final now = DateTime.now();
    final monthName = DateFormat('MMMM', 'pt_BR').format(now);
    final monthFormatted =
        "${monthName[0].toUpperCase()}${monthName.substring(1)}";
    final year = now.year;

    return Container(
      margin: const EdgeInsets.only(top: 40),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
            children: [
              const SizedBox(height: 1),
              Text(
                'HUMOR DESTAQUE',
                textAlign: TextAlign.center,
                style: GoogleFonts.courierPrime(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),

          Container(
            margin: const EdgeInsets.only(top: 30),
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 38),
            decoration: BoxDecoration(
              color: const Color(0xFFF2D8F4),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFFE9C4E8),
                width: 4,
              ),
            ),
            child: Column(
              children: [
                Text(
                  "$monthFormatted $year",
                  style: GoogleFonts.courierPrime(
                    fontSize: 15,
                    letterSpacing: 1.4,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEACCF0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    top['emoji'],
                    style: const TextStyle(fontSize: 46),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  "${top['percent'].toStringAsFixed(0)}%",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  safeTr(top['key']),
                  style: GoogleFonts.courierPrime(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ),

                const SizedBox(height: 22),

                Divider(color: Colors.black38, height: 1),

                const SizedBox(height: 20),

                Text(
                  "OUTROS HUMORES MAIS MARCADOS",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.courierPrime(
                    fontSize: 13,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,
                  children: others.map((item) {
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD2B4EC),
                            borderRadius: BorderRadius.circular(60),
                          ),
                          child: Text(
                            item['emoji'],
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${item['percent'].toStringAsFixed(0)}%",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          safeTr(item['key']),
                          style: GoogleFonts.courierPrime(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// EXTENSÃO AJUDA A CAPITALIZAR
extension CapExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
