import 'package:flutter/material.dart';
import 'package:my_year_my_story/widgets/shared/month_header.dart';
import 'package:my_year_my_story/widgets/monthly/zodiac_content.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ZodiacWidget extends StatefulWidget {
  final int? month;
  final int? year;

  const ZodiacWidget({
    super.key,
    this.month,
    this.year,
  });

  @override
  State<ZodiacWidget> createState() => _ZodiacWidgetState();
}

class _ZodiacWidgetState extends State<ZodiacWidget> {
  String? _descricaoMes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDescricaoMes();
  }

  Future<void> _fetchDescricaoMes() async {
    try {
      final mesSelecionado = widget.month ?? DateTime.now().month;

      final response = await Supabase.instance.client
          .from('zodiac_signs')
          .select('descricao_mes')
          .eq('mes', mesSelecionado)
          .maybeSingle();

      setState(() {
        _descricaoMes = response?['descricao_mes'];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao buscar descricao_mes: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = widget.month ?? DateTime.now().month;
    final selectedYear = widget.year ?? DateTime.now().year;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MonthHeader(
            month: selectedMonth,
            year: selectedYear,
            title: 'Signos do Mês',
          ),
          if (!_isLoading && _descricaoMes != null && _descricaoMes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Text(
                _descricaoMes!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: Colors.black54,
                  height: 1.6,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ZodiacContent(month: selectedMonth),
          ),
        ],
      ),
    );
  }
}
