import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/services/calendar_event_service.dart';
import 'package:myyearmystory/widgets/monthly/calender/day_entry_modal.dart';
import 'package:myyearmystory/utils/access_control.dart';

class CalendarPage extends StatefulWidget {
  final int month;
  final int year;

  const CalendarPage({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  /// 👤 guest — eventos fake (não persistem)
  final List<Map<String, dynamic>> _guestEvents = [];

  bool _isLoading = true;
  bool _isPremiumUser = false;

  final Map<int, String?> _eventColors = {};
  List<Map<String, dynamic>> _monthEvents = [];

  // ======================
  // CONSTANTES (WEEK HEADER)
  // ======================
  
  List<String> _getWeekDays(BuildContext context) {
  return [
    tr('week.mon'),
    tr('week.tue'),
    tr('week.wed'),
    tr('week.thu'),
    tr('week.fri'),
    tr('week.sat'),
    tr('week.sun'),
  ];
}


  static const List<Color> _weekDayColors = [
    Color(0xFFE9A3B8),
    Color(0xFFC7C6F7),
    Color(0xFFD6B44C),
    Color(0xFFD35BB8),
    Color(0xFF86A99B),
    Color(0xFF8E3A82),
    Color(0xFFD3487A),
  ];

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  // ======================
  // INIT
  // ======================
  Future<void> _initPage() async {
    final user = SupabaseConfig.client.auth.currentUser;

    if (user != null) {
      _isPremiumUser = await AccessControl.isPremium();
      await _loadMonthEvents();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ======================
  // LOAD EVENTS (REAL)
  // ======================
  Future<void> _loadMonthEvents() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    final events = await CalendarEventService.getEventsForMonth(
      userId: user.id,
      year: widget.year,
      month: widget.month,
    );

    _monthEvents = events;

    _eventColors.clear();

    for (final e in events) {
      final int day = e['day'];
      final String color = e['color'];
      _eventColors[day] = color;
    }

    if (mounted) setState(() {});
  }

  // ======================
  // HELPERS
  // ======================
  bool _isToday(int day) {
    final now = DateTime.now();
    return now.year == widget.year &&
        now.month == widget.month &&
        now.day == day;
  }

  // 🔁 helper substituído
  int _getStartingWeekday() {
    final firstDay = DateTime(widget.year, widget.month, 1);
    return firstDay.weekday - 1; // semana começa na SEG
  }

  // ======================
  // HEADER FOFINHO
  // ======================
  Widget _buildCuteWeekdayHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(7, (index) {
          final isWeekend = index >= 5;

          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isWeekend
                    ? _weekDayColors[index].withOpacity(0.85)
                    : _weekDayColors[index],
                borderRadius: BorderRadius.circular(12),
                boxShadow: isWeekend
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  _getWeekDays(context)[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ======================
  // OPEN DAY MODAL
  // ======================
  Future<void> _openDayEntry(int day) async {
    final user = SupabaseConfig.client.auth.currentUser;
    Map<String, dynamic>? existing;

    if (user == null) {
      final dayEvents =
          _guestEvents.where((e) => e['day'] == day).toList();
      if (dayEvents.isNotEmpty) {
        existing = dayEvents.last;
      }
    }

    if (user != null) {
      final events = await CalendarEventService.getEventsForDay(
        userId: user.id,
        year: widget.year,
        month: widget.month,
        day: day,
      );

      if (events.isNotEmpty) {
        existing = events.last;
      }

      if (!_isPremiumUser && existing == null) {
        final count =
            await CalendarEventService.countUserEventsForMonth(
          user.id,
          widget.year,
          widget.month,
        );

        if (!mounted) return;

        if (count >= 3) {
          showPremiumPopup(context);
          return;
        }
      }
    }

    if (!mounted) return;

    final result = await showDialog<dynamic>(
      context: context,
      builder: (_) => DayEntryModal(
        year: widget.year,
        month: widget.month,
        day: day,
        existing: existing,
      ),
    );

    if (!mounted || result == null) return;

    if (user != null) {
      await _loadMonthEvents();
      return;
    }

    final resultDay = result['day'] as int;
    final title = result['title'] as String;
    final color = result['color'] as String;

    _guestEvents.removeWhere((e) => e['day'] == resultDay);

    _guestEvents.add({
      'day': resultDay,
      'title': title,
      'color': color,
    });

    _eventColors[resultDay] = color;

    setState(() {});
  }

  // ======================
  // UI
  // ======================
  @override
  Widget build(BuildContext context) {
    return MonthPageTemplate(
      month: widget.month,
      year: widget.year,
      title: '',
      pageLabel: tr("dates.title"),
      description: tr("dates.description"),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Text(
                      tr("calendar.description"),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  _buildCuteWeekdayHeader(),
                  const SizedBox(height: 8),
                  _buildCalendar(),

                  _buildMonthInsight(),
                  _buildEventList(),
                ],
              ),
            ),
    );
  }

  // ======================
  // CALENDAR GRID
  // ======================
  Widget _buildCalendar() {
    final daysInMonth =
        DateTime(widget.year, widget.month + 1, 0).day;
    final startingWeekday = _getStartingWeekday();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      children: [
        for (int i = 0; i < startingWeekday; i++)
          const SizedBox(),
        for (int day = 1; day <= daysInMonth; day++)
          _buildDayTile(day),
      ],
    );
  }

  Widget _buildDayTile(int day) {
    final hex = _eventColors[day];
    final hasEntry = hex != null;
    final isToday = _isToday(day);

    final weekdayIndex =
        DateTime(widget.year, widget.month, day).weekday - 1;

    final dayColor = _weekDayColors[weekdayIndex];

    return GestureDetector(
      onTap: () => _openDayEntry(day),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isToday ? dayColor : Colors.grey.shade300,
            width: isToday ? 2 : 1,
          ),
          boxShadow: weekdayIndex >= 5
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Center(
          child: hasEntry
              ? Icon(
                  Icons.favorite,
                  color: Color(int.parse(hex, radix: 16)),
                  size: 26,
                )
              : Text('$day'),
        ),
      ),
    );
  }

  // ======================
  // INSIGHT + LIST
  // ======================
  Widget _buildMonthInsight() {
    if (_monthEvents.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        tr("dates.insight", args: ["${_monthEvents.length}"]),
        style: const TextStyle(fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildEventList() {
    final user = SupabaseConfig.client.auth.currentUser;

    if (user == null) {
      if (_guestEvents.isEmpty) return const SizedBox();

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr("calendar.your_notes"),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ..._guestEvents.map((e) {
              final color =
                  Color(int.parse(e['color'], radix: 16));
              return Card(
                child: ListTile(
                  leading:
                      Icon(Icons.favorite, color: color),
                  title: Text(e['title']),
                  subtitle:
                      Text('${e['day']}/${widget.month}'),
                  onTap: () => _openDayEntry(e['day']),
                ),
              );
            }).toList(),
          ],
        ),
      );
    }

    if (_monthEvents.isEmpty) return const SizedBox();

    final events = _isPremiumUser
        ? _monthEvents
        : _monthEvents
            .where((e) => e['repeat_type'] == 'none')
            .take(5)
            .toList();

    if (events.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr("calendar.your_notes"),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ...events.map((e) {
            final color =
                Color(int.parse(e['color'], radix: 16));
            return Card(
              child: ListTile(
                leading:
                    Icon(Icons.favorite, color: color),
                title: Text(e['title']),
                subtitle:
                    Text('${e['day']}/${widget.month}'),
                onTap: () => _openDayEntry(e['day']),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
