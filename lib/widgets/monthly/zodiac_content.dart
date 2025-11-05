import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ZodiacContent extends StatefulWidget {
  final int month;

  const ZodiacContent({super.key, required this.month});

  @override
  State<ZodiacContent> createState() => _ZodiacContentState();
}

class _ZodiacContentState extends State<ZodiacContent> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _signs = [];

  @override
  void initState() {
    super.initState();
    _fetchZodiacSigns();
  }

  Future<void> _fetchZodiacSigns() async {
    try {
      final now = DateTime.now();
      final zodiacName = _getZodiacSign(now);

      final response = await Supabase.instance.client
          .from('zodiac_signs')
          .select()
          .eq('nome', zodiacName)
          .order('nome', ascending: true);

      setState(() {
        _signs = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Erro ao buscar signos: $error');
      setState(() => _isLoading = false);
    }
  }

  String _getZodiacSign(DateTime date) {
    int day = date.day;
    int month = date.month;

    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return 'Áries';
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return 'Touro';
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return 'Gêmeos';
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return 'Câncer';
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return 'Leão';
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return 'Virgem';
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return 'Libra';
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return 'Escorpião';
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return 'Sagitário';
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return 'Capricórnio';
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return 'Aquário';
    return 'Peixes';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_signs.isEmpty) {
      return const Center(child: Text('Nenhum signo encontrado.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: _signs.map((s) => _ZodiacCard(sign: s)).toList(),
      ),
    );
  }
}

class _ZodiacCard extends StatelessWidget {
  final Map<String, dynamic> sign;

  const _ZodiacCard({required this.sign});

  @override
  Widget build(BuildContext context) {
    final cor = _extractColor(sign['cor']);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(sign['emoji'] ?? '', style: const TextStyle(fontSize: 50)),
          const SizedBox(height: 10),
          Text(
            sign['nome'] ?? '',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sign['periodo'] ?? '',
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Divider(color: cor.withOpacity(0.4)),
          const SizedBox(height: 8),
          _detailLine('Elemento', sign['elemento']),
          _detailLine('Regente', sign['regente']),
          _detailLine('Cor', sign['cor']),
          _detailLine('Pedra', sign['pedra']),
          _detailLine('Número', sign['numero']),
          _detailLine('Flor', sign['flor']),
          _detailLine('Palavra-chave', sign['palavra_chave']),
          const SizedBox(height: 12),
          if (sign['descricao'] != null && sign['descricao'].toString().isNotEmpty)
            Text(
              sign['descricao'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailLine(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(value.toString(), style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }

  Color _extractColor(String? corTexto) {
    if (corTexto == null) return Colors.indigo;
    final cor = corTexto.toLowerCase();
    if (cor.contains('vermelho')) return Colors.red;
    if (cor.contains('laranja')) return Colors.orange;
    if (cor.contains('amarelo')) return Colors.amber;
    if (cor.contains('verde')) return Colors.green;
    if (cor.contains('azul')) return Colors.blue;
    if (cor.contains('roxo')) return Colors.purple;
    if (cor.contains('rosa')) return Colors.pink;
    if (cor.contains('cinza')) return Colors.grey;
    if (cor.contains('branco')) return Colors.white;
    if (cor.contains('dourado')) return const Color(0xFFFFD700);
    if (cor.contains('prateado') || cor.contains('prata')) return const Color(0xFFC0C0C0);
    return Colors.indigo;
  }
}
