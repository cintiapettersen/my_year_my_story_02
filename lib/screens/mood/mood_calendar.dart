import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myyearmystory/screens/mood/mood_repository.dart';



class MoodCalendar extends StatefulWidget {
  final String userId;
  final int month;
  final int year;

  /// Emojis + cores vindo da tela de humor
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

  @override
  State<MoodCalendar> createState() => _MoodCalendarState();
}

class _MoodCalendarState extends State<MoodCalendar> {
  final MoodRepository repo = MoodRepository();

  Map<int, String> moodsByDay = {}; // dia → moodKey

  @override
  void initState() {
    super.initState();
    _loadMoods();
  }

  Future<void> _loadMoods() async {
    final moods = await repo.getMoodsForMonth(
      userId: widget.userId,
      month: widget.month,
      year: widget.year,
    );

    final map = <int, String>{};

    for (final m in moods) {
      final date = DateTime.parse(m['entry_date']);
      final moodKey = m['mood'];
      map[date.day] = moodKey;
    }

    setState(() => moodsByDay = map);
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(widget.year, widget.month + 1, 0).day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),

        Text(
          _monthName(widget.month) + " ${widget.year}",
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
                duration: Duration(milliseconds: 250),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgColor,
                  boxShadow: [
                    if (hasMood)
                      BoxShadow(
                        color: widget.moodColors[moodKey]!.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                  ],
                  border: Border.all(
                    color: hasMood ? Colors.transparent : Colors.grey.shade400,
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: hasMood
                    ? Text(
                        widget.moodEmojis[moodKey]!,
                        style: const TextStyle(
                          fontSize: 24,
                        ),
                      )
                    : Text(
                        "$day",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.black87,
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
