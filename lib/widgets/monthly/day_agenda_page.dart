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
  State<DayAgendaPage> createState() => DayAgendaPageState();
}

class DayAgendaPageState extends State<DayAgendaPage> {
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

  Map<int, List<Map<String, dynamic>>> groupByHour() {
    final map = <int, List<Map<String, dynamic>>>{};
    for (final e in _entries) {
      final h = e['hour'] as int;
      map.putIfAbsent(h, () => []).add(e);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final date =
        DateTime(widget.year, widget.month, widget.day);
    final grouped = groupByHour();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat("dd MMMM", 'pt_BR').format(date),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: 16, // 7h → 22h
              itemBuilder: (context, index) {
                final hour = index + 7;
                final entries = grouped[hour] ?? [];

                return HourBlock(
                  hour: hour,
                  entries: entries,
                  onTapAdd: () {
                    openAddNote(hour);
                  },
                );
              },
            ),
    );
  }

  void openAddNote(int hour) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddNoteSheet(
        hour: hour,
        onSaved: () {
          Navigator.pop(context);
          _loadAgenda();
        },
        year: widget.year,
        month: widget.month,
        day: widget.day,
      ),
    );
  }
}

class HourBlock extends StatelessWidget {
  final int hour;
  final List<Map<String, dynamic>> entries;
  final VoidCallback onTapAdd;

  const HourBlock({
    super.key,
    required this.hour,
    required this.entries,
    required this.onTapAdd,
  });

  @override
  Widget build(BuildContext context) {
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
            "${hour.toString().padLeft(2, '0')}:00",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),

          if (entries.isEmpty)
            GestureDetector(
              onTap: onTapAdd,
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
              (e) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  "• ${e['note']}",
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
        ],
      ),
    );
  }
}class AddNoteSheet extends StatefulWidget {
  final int hour;
  final int year;
  final int month;
  final int day;
  final VoidCallback onSaved;

  const AddNoteSheet({
    super.key,
    required this.hour,
    required this.year,
    required this.month,
    required this.day,
    required this.onSaved,
  });

  @override
  State<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<AddNoteSheet> {
  final controller = TextEditingController();

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
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Escreva sua anotação…",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: () {
              // depois a gente conecta com o service
              widget.onSaved();
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }
}

