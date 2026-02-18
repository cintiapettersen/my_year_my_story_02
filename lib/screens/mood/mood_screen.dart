import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

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

  int tempMonth = 1;
  int tempYear = DateTime.now().year;

  bool isSaving = false;
  int? selectedDay;

  List<Map<String, dynamic>> topMoods = [];

  // 👤 GUEST CONTROL
  int guestMoodCount = 0;
  static const int guestMoodLimit = 3;

  String trMood(String key) => "mood.$key".tr();

  final Map<String, Color> moodColors = {
    "happy": Color(0xFFE04CB7),
    "calm": Color(0xFFC79FE2),
    "loving": Color(0xFFDD97B7),
    "thoughtful": Color(0xFF7654A3),
    "anxious": Color.fromARGB(255, 183, 105, 32),
    "tired": Color(0xFFA1A8F0),
    "sad": Color.fromARGB(255, 78, 97, 161),
    "irritated": Color(0xFFE2377D),
    "embarrassed": Color(0xFFB71691),
    "comforted": Color(0xFFDBAF35),
    "bored": Color(0xFFCF78F7),
    "excited": Color(0xFFE04CB7),
    "overwhelmed": Color(0xFF7654A3),
    "proud": Color(0xFFDD97B7),
    "surprised": Color(0xFFC79FE2),
    "confused": Color(0xFFB539BC),
    "sick": Color.fromARGB(255, 228, 104, 120),
    "lucky": Color.fromARGB(255, 92, 143, 123),
    "productive": Color.fromARGB(255, 190, 174, 239),
    "disappointed": Color.fromARGB(255, 235, 194, 194),
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
    {'emoji': '🤒', 'key': 'sick'},
    {'emoji': '🍀', 'key': 'lucky'},
    {'emoji': '🚀', 'key': 'productive'},
    {'emoji': '😞', 'key': 'disappointed'},
  ];

  List<Map<String, dynamic>> get mainMoods => moods.take(12).toList();
  List<Map<String, dynamic>> get extraMoods => moods.skip(12).toList();

  @override
  void initState() {
    super.initState();
    tempMonth = widget.month;
    tempYear = widget.year;
    selectedDay = null; // 👈 ESSENCIAL para evitar bug ao trocar mês/ano
    fetchMonthlySummary();
  }

  Future<void> fetchMonthlySummary() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() => topMoods = []);
      return;
    }

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

  Future<void> _saveMood(String moodKey) async {
    final day = selectedDay;

    if (day == null) {
      _showSnack(
        "mood.select_day_first".tr(),
        Colors.black87,
      );
      return;
    }

    final user = supabase.auth.currentUser;

    // 👤 GUEST
    if (user == null) {
      if (guestMoodCount >= guestMoodLimit) {
        showPremiumPopup(context);
        return;
      }

      guestMoodCount++;

      MoodCalendar.globalKey.currentState
          ?.setGuestMood(day, moodKey);

      _showSnack(
        "mood.guest_saved".tr(),
        moodColors[moodKey]!,
      );

      if (guestMoodCount >= guestMoodLimit) {
        Future.delayed(const Duration(milliseconds: 300), () {
          showPremiumPopup(context);
        });
      }
      return;
    }

    if (isSaving) return;
    setState(() => isSaving = true);

    final now = DateTime(widget.year, widget.month, day);

    await supabase
        .from('mood_entries')
        .delete()
        .eq('user_id', user.id)
        .eq('day', day)
        .eq('month', widget.month)
        .eq('year', widget.year);

    await supabase.from('mood_entries').insert({
      'user_id': user.id,
      'mood': moodKey,
      'entry_date': now.toIso8601String(),
      'day': day,
      'month': widget.month,
      'year': widget.year,
      'created_at': DateTime.now().toIso8601String(),
    });

    MoodCalendar.globalKey.currentState
        ?.setGuestMood(day, moodKey);

    await fetchMonthlySummary();

    _showSnack(
      "motivation.$moodKey".tr(),
      moodColors[moodKey]!,
    );

    setState(() => isSaving = false);
  }

  void _showSnack(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFE6BDEA).withOpacity(0.85),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              const SizedBox(height: 26),
              Text(
                "mood.how_are_you_feeling".tr().toLowerCase(),
                textAlign: TextAlign.center,
                
                style: GoogleFonts.monteCarlo(
                  color: Colors.black,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.3,
          

                ),
              ),
              const SizedBox(height: 14),
              FractionallySizedBox(
                widthFactor: 0.9,
                child: Container(
                  height: 1,
                  color: Colors.black
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "mood.page_description".tr(),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -12,
          left: 0,
          right: 0,
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withOpacity(0.7),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFE6BDEA),
              child: const Text("😊", style: TextStyle(fontSize: 22)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodNavigatorButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openAestheticMoodNavigator,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 18),
            const SizedBox(width: 8),
            Text(
              "mood.search_other_dates".tr(),
              style: GoogleFonts.courierPrime(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodGrid(List<Map<String, dynamic>> moodList) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: moodList.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 26,
        childAspectRatio: 2.3,
      ),
      itemBuilder: (context, index) {
        final mood = moodList[index];
        final emoji = mood['emoji'];
        final moodKey = mood['key'];
        final color = moodColors[moodKey]!;

        return GestureDetector(
          onTap: () => _saveMood(moodKey),
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

  void _openAestheticMoodNavigator() {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "mood.choose_period".tr(),
                  style: GoogleFonts.courierPrime(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                // ANO
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setModalState(() => tempYear--);
                      },
                    ),
                    Text(
                      tempYear.toString(),
                      style: GoogleFonts.courierPrime(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setModalState(() => tempYear++);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // MESES
                GridView.builder(
                  shrinkWrap: true,
                  itemCount: 12,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.2,
                  ),
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    final selected = month == tempMonth;

                    return GestureDetector(
                      onTap: () {
                        setModalState(() => tempMonth = month);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFE6BDEA)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Text(
                          "calendar_month_short.$month".tr(),
                          style: GoogleFonts.courierPrime(
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE6BDEA),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      context.go(
                        '/mood',
                        extra: {'month': tempMonth, 'year': tempYear},
                      );
                    },
                    child: Text(
                      "common.open".tr(),
                      style: GoogleFonts.courierPrime(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
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
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: others.map((item) {
            return Column(
              children: [
                Text(item['emoji'], style: const TextStyle(fontSize: 28)),
                Text("${item['percent'].toStringAsFixed(0)}%"),
                Text(
                  trMood(item['key']),
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


Widget _buildGuestStatsCard() {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: const Color(0xFFF2D8F4),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        Text(
          "mood.guest_title".tr(),
          style: GoogleFonts.courierPrime(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "mood.guest_description".tr(),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ],
    ),
  );
}





  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

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

                MoodCalendar(
                  key: MoodCalendar.globalKey,
                  userId: user?.id,
                  month: widget.month,
                  year: widget.year,
                  moodEmojis: moodEmojiMap,
                  moodColors: moodColors,
                  onDaySelected: (day) {
                    setState(() => selectedDay = day);
                  },
                ),

                const SizedBox(height: 20),
                _buildMoodNavigatorButton(),
                const SizedBox(height: 30),

                _buildMoodGrid(mainMoods),
                const SizedBox(height: 20),
                _buildMoodGrid(extraMoods),


                const SizedBox(height: 30),

if (topMoods.isNotEmpty) ...[
  _buildHighlightCard(),
] else if (user == null) ...[
  _buildGuestStatsCard(),
],
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
