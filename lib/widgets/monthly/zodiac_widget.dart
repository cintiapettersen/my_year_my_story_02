import 'package:flutter/material.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';



class ZodiacWidget extends StatefulWidget {
  final int month;
  final int year;

  const ZodiacWidget({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<ZodiacWidget> createState() => _ZodiacWidgetState();
}

class _ZodiacWidgetState extends State<ZodiacWidget> {
  bool _isLoading = false;

  Map<String, dynamic>? _todaySign;
  Map<String, dynamic>? _startSign;
  Map<String, dynamic>? _endSign;

  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _loadZodiacData();
    _loadEvents();
  }


  Future<void> _loadZodiacData() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final rows = await supabase.from('zodiac_signs').select('*');

      final now = DateTime.now();

      for (final row in rows) {
        final start = DateTime.parse(row['start_date']);
        final end = DateTime.parse(row['end_date']);

        if (!start.isAfter(now) && !end.isBefore(now)) {
          _todaySign = row;
        }
      }

      final monthStart = DateTime(widget.year, widget.month, 1);
      final monthEnd = DateTime(widget.year, widget.month + 1, 0);

      _startSign = rows.firstWhere(
        (r) {
          final s = DateTime.parse(r['start_date']);
          final e = DateTime.parse(r['end_date']);
          return !s.isAfter(monthStart) && !e.isBefore(monthStart);
        },
        orElse: () => {},
      );

      _endSign = rows.firstWhere(
        (r) {
          final s = DateTime.parse(r['start_date']);
          final e = DateTime.parse(r['end_date']);
          return !s.isAfter(monthEnd) && !e.isBefore(monthEnd);
        },
        orElse: () => {},
      );
    } catch (e) {
      debugPrint('Erro signos → $e');
    }

    setState(() => _isLoading = false);
  }



  Future<void> _loadEvents() async {
    final supabase = Supabase.instance.client;

    final rows = await supabase
        .from('zodiac_events')
        .select('*')
        .eq('month', widget.month)
        .eq('year', widget.year)
        .order('date');

    setState(() {
      _events = List<Map<String, dynamic>>.from(rows);
    });
  }

  Future<void> _deleteEvent(int id) async {
    final supabase = Supabase.instance.client;

    await supabase.from('zodiac_events').delete().eq('id', id);

    await _loadEvents();
  }

  Widget _zodiacCard(Map<String, dynamic> sign) {
    final isEN = context.locale.languageCode == 'en';

    final name = isEN ? sign['signo_en'] : sign['signo_pt'];
    final description = isEN ? sign['descricao_en'] : sign['descricao_pt'];
    final phrase = isEN ? sign['frase_en'] : sign['frase_pt'];
    final period = isEN ? sign['periodo_en'] : sign['periodo_pt'];

    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        color: const Color(0xFFF5DCEB).withOpacity(0.45),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF5DCEB), width: 2),
      ),
      child: Column(
        children: [
          Text(sign['emoji'] ?? '⭐', style: const TextStyle(fontSize: 60)),
          const SizedBox(height: 12),

          Text(
            name.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(period,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 15)),

          const SizedBox(height: 18),

          Text(description,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 15, height: 1.45)),

          const SizedBox(height: 28),

          _infoSlider(sign, isEN),

          const SizedBox(height: 32),

          Text(
            '“$phrase”',
            textAlign: TextAlign.center,
            style: GoogleFonts.satisfy(
              fontSize: 22,
              color: const Color(0xFF554587),
            ),
          ),
        ],
      ),
    );
  }


  Widget _infoSlider(Map<String, dynamic> sign, bool isEN) {
    final items = [
      {"label": "zodiac.color".tr(), "value": isEN ? sign['cor_en'] : sign['cor_pt']},
      {"label": "zodiac.number".tr(), "value": sign['numero']},
      {"label": "zodiac.element".tr(), "value": isEN ? sign['elemento_en'] : sign['elemento_pt']},
      {"label": "zodiac.stone".tr(), "value": isEN ? sign['pedra_en'] : sign['pedra_pt']},
      {"label": "zodiac.flower".tr(), "value": isEN ? sign['flor_en'] : sign['flor_pt']},
      {"label": "zodiac.ruler".tr(), "value": isEN ? sign['regente_en'] : sign['regente_pt']},
    ];

    return SizedBox(
      height: 130,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.75),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item['label']!,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text(item['value']!, textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  void _openEventsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('zodiac.events'.tr(),
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w700)),

              const SizedBox(height: 16),

              if (_events.isEmpty)
                Text('zodiac.no_events'.tr()),

              ..._events.map((e) {
                return ListTile(
                  title: Text(e['title']),
                  subtitle: Text(e['date']),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await _deleteEvent(e['id']);
                      Navigator.pop(context);
                      _openEventsModal();
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return MonthPageTemplate(
      month: widget.month,
      year: widget.year,
      title: '',
      pageLabel: 'zodiac.title'.tr(),
      labelColor: const Color.fromARGB(255, 141, 99, 195),
      description: 'zodiac.month_description'.tr(),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final isEN = context.locale.languageCode == 'en';

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 14),

          if (_todaySign != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                "${'zodiac.today_sign'.tr()}: ${isEN ? _todaySign!['signo_en'] : _todaySign!['signo_pt']}",
                style: GoogleFonts.poppins(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),

          if (_startSign != null && _startSign!.isNotEmpty)
            _zodiacCard(_startSign!),

          if (_endSign != null &&
              _endSign!.isNotEmpty &&
              _endSign!['id'] != _startSign!['id'])
            _zodiacCard(_endSign!),

          const SizedBox(height: 12),

          ElevatedButton(
            onPressed: _openEventsModal,
            child: Text('zodiac.open_events'.tr()),
          ),
        ],
      ),
    );
  }
}
