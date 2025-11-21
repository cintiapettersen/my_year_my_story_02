// calendar_page.dart
// Generated page following Option B with theme, description, and monthly template.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/services/calendar_event_service.dart';



class CalendarPage extends StatefulWidget {
  final int month;
  final int year;

  const CalendarPage({super.key, required this.month, required this.year});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  bool _isLoading = false;
  bool _isPremiumUser = false;
  bool _isGuest = false;

  int? _entryId;

  String _themeTitle = '';
  String _themeDescription = '';

  List<String> _questions = [];
  List<TextEditingController> _controllers = [];

  int _insertionCount = 0;


 
// ------------------ EVENT MODAL CIRCULAR ESTILO ILUSTRATOR ------------------
Future<void> _openEventModal(int day) async {
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 320,
            height: 420,
            decoration: BoxDecoration(
              color: const Color(0xFFF4E1F2),     // fundo rosinha circular
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // CARD DA DATA (quadradinho lilás)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4D1FA),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "$day",
                          style: const TextStyle(
                            fontSize: 52,
                            fontFamily: "RobotoMono",
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          DateFormat.MMMM('pt_BR')
                              .format(DateTime(widget.year, widget.month))
                              .toLowerCase(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontFamily: "RobotoMono",
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // título "adicionar evento"
                  const Text(
                    "adicionar evento",
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: "RobotoMono",
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // input TÍTULO
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(
                      fontFamily: "RobotoMono",
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "titulo",
                      hintStyle: const TextStyle(
                        fontFamily: "RobotoMono",
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // input DESCRIÇÃO
                  TextField(
                    controller: descCtrl,
                    style: const TextStyle(
                      fontFamily: "RobotoMono",
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "descricao",
                      hintStyle: const TextStyle(
                        fontFamily: "RobotoMono",
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // BOTÃO CRIAR ALERTA
                  SizedBox(
                    width: 160,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 208, 195, 255), // lilás
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
  final user = SupabaseConfig.client.auth.currentUser;

  if (user == null) {
    Navigator.pop(context);
    showPremiumPopup(context); // pode manter seu fluxo de login/premium
    return;
  }

  final title = titleCtrl.text.trim();
  final desc = descCtrl.text.trim();

  if (title.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Digite um título para salvar o evento.")),
    );
    return;
  }

  setState(() => _isLoading = true);

  await CalendarEventService.createEvent(
    userId: user.id,
    year: widget.year,
    month: widget.month,
    day: day,
    title: title,
    description: desc.isEmpty ? null : desc,
    remind: true,           // por enquanto sempre true — depois deixamos opcional
    repeatType: 'none',
  );

  setState(() => _isLoading = false);

  Navigator.pop(context);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Evento salvo!")),
  );
},

                      child: const Text(
                        "criar alerta",
                        style: TextStyle(
                          fontFamily: "RobotoMono",
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}


  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    await _checkUserStatus();
    await _loadThemeAndQuestions();
    await _loadSavedAnswers();
    setState(() {});
  }

  Future<void> _checkUserStatus() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      _isGuest = true;
      _isPremiumUser = false;
      return;
    }
    _isGuest = false;
    _isPremiumUser = true;
  }

  Future<void> _loadThemeAndQuestions() async {
    _themeTitle = 'dates.title'.tr();
    _themeDescription = 'dates.description'.tr();
    _questions = [];
    _controllers = [];
  }

  Future<void> _loadSavedAnswers() async {}
  Future<void> _saveAnswers() async {}

  @override
  Widget build(BuildContext context) {
    return MonthPageTemplate(
      month: widget.month,
      year: widget.year,
      title: '',
      pageLabel: 'dates.title'.tr(),
      labelColor: const Color(0xFF636EE6),
      description: _themeDescription,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildCalendar(),
    );
  }

  // ------------------ MAIN CALENDAR WRAPPER ------------------
  Widget _buildCalendar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildCalendarHeader(),
        const SizedBox(height: 12),
        _buildWeekdaysRow(),
        const SizedBox(height: 6),
        _buildCalendarGrid(),
        const SizedBox(height: 20),
      ],
    );
  }

  // ------------------ CALENDAR HEADER ------------------
  Widget _buildCalendarHeader() {
    final monthName = DateFormat.MMMM('pt_BR').format(
      DateTime(widget.year, widget.month),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, size: 26),
          onPressed: () {
            final prev = DateTime(widget.year, widget.month - 1, 1);
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) =>
                    CalendarPage(month: prev.month, year: prev.year),
                transitionDuration: Duration.zero,
              ),
            );
          },
        ),
        Text(
          '${monthName[0].toUpperCase()}${monthName.substring(1)}',

          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, size: 26),
          onPressed: () {
            final next = DateTime(widget.year, widget.month + 1, 1);
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) =>
                    CalendarPage(month: next.month, year: next.year),
                transitionDuration: Duration.zero,
              ),
            );
          },
        ),
      ],
    );
  }

  // ------------------ WEEKDAYS ROW ------------------
  Widget _buildWeekdaysRow() {
    final days = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    return Row(
      children: days
          .map(
            (d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }


// ------------------ CALENDAR WEEKDAY FIX ------------------
int _getStartingWeekday() {
  final firstDay = DateTime(widget.year, widget.month, 1);

  // Flutter: Monday = 1 → Sunday = 7
  // Seu calendário: Sunday = 0 → Saturday = 6
  return firstDay.weekday == DateTime.sunday
      ? 0
      : firstDay.weekday;
}




  // ------------------ CALENDAR GRID ------------------
  Widget _buildCalendarGrid() {
    final DateTime firstDayOfMonth = DateTime(widget.year, widget.month, 1);
    final int daysInMonth = DateTime(widget.year, widget.month + 1, 0).day;
    final int startingWeekday = _getStartingWeekday();

    List<Widget> dayTiles = [];

    for (int i = 0; i < startingWeekday; i++) {
      dayTiles.add(Container());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      dayTiles.add(
        GestureDetector(
          onTap: () => _openEventModal(day),

          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Center(
              child: Text(
                "$day",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      children: dayTiles,
    );
  }
}
