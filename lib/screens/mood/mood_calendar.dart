import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';



class MoodCalendar extends StatefulWidget {
  final String? userId;
  final int month;
  final int year;

  final Map<String, String> moodEmojis;
  final Map<String, Color> moodColors;

  final Function(int)? onDaySelected;

  

  const MoodCalendar({
    super.key,
    required this.userId,
    required this.month,
    required this.year,
    required this.moodEmojis,
    required this.moodColors,
    this.onDaySelected,
  });

  static GlobalKey<_MoodCalendarState> globalKey =
      GlobalKey<_MoodCalendarState>();

  static void refresh() {
    globalKey.currentState?.loadMoods();
  }

  @override
  State<MoodCalendar> createState() => _MoodCalendarState();
}

class _MoodCalendarState extends State<MoodCalendar> {
  final supabase = Supabase.instance.client;

  Map<int, String> moodByDay = {};
  int? selectedDay;


  bool _offlineMoodWarned = false; // 👈 AQUI

  @override
  void initState() {
    super.initState();
    loadMoods();
  }

 


  // 👇 COLOCA AQUI
  void _showOfflineMoodWarning() {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      backgroundColor: const Color(0xFFFFEEF4),
      content: Text(
        'Para registrar o humor, é preciso estar online 💭',
        style: const TextStyle(color: Color(0xFF6D2C4A)),
      ),
    ),
  );
}


  

  void setGuestMood(int day, String moodKey) {
    setState(() {
      moodByDay[day] = moodKey;
    });
  }



  Future<void> loadMoods() async {
  // 👤 Guest não carrega do Supabase
  if (widget.userId == null) {
  // Guest NÃO carrega do Supabase
  // mas também NÃO apaga estado local
  return;
}

  final result = await supabase
      .from('mood_entries')
      .select()
      .eq('user_id', widget.userId!) 
      .eq('month', widget.month)
      .eq('year', widget.year);

  final map = <int, String>{};

  for (var entry in result) {
    map[entry['day']] = entry['mood'];
  }

  if (!mounted) return;
  setState(() => moodByDay = map);
}


Future<void> _deleteMood(int day) async {
  final userId = widget.userId;

  // 👤 Guest: remove só local
  if (userId == null) {
    if (!mounted) return;
    setState(() {
      moodByDay.remove(day);
    });
    return;
  }

  // 👑 Premium: remove do Supabase
  await supabase
      .from('mood_entries')
      .delete()
      .eq('user_id', userId)
      .eq('day', day)
      .eq('month', widget.month)
      .eq('year', widget.year);

  if (!mounted) return;

  setState(() {
    moodByDay.remove(day);
  });
}


  // -------------------------------------------------------
  // 🌸 POPUP DE AÇÕES DO HUMOR DO DIA
  // -------------------------------------------------------
  
  
  void _showMoodActionsPopup(int day, String moodKey) async {
  final userId = widget.userId;
  final currentContext = context;

  // 👤 Guest não consulta Supabase
  if (userId == null) {
    // aqui você pode:
    // - retornar direto
    // - ou mostrar popup premium
    return;
  }

  final startDate =
      DateTime(widget.year, widget.month, 1).toIso8601String();
  final endDate =
      DateTime(widget.year, widget.month + 1, 0).toIso8601String();

  final result = await Supabase.instance.client
      .from("diary_entries")
      .select("entry_date")
      .eq("user_id", userId)
      .gte("entry_date", startDate)
      .lte("entry_date", endDate);

  final bool hasEntry = result.any((entry) {
    final date = DateTime.parse(entry["entry_date"]);
    return date.day == day &&
        date.month == widget.month &&
        date.year == widget.year;
  });
    if (!mounted) return;

    final fullDate = DateFormat(
      "dd 'de' MMMM 'de' y",
      "pt_BR",
    ).format(DateTime(widget.year, widget.month, day));

    showModalBottomSheet(
      context: currentContext,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 22,
              right: 22,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 40,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.moodEmojis[moodKey] ?? "😊",
                  style: const TextStyle(fontSize: 46),
                ),

                const SizedBox(height: 10),

                Text(
                  "${'calendar.mood_of_day'.tr()} $fullDate",
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 22),
                const Divider(),

                // 📘 Ver entradas
                ListTile(
                  leading: const Icon(Icons.menu_book_rounded, color: Colors.purple),
                  title: Text(
                    hasEntry
                        ? 'calendar.view_entries'.tr()
                        : 'calendar.no_entries_day'.tr(),
                    style: GoogleFonts.poppins(fontSize: 15),
                  ),
                  enabled: hasEntry,
                  onTap: hasEntry
                      ? () {
                          Navigator.pop(context);
                          Future.delayed(const Duration(milliseconds: 80), () {
                            context.push(
                              "/diary",
                              extra: DateTime(widget.year, widget.month, day),
                            );
                          });
                        }
                      : null,
                ),

                // ✍️ Escrever no diário
                ListTile(
                  leading: const Icon(Icons.edit_note_rounded,
                      color: Colors.deepPurple),
                  title: Text(
                    'calendar.write_diary'.tr(),
                    style: GoogleFonts.poppins(fontSize: 15),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Future.delayed(const Duration(milliseconds: 80), () {
                      context.push(
                        "/diary",
                        extra: DateTime(widget.year, widget.month, day),
                      );

                    });
                  },
                ),

                // 🎨 Editar humor
                ListTile(
                  leading:
                      const Icon(Icons.edit_rounded, color: Colors.pinkAccent),
                  title: Text(
                    'calendar.edit_mood'.tr(),
                    style: GoogleFonts.poppins(fontSize: 15),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => selectedDay = day);
                  },
                ),

                // 🗑️ Excluir humor
  ListTile(
  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
  title: Text(
    'calendar.delete_mood'.tr(),
    style: GoogleFonts.poppins(
      fontSize: 15,
      color: Colors.redAccent,
    ),
  ),
  onTap: () {
    final parentContext = context;

    Navigator.pop(parentContext);

    Future.delayed(const Duration(milliseconds: 100), () {
      _deleteMood(day);
    });
  },
),

              ],
            ),
          ),
        );
      },
    );
  } //  👈👈👈 FECHAMENTO DO MÉTODO (O QUE FALTAVA!)


  

  // -------------------------------------------------------
  // 🏗️ BUILD
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final totalDays = DateTime(widget.year, widget.month + 1, 0).day;
    final firstWeekday =
    DateTime(widget.year, widget.month, 1).weekday;



    final today = DateTime.now();
    final isTodayMonth =
        today.month == widget.month && today.year == widget.year;

    List<Widget> grid = [];

    for (int i = 1; i < firstWeekday; i++) {
    grid.add(Container());


    }

    for (int day = 1; day <= totalDays; day++) {
      final moodKey = moodByDay[day];
      final emoji = moodKey != null ? widget.moodEmojis[moodKey] : null;

      final bool isSelected = selectedDay == day;
      final bool isToday = isTodayMonth && today.day == day;

      

      grid.add(
  GestureDetector(
    onTap: () {
      setState(() => selectedDay = day);

      final moodKey = moodByDay[day];

      // 🟣 Já existe humor → popup normal
      if (moodKey != null) {
        Future.delayed(const Duration(milliseconds: 120), () {
          _showMoodActionsPopup(day, moodKey);
        });
        widget.onDaySelected?.call(day);
        return;
      }

      // 🟠 Dia vazio + guest → avisa uma vez
      if (widget.userId == null) {
        if (!_offlineMoodWarned && mounted) {
          _showOfflineMoodWarning();
          _offlineMoodWarned = true;
        }
        return;
      }

      // ✅ Usuário válido → segue fluxo normal
      widget.onDaySelected?.call(day);
    },
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isSelected ? Colors.pink.withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: isToday
            ? Border.all(color: Colors.pinkAccent, width: 2)
            : Border.all(color: Colors.black12, width: 1),
      ),
      alignment: Alignment.center,
      child: emoji == null
          ? Text(
              "$day",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            )
          : Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
    ),
  ),
);

  
    }

    return Column(
      children: [
        Text(
          "${"calendar_month.${widget.month}".tr()} ${widget.year}",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 30),

        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          children: grid,
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}
