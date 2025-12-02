import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:myyearmystory/widgets/shared/main_scaffold.dart';
import 'package:myyearmystory/screens/mood/mood_calendar.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';

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
  bool isPremium = false;
  int moodsToday = 0;

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

  List<Map<String, dynamic>> topMoods = [];

  @override
  void initState() {
    super.initState();
    _checkPremium();
    fetchMonthlySummary();
    _loadTodayCount();
  }

  Future<void> _checkPremium() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final res = await supabase
        .from("profiles")
        .select("is_premium")
        .eq("id", user.id)
        .maybeSingle();

    isPremium = res?["is_premium"] == true;
    setState(() {});
  }

  Future<void> _loadTodayCount() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final result = await supabase
        .from("mood_entries")
        .select()
        .eq("user_id", user.id)
        .eq("year", today.year)
        .eq("month", today.month)
        .eq("day", today.day);

    moodsToday = result.length;
    setState(() {});
  }

  Future<void> saveMood(String moodKey) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      showPremiumPopup(context);
      return;
    }

    if (!isPremium && moodsToday >= 1) {
      showPremiumPopup(context);
      return;
    }

    setState(() => isSaving = true);

    final now = DateTime.now();

    await supabase.from('mood_entries').insert({
      'user_id': user.id,
      'mood': moodKey,
      'entry_date': now.toIso8601String(),
      'day': now.day,
      'month': now.month,
      'year': now.year,
      'created_at': now.toIso8601String(),
    });

    moodsToday++;
    _showSnack(motivationalMessages[moodKey] ?? 'Mood salvo!');

    setState(() => isSaving = false);

    fetchMonthlySummary();
  }

  // SNACK FOFO
  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFE91E63),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ANALISE MENSAL
  Future<void> fetchMonthlySummary() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final res = await supabase
        .from("mood_entries")
        .select()
        .eq("user_id", user.id)
        .eq("month", widget.month)
        .eq("year", widget.year);

    if (res.isEmpty) {
      setState(() => topMoods = []);
      return;
    }

    final counts = <String, int>{};

    for (var row in res) {
      final mood = row["mood"];
      counts[mood] = (counts[mood] ?? 0) + 1;
    }

    final total = counts.values.fold(0, (a, b) => a + b);

    final list = counts.entries.map((e) {
      final moodData = moods.firstWhere(
        (m) => m['key'] == e.key,
        orElse: () => {'emoji': '❓'},
      );

      return {
        "key": e.key,
        "emoji": moodData["emoji"],
        "percent": (e.value / total) * 100,
      };
    }).toList();

    list.sort((a, b) => b["percent"].compareTo(a["percent"]));

    setState(() => topMoods = list.take(4).toList());
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 3,
      title: "My Year, My Story",
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 30),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildDescription(),
                      const SizedBox(height: 20),

                      // CALENDÁRIO
                      MoodCalendar(
                        userId: supabase.auth.currentUser?.id ?? "",
                        month: widget.month,
                        year: widget.year,
                        moodEmojis: {
                          for (var m in moods) m['key']: m['emoji'],
                        },
                        moodColors: moodColors,
                      ),

                      const SizedBox(height: 40),
                      _buildMoodGrid(),

                      const SizedBox(height: 40),
                      if (topMoods.isNotEmpty) _buildSummaryCard(),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE9C4E8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'mood.how_are_you_feeling'.tr(),
        textAlign: TextAlign.center,
        style: GoogleFonts.robotoMono(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        'mood.calendar_description'.tr(),
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  // GRID DE HUMORES
  Widget _buildMoodGrid() {
    final width = MediaQuery.of(context).size.width;
    final itemWidth = (width - 40) / 2;

    return Wrap(
      spacing: 16,
      runSpacing: 30,
      children: moods.map((mood) {
        return SizedBox(
          width: itemWidth,
          child: _moodButton(
            mood['emoji'],
            'mood.${mood['key']}'.tr(),
            moodColors[mood['key']]!,
            () => saveMood(mood['key']),
          ),
        );
      }).toList(),
    );
  }

  Widget _moodButton(
      String emoji, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: isSaving ? null : onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.only(top: 26, bottom: 18),
            decoration: BoxDecoration(
              color: color.withOpacity(0.28),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Positioned(
            top: -18,
            left: 0,
            right: 0,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white.withOpacity(0.7),
              child: CircleAvatar(
                radius: 19,
                backgroundColor: color,
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // CARD DE RESUMO
  Widget _buildSummaryCard() {
    final top = topMoods.first;
    final others = topMoods.skip(1).toList();

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF2D8F4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9C4E8), width: 3),
      ),
      child: Column(
        children: [
          Text(
            "HUMOR DESTAQUE",
            style: GoogleFonts.courierPrime(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            top["emoji"],
            style: const TextStyle(fontSize: 48),
          ),

          const SizedBox(height: 10),
          Text(
            "${top['percent'].toStringAsFixed(0)}%",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),
          Text(
            'mood.${top['key']}'.tr(),
            style: GoogleFonts.courierPrime(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),

          const SizedBox(height: 20),
          Divider(),

          const SizedBox(height: 14),
          Text(
            "OUTROS HUMORES",
            style: GoogleFonts.courierPrime(
              fontSize: 13,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: others.map((item) {
              return Column(
                children: [
                  Text(item['emoji'], style: const TextStyle(fontSize: 32)),
                  Text(
                    "${item['percent'].toStringAsFixed(0)}%",
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  Text(
                    'mood.${item['key']}'.tr(),
                    style: GoogleFonts.courierPrime(fontSize: 14),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
