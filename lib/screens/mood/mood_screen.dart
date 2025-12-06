import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:myyearmystory/widgets/shared/main_scaffold.dart';
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
  int? selectedDay;
  List<Map<String, dynamic>> topMoods = [];

  String trMood(String key) => "mood.$key".tr();

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

  // -----------------------------------------------------------
  // 📊 BUSCAR RESUMO DO MÊS (Top 4 humores + porcentagens)
  // -----------------------------------------------------------
  Future<void> fetchMonthlySummary() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final result = await supabase
        .from("mood_entries")
        .select()
        .eq("user_id", user.id)
        .eq("month", widget.month)
        .eq("year", widget.year);

    if (result.isEmpty) {
      setState(() => topMoods = []);
      return;
    }

    final counts = <String, int>{};

    for (var entry in result) {
      final mood = entry['mood'];
      counts[mood] = (counts[mood] ?? 0) + 1;
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
        'percent': ((e.value / total) * 100),
      };
    }).toList();

    list.sort((a, b) => b['percent'].compareTo(a['percent']));

    setState(() => topMoods = list.take(4).toList());
  }

  @override
  void initState() {
    super.initState();
    fetchMonthlySummary();
  }

  // -----------------------------------------------------------
  // 💾 SALVAR HUMOR (responsabilidade do MoodScreen)
  // -----------------------------------------------------------
  Future<void> _saveMood(String moodKey) async {
    if (selectedDay == null) return;

    if (isSaving) return;
    setState(() => isSaving = true);

    final user = supabase.auth.currentUser!;
    final day = selectedDay!;
    final now = DateTime(widget.year, widget.month, day);

    // apaga a entrada anterior do dia
    await supabase
        .from('mood_entries')
        .delete()
        .eq('user_id', user.id)
        .eq('day', day)
        .eq('month', widget.month)
        .eq('year', widget.year);

    // insere nova entrada
    await supabase.from('mood_entries').insert({
      'user_id': user.id,
      'mood': moodKey,
      'entry_date': now.toIso8601String(),
      'day': day,
      'month': widget.month,
      'year': widget.year,
      'created_at': DateTime.now().toIso8601String(),
    });

    await fetchMonthlySummary();
    MoodCalendar.refresh();

    // mensagem motivacional
    final msg = "motivation.$moodKey".tr();
    final color = moodColors[moodKey]!;

    _showSnack(msg, color);

    setState(() => isSaving = false);
  }

  // -----------------------------------------------------------
  // 🔔 SNACK
  // -----------------------------------------------------------
  void _showSnack(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // -----------------------------------------------------------
  // 🌈 BOTÕES
  // -----------------------------------------------------------
  Widget _buildMoodGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: moods.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 26,
        childAspectRatio: 2.3,
      ),
      itemBuilder: (context, index) {
        final mood = moods[index];
        final emoji = mood['emoji'];
        final moodKey = mood['key'];
        final color = moodColors[moodKey]!;

        return GestureDetector(
          onTap: () async => _saveMood(moodKey),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.only(top: 22),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.30),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(
                  trMood(moodKey),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
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
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -----------------------------------------------------------
  // UI
  // -----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser!;

    final Map<String, String> moodEmojiMap = {
      for (var m in moods) m['key']: m['emoji'],
    };

    return MainScaffold(
      currentIndex: 3,
      title: "My Year, My Story",
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 20),

                // CALENDÁRIO
                MoodCalendar(
                  key: MoodCalendar.globalKey,
                  userId: user.id,
                  month: widget.month,
                  year: widget.year,
                  moodEmojis: moodEmojiMap,
                  moodColors: moodColors,
                  onDaySelected: (day) {
                    setState(() => selectedDay = day);
                  },
                ),

                const SizedBox(height: 30),

                _buildMoodGrid(),

                const SizedBox(height: 30),

                if (topMoods.isNotEmpty) _buildHighlightCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE6BDEA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "mood.how_are_you_feeling".tr().toUpperCase(),
        textAlign: TextAlign.center,
        style: GoogleFonts.courierPrime(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildHighlightCard() {
    final top = topMoods.first;
    final others = topMoods.skip(1).toList();
    final monthName = "calendar_month.${widget.month}".tr();

    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFF2D8F4),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            "mood.other_marked".tr(),

            style: GoogleFonts.courierPrime(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "$monthName ${widget.year}",
            style: GoogleFonts.courierPrime(
              fontSize: 15,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 20),
          Text(top['emoji'], style: const TextStyle(fontSize: 45)),
          const SizedBox(height: 10),
          Text(
            "${top['percent'].toStringAsFixed(0)}%",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            trMood(top['key']),
            style: GoogleFonts.courierPrime(
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Divider(color: Colors.black38),
          const SizedBox(height: 16),
          Text(
            "mood.other_top_moods".tr(),
            style: GoogleFonts.courierPrime(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: others.map((item) {
              return Column(
                children: [
                  Text(item['emoji'], style: const TextStyle(fontSize: 28)),
                  Text("${item['percent'].toStringAsFixed(0)}%"),
                  Text(trMood(item['key']),
                      style: GoogleFonts.courierPrime(fontSize: 14)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
