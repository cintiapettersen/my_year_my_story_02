// widgets/monthly/day_entry_modal.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/services/calendar_event_service.dart';
import 'package:intl/intl.dart';


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
    if (text.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        tr("calendar.write_something_first"),
      ),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
  return;
}

    // 👤 GUEST → retorna dados
    if (user == null) {
      Navigator.pop(context, {
        'day': widget.day,
        'title': text,
        'color': _selectedColorHex,
      });
      return;
    }

    // 👤 LOGADO → salva no banco
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

  // Recarrega os eventos do dia
  await _loadEvents();

  if (!mounted) return;

  // 🔑 Se não sobrou nenhum evento, fecha o modal
  // avisando a tela de trás para atualizar o calendário
  if (_events.isEmpty) {
    Navigator.pop(context, true);
  }
}

  // ───────── UI ─────────
  @override
  Widget build(BuildContext context) {
    final user = SupabaseConfig.client.auth.currentUser;
     final date = DateTime(widget.year, widget.month, widget.day);

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
              color: const Color(0xFFFFF1F7).withOpacity(0.9),
  border: Border.all(
    color: Colors.white.withOpacity(0.4),
    width: 1,
            ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('d', context.locale.toString()).format(date),
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          DateFormat('MMM', context.locale.toString()).format(date),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          DateFormat('yyyy', context.locale.toString()).format(date),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      ],
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
                    initialValue: _hour,
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
                    onChanged: (v) =>
                        setState(() => _hour = v!),
                  ),

                  const SizedBox(height: 12),

	                  // TEXT
	                  TextField(
	                    controller: _textController,
	                    autocorrect: true,
	                    enableSuggestions: true,
	                    smartQuotesType: SmartQuotesType.enabled,
	                    smartDashesType: SmartDashesType.enabled,
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

                  // ALERT
                  SwitchListTile(
                    value: _hasAlert,
                    onChanged: (v) =>
                        setState(() => _hasAlert = v),
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

                  const SizedBox(height: 12),

                  // REPEAT
                  DropdownButtonFormField<String>(
                    initialValue: _repeatType,
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'none',
                        child:
                            Text(tr("calendar.repeat_none")),
                      ),
                      DropdownMenuItem(
                        value: 'daily',
                        child:
                            Text(tr("calendar.repeat_daily")),
                      ),
                      DropdownMenuItem(
                        value: 'weekly',
                        child:
                            Text(tr("calendar.repeat_weekly")),
                      ),
                      DropdownMenuItem(
                        value: 'monthly',
                        child:
                            Text(tr("calendar.repeat_monthly")),
                      ),
                      DropdownMenuItem(
                        value: 'yearly',
                        child:
                            Text(tr("calendar.repeat_yearly")),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _repeatType = v!),
                  ),

                  const SizedBox(height: 16),

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
                          const Icon(Icons.lock_outline,
                              size: 18),
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

                  const SizedBox(height: 20),

                  // EVENTS LIST (logado)
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
                              color: Color(int.parse(
                                  e['color'],
                                  radix: 16)),
                            ),
                            title: Text(e['title']),
                            subtitle: Text("${e['hour']}:00"),
                            trailing: IconButton(
                              icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent),
                              onPressed: () =>
                                  _deleteEvent(e['id']
                                      .toString()),
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
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE2377D),
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          tr("common.save"),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      const SizedBox(height: 8),

      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(
          tr("common.cancel"),
          style: const TextStyle(
            color: Color(0xFFE2377D),
            fontWeight: FontWeight.w600,
          ),
        ),
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
