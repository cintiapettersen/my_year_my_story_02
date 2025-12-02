import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myyearmystory/screens/mood/mood_repository.dart';

class MoodCalendar extends StatefulWidget {
  final String userId;
  final int month;
  final int year;

  final Map<String, String> moodEmojis;
  final Map<String, Color> moodColors;

  const MoodCalendar({
    super.key,
    required this.userId,
    required this.month,
    required this.year,
    required this.moodEmojis,
    required this.moodColors,
  });

  /// 🔥 Permite o MoodScreen mandar recarregar depois de salvar
  static final _calendarKey = GlobalKey<_MoodCalendarState>();

  static void refresh() {
    if (_calendarKey.currentState != null) {
      _calendarKey.currentState!._loadMoods();
    }
  }

  @override
  State<MoodCalendar> createState() => _MoodCalendarState();
}

class _MoodCalendarState extends State<MoodCalendar> {
  final MoodRepository repo = MoodRepository();

  Map<int, String> moodsByDay = {};

  @override
  void initState() {
    super.initState();
    _loadMoods();
  }

  Future<void> _loadMoods() async {
    if (widget.userId.isEmpty) {
      setState(() => moodsByDay = {});
      return;
    }

    final moods = await repo.getMoodsForMonth(
      userId: widget.userId,
      month: widget.month,
      year: widget.year,
    );

    final Map<int, String> map = {};

    for (final m in moods) {
      final raw = m['entry_date'];

      // Correção do timezone
      final date = DateTime.tryParse(raw)?.toLocal();
      if (date == null) continue;

      final day = date.day;
      final moodKey = m['mood'];

      // Último humor do dia vence
      map[day] = moodKey;
    }

    setState(() => moodsByDay = map);
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(widget.year, widget.month + 1, 0).day;

    return Column(
      children: [
        const SizedBox(height: 12),

        Text(
          "${_monthName(widget.month)} ${widget.year}",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 18),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: daysInMonth,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 10,
            mainAxisSpacing: 14,
          ),
          itemBuilder: (_, index) {
            final day = index + 1;
            final moodKey = moodsByDay[day];
            final hasMood = moodKey != null;

            final bgColor = hasMood
                ? widget.moodColors[moodKey]!.withOpacity(0.85)
                : Colors.white;

            return Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgColor,
                  border: Border.all(
                    color: hasMood ? Colors.transparent : Colors.grey.shade400,
                    width: 1.2,
                  ),
                  boxShadow: [
                    if (hasMood)
                      BoxShadow(
                        color: widget.moodColors[moodKey]!.withOpacity(0.35),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                  ],
                ),
                child: Center(
                  child: hasMood
                      ? Text(
                          widget.moodEmojis[moodKey]!,
                          style: const TextStyle(fontSize: 24),
                        )
                      : Text(
                          "$day",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _monthName(int m) {
    const nomes = [
      "",
      "Janeiro",
      "Fevereiro",
      "Março",
      "Abril",
      "Maio",
      "Junho",
      "Julho",
      "Agosto",
      "Setembro",
      "Outubro",
      "Novembro",
      "Dezembro"
    ];
    return nomes[m];
  }
}
