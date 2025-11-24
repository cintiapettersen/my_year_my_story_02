// calendar_page.dart
import 'dart:ui';
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

  const CalendarPage({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  bool _isLoading = false;
  bool _isGuest = false;

  Map<int, String?> _eventColors = {};

  final List<String> _colorHexOptions = const [
    "FFe04cb7",
    "FFb71691",
    "FFa1a8f0",
    "FFdd97b7",
    "FFf7d74a",
  ];

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    await _checkUserStatus();
    await _loadMonthEvents();
    setState(() {});
  }

  Future<void> _checkUserStatus() async {
    final user = SupabaseConfig.client.auth.currentUser;
    _isGuest = user == null;
  }

  Future<void> _loadMonthEvents() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    final events = await CalendarEventService.getEventsForMonth(
      userId: user.id,
      year: widget.year,
      month: widget.month,
    );

    _eventColors.clear();
    for (final e in events) {
      _eventColors[e['day']] = e['color'];
    }

    if (mounted) setState(() {});
  }

  /// =============================================================
  /// WEEKDAY BUTTON COMPONENT
  /// =============================================================
  Widget _weekButton(
      Function(void Function()) setModal,
      List<String> selectedDays,
      String key,
      String label) {
    final isSelected = selectedDays.contains(key);

    return GestureDetector(
      onTap: () {
        setModal(() {
          if (isSelected) {
            selectedDays.remove(key);
          } else {
            selectedDays.add(key);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.35)
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  /// =============================================================
   /// =============================================================
  /// MODAL
  /// =============================================================
  Future<void> _openEventModal(int day) async {
    final user = SupabaseConfig.client.auth.currentUser;

    if (user == null) {
      showPremiumPopup(context);
      return;
    }

    final existing = await CalendarEventService.getEventForDay(
      userId: user.id,
      year: widget.year,
      month: widget.month,
      day: day,
    );

    final textController =
        TextEditingController(text: existing?['title'] ?? "");
    String selectedColorHex =
        existing?['color'] ?? _colorHexOptions.first;

    String repeatType = existing?['repeat_type'] ?? "none";

    List<String> selectedWeekdays =
        (existing?['repeat_days'] as List?)?.cast<String>() ?? [];

    int daysBefore = existing?['days_before'] ?? 0;

    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Center(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                child: Dialog(
                  insetPadding:
                      const EdgeInsets.symmetric(horizontal: 26),
                  backgroundColor: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(20),

                    constraints: const BoxConstraints(
                      maxHeight: 620,
                      maxWidth: 420,
                    ),

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color:
                          const Color(0xFFFFE4EC).withOpacity(0.55),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.35),
                        width: 1.4,
                      ),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFFF1F7).withOpacity(0.65),
                          const Color(0xFFFFD4E3).withOpacity(0.55),
                        ],
                      ),
                    ),

                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Stack(
                        children: [
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () =>
                                  Navigator.of(context).pop(),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(0.28),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 20, color: Colors.white),
                              ),
                            ),
                          ),

                          Padding(
                            padding:
                                const EdgeInsets.only(top: 40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 10),

                                Container(
                                  padding:
                                      const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    color: Colors.white
                                        .withOpacity(0.18),
                                    border: Border.all(
                                      color: Colors.white
                                          .withOpacity(0.22),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        "$day",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 30,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        DateFormat.MMMM('pt_BR')
                                            .format(DateTime(
                                                widget.year,
                                                widget.month)),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                Text(
                                  existing == null
                                      ? tr("calendar.add_event")
                                      : tr("calendar.edit_event"),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                                const SizedBox(height: 20),

                                TextField(
                                  controller: textController,
                                  style: const TextStyle(
                                      color: Colors.white),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white
                                        .withOpacity(0.15),
                                    hintText:
                                        tr("calendar.event_hint"),
                                    hintStyle: TextStyle(
                                      color: Colors.white
                                          .withOpacity(0.7),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                              12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                Text(
                                  tr("calendar.color"),
                                  style: TextStyle(
                                      color: Colors.white
                                          .withOpacity(0.9)),
                                ),

                                const SizedBox(height: 10),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children:
                                      _colorHexOptions.map((hex) {
                                    final color =
                                        Color(int.parse(hex,
                                            radix: 16));
                                    final isSelected =
                                        selectedColorHex ==
                                            hex;

                                    return GestureDetector(
                                      onTap: () => setModal(() =>
                                          selectedColorHex =
                                              hex),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(
                                                milliseconds:
                                                    180),
                                        margin:
                                            const EdgeInsets
                                                .symmetric(
                                                    horizontal:
                                                        6),
                                        width: isSelected
                                            ? 38
                                            : 32,
                                        height: isSelected
                                            ? 38
                                            : 32,
                                        decoration:
                                            BoxDecoration(
                                          color: color,
                                          shape:
                                              BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white
                                                .withOpacity(
                                                    isSelected
                                                        ? 1
                                                        : 0.4),
                                            width: isSelected
                                                ? 3
                                                : 1.5,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),

                                const SizedBox(height: 22),

                                Text(
                                  tr("calendar.repeat"),
                                  style: TextStyle(
                                      color: Colors.white
                                          .withOpacity(0.9)),
                                ),

                                const SizedBox(height: 10),

                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white
                                        .withOpacity(0.15),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton(
                                      dropdownColor:
                                          const Color(
                                              0xFFFFF1F7),
                                      value: repeatType,
                                      style: const TextStyle(
                                          color:
                                              Color.fromARGB(221, 154, 59, 142)),
                                      icon: const Icon(
                                          Icons
                                              .arrow_drop_down,
                                          color:
                                              Colors.white),
                                      items: [
                                        DropdownMenuItem(
                                          value: "none",
                                          child: Text(tr(
                                              "calendar.repeat_none")),
                                        ),
                                        DropdownMenuItem(
                                          value: "daily",
                                          child: Text(tr(
                                              "calendar.repeat_daily")),
                                        ),
                                        DropdownMenuItem(
                                          value: "weekly",
                                          child: Text(tr(
                                              "calendar.repeat_weekly")),
                                        ),
                                        DropdownMenuItem(
                                          value: "monthly",
                                          child: Text(tr(
                                              "calendar.repeat_monthly")),
                                        ),
                                        DropdownMenuItem(
                                          value: "yearly",
                                          child: Text(tr(
                                              "calendar.repeat_yearly")),
                                        ),
                                      ],
                                      onChanged: (v) =>
                                          setModal(() =>
                                              repeatType = v!),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                if (repeatType == "weekly") ...[
                                  Text(
                                    tr("calendar.weekdays"),
                                    style: TextStyle(
                                        color: Colors.white
                                            .withOpacity(0.9)),
                                  ),
                                  const SizedBox(
                                      height: 10),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      _weekButton(
                                          setModal,
                                          selectedWeekdays,
                                          "Mon",
                                          tr("week.mon")),
                                      _weekButton(
                                          setModal,
                                          selectedWeekdays,
                                          "Tue",
                                          tr("week.tue")),
                                      _weekButton(
                                          setModal,
                                          selectedWeekdays,
                                          "Wed",
                                          tr("week.wed")),
                                      _weekButton(
                                          setModal,
                                          selectedWeekdays,
                                          "Thu",
                                          tr("week.thu")),
                                      _weekButton(
                                          setModal,
                                          selectedWeekdays,
                                          "Fri",
                                          tr("week.fri")),
                                      _weekButton(
                                          setModal,
                                          selectedWeekdays,
                                          "Sat",
                                          tr("week.sat")),
                                      _weekButton(
                                          setModal,
                                          selectedWeekdays,
                                          "Sun",
                                          tr("week.sun")),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                Text(
                                  tr("calendar.days_before"),
                                  style: TextStyle(
                                      color: Colors.white
                                          .withOpacity(0.9)),
                                ),

                                const SizedBox(height: 10),

                                Container(
                                  width: 180,
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                              horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white
                                        .withOpacity(0.15),
                                    borderRadius:
                                        BorderRadius.circular(
                                            12),
                                  ),
                                  child: TextField(
                                    controller:
                                        TextEditingController(
                                            text:
                                                "$daysBefore"),
                                    keyboardType:
                                        TextInputType.number,
                                    textAlign:
                                        TextAlign.center,
                                    style: const TextStyle(
                                        color: Colors.white),
                                    onChanged: (v) {
                                      setModal(() =>
                                          daysBefore =
                                              int.tryParse(v) ??
                                                  0);
                                    },
                                    decoration:
                                        const InputDecoration(
                                      border:
                                          InputBorder.none,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                if (existing != null)
                                  TextButton(
                                    onPressed: () async {
                                      final confirm =
                                          await showDialog<
                                              bool>(
                                        context: context,
                                        builder: (_) =>
                                            AlertDialog(
                                          title: Text(tr(
                                              "calendar.delete_title")),
                                          content: Text(tr(
                                              "calendar.delete_message")),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(
                                                      context,
                                                      false),
                                              child: Text(tr(
                                                  "common.cancel")),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(
                                                      context,
                                                      true),
                                              child: Text(
                                                tr("common.delete"),
                                                style:
                                                    const TextStyle(
                                                        color:
                                                            Colors.red),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm != true)
                                        return;

                                      await CalendarEventService
                                          .deleteEvent(
                                              existing['id']);

                                      Navigator.pop(
                                          context);
                                      _loadMonthEvents();
                                    },
                                    child: Text(
                                      tr("calendar.delete_button"),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        decoration:
                                            TextDecoration
                                                .underline,
                                      ),
                                    ),
                                  ),

                                const SizedBox(height: 12),

                                ElevatedButton(
                                  style: ElevatedButton
                                      .styleFrom(
                                    backgroundColor:
                                        Colors.white
                                            .withOpacity(
                                                0.25),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius
                                              .circular(12),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final text =
                                        textController.text
                                            .trim();

                                    if (text.isEmpty) {
                                      ScaffoldMessenger.of(
                                              context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              tr("calendar.error_empty")),
                                        ),
                                      );
                                      return;
                                    }

                                    await CalendarEventService
                                        .saveOrUpdateEvent(
                                      existingId:
                                          existing?['id'],
                                      userId: user.id,
                                      year: widget.year,
                                      month: widget.month,
                                      day: day,
                                      title: text,
                                      color:
                                          selectedColorHex,
                                      repeatType:
                                          repeatType,
                                      repeatDays:
                                          selectedWeekdays,
                                      daysBefore:
                                          daysBefore,
                                    );

                                    Navigator.pop(
                                        context);
                                    _loadMonthEvents();
                                  },
                                  child: Text(
                                    existing == null
                                        ? tr("calendar.create")
                                        : tr("calendar.save"),
                                    style:
                                        const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  } // <-- AGORA FECHOU! 🎉

  /// =============================================================
  /// CALENDAR
  /// =============================================================
  int _getStartingWeekday() {
    final firstDay = DateTime(widget.year, widget.month, 1);
    return firstDay.weekday == DateTime.sunday ? 0 : firstDay.weekday;
  }

  @override
  Widget build(BuildContext context) {
    return MonthPageTemplate(
      month: widget.month,
      year: widget.year,
      title: '',
      pageLabel: tr("dates.title"),
      labelColor: const Color(0xFF636EE6),
      description: tr("dates.description"),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildCalendar(),
    );
  }

  Widget _buildCalendar() {
    return Column(
      children: [
        const SizedBox(height: 15),
        _buildCalendarHeader(),
        const SizedBox(height: 12),
        _buildWeekdaysRow(),
        const SizedBox(height: 6),
        _buildCalendarGrid(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    final m = DateFormat.MMMM('pt_BR').format(
      DateTime(widget.year, widget.month),
    );
    final monthName = m[0].toUpperCase() + m.substring(1);

    return Text(
      monthName,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildWeekdaysRow() {
    final days = [
      tr("week.short.sun"),
      tr("week.short.mon"),
      tr("week.short.tue"),
      tr("week.short.wed"),
      tr("week.short.thu"),
      tr("week.short.fri"),
      tr("week.short.sat"),
    ];

    return Row(
      children: days
          .map(
            (d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth =
        DateTime(widget.year, widget.month + 1, 0).day;
    final startingWeekday = _getStartingWeekday();

    List<Widget> tiles = [];

    for (int i = 0; i < startingWeekday; i++) {
      tiles.add(Container());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final hex = _eventColors[day];
      final color =
          hex != null ? Color(int.parse(hex, radix: 16)) : null;

      tiles.add(
        GestureDetector(
          onTap: () => _openEventModal(day),
          child: Container(
            margin: const EdgeInsets.all(4),
            height: 48,
            decoration: BoxDecoration(
              color: color ?? Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (color == null)
                  Text(
                    "$day",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (color != null)
                  const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 28,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      children: tiles,
    );
  }
}
