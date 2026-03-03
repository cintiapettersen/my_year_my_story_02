import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/widgets/monthly/calender/day_agenda_service.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';


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

    if (user == null) {
      setState(() {
        _entries = [];
        _loading = false;
      });
      return;
    }

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

  @override
  Widget build(BuildContext context) {
    final date = DateTime(widget.year, widget.month, widget.day);

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
          : _entries.isEmpty
              ? Center(
                  child: Text(
                    tr("agenda.empty_day"),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final e = _entries[index];
                    final hour = e['hour'] as int;

                    return _AgendaItem(
                      hour: hour,
                      note: e['note'],
                      onTap: () {
                        final user =
                            SupabaseConfig.client.auth.currentUser;
                        if (user == null) {
                          showPremiumPopup(context);
                          return;
                        }

                        // 👉 aqui, no futuro:
                        // abrir o MODAL ÚNICO já preenchido
                      },
                    );
                  },
                ),
    );
  }
}

class _AgendaItem extends StatelessWidget {
  final int hour;
  final String note;
  final VoidCallback onTap;

  const _AgendaItem({
    required this.hour,
    required this.note,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            const SizedBox(height: 6),
            Text(
              note,
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
