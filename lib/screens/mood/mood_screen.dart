import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myyearmystory/widgets/shared/main_scaffold.dart';

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

  /// COR PARA CADA HUMOR
  final Map<String, Color> moodColors = {
  "happy": const Color(0xFFE04CB7),
  "calm": const Color(0xFFC79FE2),
  "loving": const Color(0xFFDD97B7),
  "thoughtful": const Color(0xFF7654A3),
  "anxious": const Color(0xFF686DAD),
  "tired": const Color(0xFFA1A8F0),
  "sad": const Color(0xFF627FDD),
  "irritated": const Color(0xFFE2377D),
  "embarrassed": const Color(0xFFB71691),
  "comforted": const Color(0xFFDBAF35),
  "bored": const Color(0xFFCF78F7),
  "excited": const Color(0xFFE04CB7),
  "overwhelmed": const Color(0xFF7654A3),
  "proud": const Color(0xFFDD97B7),
  "surprised": const Color(0xFFC79FE2),
  "confused": const Color(0xFFB539BC),


  };

  /// LISTA DE HUMORES
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


  /// MENSAGENS MOTIVACIONAIS
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


  
  // ⇢ SALVAR HUMOR
  Future<void> saveMood(String moodKey) async {
    if (isSaving) return;
    setState(() => isSaving = true);

    final user = supabase.auth.currentUser;
    if (user == null) {
      _showSnack('user.not_authenticated'.tr(), Colors.redAccent);
      setState(() => isSaving = false);
      return;
    }

    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));

    final response = await supabase
        .from('mood_entries')
        .select()
        .eq('user_id', user.id)
        .gte('created_at', oneHourAgo.toIso8601String())
        .lt('created_at', now.toIso8601String());

    if (response.length >= 3) {
      _showSnack('mood.limit_message'.tr(), const Color(0xFFE91E63));
      setState(() => isSaving = false);
      return;
    }

    await supabase.from('mood_entries').insert({
      'user_id': user.id,
      'mood': moodKey,
      'entry_date': now.toIso8601String(),
      'month': now.month,
      'year': now.year,
      'created_at': now.toIso8601String(),
    });

    _showSnack(
      motivationalMessages[moodKey] ?? 'mood.saved'.tr(),
      const Color(0xFFE91E63),
    );

    setState(() => isSaving = false);
    fetchMonthlySummary();
  }

  List<Map<String, dynamic>> topMoods = [];

  // ⇢ CARREGAR RESUMO DO MÊS
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
      final moodItem = moods.firstWhere(
        (m) => m['key'] == e.key,
        orElse: () => {'emoji': '❓'},
      );

      return {
        'key': e.key,
        'emoji': moodItem['emoji'],
        'percent': (e.value / total) * 100,
      };
    }).toList();

    list.sort((a, b) => b['percent'].compareTo(a['percent']));

    setState(() => topMoods = list.take(4).toList());
  }

  void _showSnack(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 6),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    ));
  }

  @override
  void initState() {
    super.initState();
    fetchMonthlySummary();
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 4,
      title: 'My Year, My Story',
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: 25),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildMoodGrid(),
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

  // ----------------------------------------------------------
  // HEADER
  // ----------------------------------------------------------
  Widget _buildHeader() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFEEDAF0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'mood.title_today'.tr(),
          style: GoogleFonts.courierPrime(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // GRID DE HUMORES
  // ----------------------------------------------------------
  Widget _buildMoodGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 14) / 2;
        final itemHeight = 60;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: moods.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: itemWidth / itemHeight,
          ),
          itemBuilder: (context, index) {
            final mood = moods[index];
            final key = mood['key'];
            final emoji = mood['emoji'];
            final bgColor = moodColors[key]!;

            return GestureDetector(
              onTap: () => saveMood(key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: bgColor.withOpacity(0.23),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: bgColor.withOpacity(0.25),
                      offset: const Offset(0, 3),
                      blurRadius: 6,
                    )
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'mood.$key'.tr(),
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ----------------------------------------------------------
  // SUMMARY (VIDRO FROSTED)
  // ----------------------------------------------------------
  Widget _buildMoodSummaryGlass() {
    final top = topMoods.first;
    final others = topMoods.skip(1).toList();

    return Container(
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.20),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEDAF0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'mood.month_summary'.tr(),
                  style: GoogleFonts.courierPrime(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'mood.summary_description'.tr(),
                style: GoogleFonts.montserrat(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 20),

              Container(
  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.25),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: Colors.white.withOpacity(0.4),
      width: 1,
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      _percentColumn(top['emoji'], top['percent']),
      if (others.isNotEmpty)
        _percentColumn(others[0]['emoji'], others[0]['percent']),
      if (others.length > 1)
        _percentColumn(others[1]['emoji'], others[1]['percent']),
      if (others.length > 2)
        _percentColumn(others[2]['emoji'], others[2]['percent']),
    ],
  ),
),

            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // COLUNA DE EMOJI + %
  // ----------------------------------------------------------
  Widget _percentColumn(String emoji, double percent) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 28),
        ),
        const SizedBox(height: 4),
        Text(
          '${percent.toStringAsFixed(0)}%',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
