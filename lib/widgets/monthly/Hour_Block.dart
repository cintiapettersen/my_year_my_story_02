import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/widgets/monthly/day_agenda_service.dart';

class DayAgendaPage extends StatefulWidget {
  final int year;
  final int month;
  final int day;

  const DayAgendaPage({
    super.key,
    required this.year,
    required this.month,
    required this.day,
  });

  @override
  State<DayAgendaPage> createState() => _DayAgendaPageState();
}

class _DayAgendaPageState extends State<DayAgendaPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadAgenda();
  }

  Future<void> _loadAgenda() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    final res = await DayAgendaService.getEntriesForDay(
      userId: user.id,
      year: widget.year,
      month: widget.month,
      day: widget.day,
    );

    setState(() {
      _entries = res;
      _loading = false;
    });
  }

  Map<int, List<Map<String, dynamic>>> _groupByHour() {
    final map = <int, List<Map<String, dynamic>>>{};
    for (final e in _entries) {
      final hour = e['hour'] as int;
      map.putIfAbsent(hour, () => []).add(e);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final date =
        DateTime(widget.year, widget.month, widget.day);
    final grouped = _groupByHour();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          DateFormat("dd MMMM", 'pt_BR').format(date),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: 16, // 07h → 22h
              itemBuilder: (context, index) {
                final hour = index + 7;
                final entries = grouped[hour] ?? [];

                return HourBlock(
                  hour: hour,
                  entries: entries,
                  onAdd: () => _openNoteSheet(hour),
                  onEdit: (e) => _openNoteSheet(hour, entry: e),
                  onDelete: (id) async {
                    await DayAgendaService.deleteEntry(entryId: id);
                    _loadAgenda();
                  },
                );
              },
            ),
    );
  }

  void _openNoteSheet(int hour, {Map<String, dynamic>? entry}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddEditNoteSheet(
        year: widget.year,
        month: widget.month,
        day: widget.day,
        hour: hour,
        entry: entry,
        onSaved: () {
          Navigator.pop(context);
          _loadAgenda();
        },
      ),
    );
  }
}

/// ------------------------------------------------------------
/// HOUR BLOCK
/// ------------------------------------------------------------
class HourBlock extends StatelessWidget {
  final int hour;
  final List<Map<String, dynamic>> entries;
  final VoidCallback onAdd;
  final Function(Map<String, dynamic>) onEdit;
  final Function(String entryId) onDelete;

  const HourBlock({
    required this.hour,
    required this.entries,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final label = "${hour.toString().padLeft(2, '0')}:00";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),

          if (entries.isEmpty)
            GestureDetector(
              onTap: onAdd,
              child: Text(
                "Toque para adicionar uma anotação",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          if (entries.isNotEmpty)
            ...entries.map(
              (e) => GestureDetector(
                onTap: () => onEdit(e),
                onLongPress: () => onDelete(e['id']),
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    "• ${e['note']}",
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// ADD / EDIT NOTE SHEET
/// ------------------------------------------------------------
class AddEditNoteSheet extends StatefulWidget {
  final int year;
  final int month;
  final int day;
  final int hour;
  final Map<String, dynamic>? entry;
  final VoidCallback onSaved;

  const AddEditNoteSheet({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    this.entry,
    required this.onSaved,
  });

  @override
  State<AddEditNoteSheet> createState() =>
      AddEditNoteSheetState();
}

class AddEditNoteSheetState extends State<AddEditNoteSheet> {
  late TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.entry?['note'] ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, padding + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "${widget.hour.toString().padLeft(2, '0')}:00",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Escreva sua anotação…",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const CircularProgressIndicator()
                : const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    setState(() => _saving = true);

    if (widget.entry == null) {
      await DayAgendaService.createEntry(
        userId: user.id,
        year: widget.year,
        month: widget.month,
        day: widget.day,
        hour: widget.hour,
        note: _controller.text.trim(),
      );
    } else {
      await DayAgendaService.updateEntry(
        entryId: widget.entry!['id'],
        hour: widget.hour,
        note: _controller.text.trim(),
      );
    }

    widget.onSaved();
  }
}
