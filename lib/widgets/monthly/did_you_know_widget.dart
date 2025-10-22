import 'package:flutter/material.dart';
import '../../services/did_you_know_service.dart';
import 'monthly_page_template.dart';

class DidYouKnowWidget extends StatefulWidget {
  final int month;
  final int year;

  const DidYouKnowWidget({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<DidYouKnowWidget> createState() => _DidYouKnowWidgetState();
}

class _DidYouKnowWidgetState extends State<DidYouKnowWidget> {
  final DidYouKnowService _service = DidYouKnowService();
  List<Map<String, dynamic>> curiosities = [];
  bool isLoading = true;
  int refreshCount = 0;
  final int maxRefresh = 3;

  // 🎨 Paleta de cores para as categorias
  final List<Color> categoryColors = const [
    Color(0xFF7FA9D1), // azul sereno
    Color(0xFFD7C3EE), // lilás suave
    Color(0xFFD84A75), // rosa intenso
    Color(0xFFE78AC6), // rosa médio
    Color(0xFFCBA5E3), // lavanda
    Color(0xFFD8CA7D), // amarelo vintage
  ];

  // 🌷 Mensagens diferentes por mês
  final Map<int, String> monthMessages = {
    1: "✨ Janeiro é um recomeço — hora de abrir o coração e se encher de curiosidade pelo novo!",
    2: "💫 Fevereiro traz leveza, cor e descobertas curiosas que aquecem o coração.",
    3: "🌿 Março é tempo de crescer, aprender e se encantar com o que o mundo tem pra contar.",
    4: "🌸 Abril desperta a criatividade — prepare-se para curiosidades cheias de vida!",
    5: "🌼 Maio é doce e inspirador — perfeito pra descobrir algo que te faça sorrir.",
    6: "🌞 Junho vem com energia boa e histórias fascinantes esperando por você!",
    7: "🌻 Julho é o mês das surpresas — mergulhe nessas curiosidades e se inspire.",
    8: "🌺 Agosto convida à reflexão e à descoberta de coisas novas e inesperadas.",
    9: "🍂 Setembro é pura inspiração — pequenas curiosidades pra te fazer ver o mundo com outros olhos.",
    10: "🌕 Outubro vem com mistério e magia — perfeito pra explorar o desconhecido!",
    11: "🍁 Novembro é um lembrete: nunca é tarde pra aprender algo novo e se surpreender.",
    12: "🎇 Dezembro fecha o ano com brilho — curiosidades pra encerrar com leveza e encantamento.",
  };

  @override
  void initState() {
    super.initState();
    _loadCuriosities();
  }

  Future<void> _loadCuriosities() async {
    setState(() => isLoading = true);

    final data = await _service.fetchCuriosities(widget.month, widget.year);

    // 💫 Embaralha e mantém apenas 5 resultados
    final shuffled = List<Map<String, dynamic>>.from(data)..shuffle();
    final limited = shuffled.take(5).toList();

    setState(() {
      curiosities = limited;
      isLoading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    final message = monthMessages[widget.month] ??
        "✨ Curiosidades que inspiram e surpreendem!";

    return MonthlyPageTemplate(
      month: widget.month,
      year: widget.year,
      title: "Você Sabia?",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 🌸 Introdução personalizada
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.black87,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(color: Colors.pinkAccent),
              ),
            )
          else if (curiosities.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  "Sem curiosidades para este mês.",
                  style: TextStyle(fontSize: 18, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...curiosities.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final color =
              categoryColors[index % categoryColors.length]; // alterna cores

              // Categoria formatada com inicial maiúscula
              final category = (item['category'] != null &&
                  (item['category'] as String).isNotEmpty)
                  ? '${item['category'][0].toUpperCase()}${item['category'].substring(1)}'
                  : null;

              return Card(
                color: Colors.white,
                margin:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        item['content'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

          const SizedBox(height: 20),

          // 🔄 Botão de atualização
          Center(
            child: ElevatedButton.icon(
              onPressed: refreshCount < maxRefresh
                  ? () async {
                await _loadCuriosities();
                setState(() => refreshCount++);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✨ Novas curiosidades carregadas!"),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
                  : null,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(
                refreshCount < maxRefresh
                    ? "Atualizar curiosidades"
                    : "🌙 Volte amanhã para mais!",
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: refreshCount < maxRefresh
                    ? Colors.pinkAccent
                    : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
