// widgets/monthly/day_entry_modal.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/services/calendar_event_service.dart';

class DayEntryModal extends StatefulWidget {
  final int year;
  final int month;
  final int day;
  final Map<String, dynamic>? existing;

  const DayEntryModal({
    super.key,
    required this.year,
    required this.month,
    required this.day,
    this.existing,
  });

  @override
  State<DayEntryModal> createState() => _DayEntryModalState();
}

class _DayEntryModalState extends State<DayEntryModal> {
  // ───────── STATE ─────────
  late TextEditingController _textController;

  int _hour = 8;
  bool _hasAlert = false;
  String _selectedColorHex = "FFe04cb7";
  String _repeatType = 'none';

  List<Map<String, dynamic>> _events = [];

  final List<String> _colors = const [
    "FFe04cb7",
    "FFb71691",
    "FFa1a8f0",
    "FFdd97b7",
    "FFf7d74a",
  ];

  // ───────── LIFECYCLE ─────────
  @override
  void initState() {
    super.initState();

    _textController = TextEditingController(
      text: widget.existing?['title'] ?? '',
    );

    _hour = widget.existing?['hour'] ?? 8;
    _hasAlert = widget.existing?['remind'] ?? false;
    _selectedColorHex =
        widget.existing?['color'] ?? _selectedColorHex;
    _repeatType = widget.existing?['repeat_type'] ?? 'none';

    _loadEvents();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // ───────── DATA ─────────
  Future<void> _loadEvents() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      setState(() => _events = []);
      return;
    }

    final list = await CalendarEventService.getEventsForDay(
      userId: user.id,
      year: widget.year,
      month: widget.month,
      day: widget.day,
    );

    if (!mounted) return;
    setState(() => _events = list);
  }

  Future<void> _save() async {
    final user = SupabaseConfig.client.auth.currentUser;
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // 👤 guest → salva fake
    if (user == null) {
      Navigator.pop(context, true);
      return;
    }

    await CalendarEventService.saveOrUpdateEvent(
      existingId: widget.existing?['id'],
      userId: user.id,
      year: widget.year,
      month: widget.month,
      day: widget.day,
      hour: _hour,
      title: text,
      color: _hasAlert ? _selectedColorHex : "FFe04cb7",
      repeatType: _repeatType,
      remind: _hasAlert,
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _deleteEvent(String id) async {
    await CalendarEventService.deleteEvent(id);
    await _loadEvents();
  }

  // ───────── UI ─────────
  @override
  Widget build(BuildContext context) {
    final user = SupabaseConfig.client.auth.currentUser;

    return Center(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              color: const Color(0xFFFFF1F7),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${widget.day}",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // HOUR
                  DropdownButtonFormField<int>(
                    value: _hour,
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: List.generate(
                      24,
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Text(
                            "${i.toString().padLeft(2, '0')}:00"),
                      ),
                    ),
                    onChanged: (v) => setState(() => _hour = v!),
                  ),

                  const SizedBox(height: 12),

                  // TEXT
                  TextField(
                    controller: _textController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: tr("calendar.describe"),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),



/// 🔁 BADGE DE REPETIÇÃO
if (_repeatType != 'none')
  Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Row(
      children: [
        const Icon(Icons.repeat, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _repeatType == 'daily'
                ? tr("calendar.repeat_daily")
                : _repeatType == 'weekly'
                    ? tr("calendar.repeat_weekly")
                    : _repeatType == 'monthly'
                        ? tr("calendar.repeat_monthly")
                        : tr("calendar.repeat_yearly"),
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    ),
  ),

const SizedBox(height: 12),


                  // ALERT
                  SwitchListTile(
                    value: _hasAlert,
                    onChanged: (v) => setState(() => _hasAlert = v),
                    title: Text(tr("calendar.add_alert")),
                  ),

                  if (_hasAlert)
                    Wrap(
                      spacing: 10,
                      children: _colors.map((hex) {
                        final c =
                            Color(int.parse(hex, radix: 16));
                        return GestureDetector(
                          onTap: () => setState(
                              () => _selectedColorHex = hex),
                          child: CircleAvatar(
                            backgroundColor: c,
                            radius: 16,
                            child: _selectedColorHex == hex
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 16)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 16),



                  const SizedBox(height: 12),

DropdownButtonFormField<String>(
  value: _repeatType,
  dropdownColor: Colors.white,
  decoration: InputDecoration(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 14,
    ),
  ),
  items: [
    DropdownMenuItem(
      value: 'none',
      child: Text(tr("calendar.repeat_none")),
    ),
    DropdownMenuItem(
      value: 'daily',
      child: Text(tr("calendar.repeat_daily")),
    ),
    DropdownMenuItem(
      value: 'weekly',
      child: Text(tr("calendar.repeat_weekly")),
    ),
    DropdownMenuItem(
      value: 'monthly',
      child: Text(tr("calendar.repeat_monthly")),
    ),
    DropdownMenuItem(
      value: 'yearly',
      child: Text(tr("calendar.repeat_yearly")),
    ),
  ],
  onChanged: (v) => setState(() => _repeatType = v!),
),


                  // GUEST WARNING
                  if (user == null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tr("calendar.login_to_save"),
                              style:
                                  const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // EVENTS LIST
                  if (_events.isNotEmpty) ...[
                    Text(
                      tr("calendar.your_notes"),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._events.map((e) => Card(
  child: ListTile(
    leading: Icon(
      Icons.favorite,
      color: Color(int.parse(e['color'], radix: 16)),
    ),
    title: Text(e['title']),
    
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("${e['hour']}:00"),

        if (e['repeat_type'] != 'none')
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              tr("calendar.repeats_${e['repeat_type']}"),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
      ],
    ),
    trailing: IconButton(
      icon: const Icon(
        Icons.delete_outline,
        color: Colors.redAccent,
      ),
      onPressed: () => _deleteEvent(e['id'].toString()),
    ),
  ),
)),

                  ],

                  const SizedBox(height: 20),

                  // ACTIONS
                  Center(
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: _save,
                          child: Text(tr("common.save")),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context),
                          child: Text(tr("common.cancel")),
                        ),
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
  }
}
