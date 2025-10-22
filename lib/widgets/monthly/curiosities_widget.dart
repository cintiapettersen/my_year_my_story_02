import 'package:flutter/material.dart';
import 'package:my_year_my_story/widgets/shared/month_page_template.dart'; // 🌸 novo template
import 'package:my_year_my_story/supabase/supabase_config.dart';

class CuriositiesWidget extends StatefulWidget {
  final int month;
  final int year;

  const CuriositiesWidget({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<CuriositiesWidget> createState() => _CuriositiesWidgetState();
}

class _CuriositiesWidgetState extends State<CuriositiesWidget> {
  final List<TextEditingController> _controllers = [];
  List<String> _questions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _questions = _getQuestionsForMonth(widget.month);
    _controllers.addAll(
      List.generate(_questions.length, (_) => TextEditingController()),
    );
    _loadSavedData();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // 🔹 Perguntas por mês
  List<String> _getQuestionsForMonth(int month) {
    switch (month) {
      case 1:
        return [
          'Se você fosse um animal, qual seria?',
          'Qual seria o título do livro da sua vida?',
          'Um hábito que você gostaria de criar neste ano?',
          'Qual é o seu sabor de sorvete preferido?',
          'Se você tivesse um superpoder, qual seria?',
        ];
      case 2:
        return [
          'Qual personagem da Disney mais combina com você?',
          'Um momento recente que te fez sorrir?',
          'Qual seria o destino da sua viagem dos sonhos?',
          'Se sua vida fosse um filme, qual seria o gênero?',
          'Qual é a sua cor favorita e por quê?',
        ];
      case 3:
        return [
          'Qual música seria a trilha sonora da sua vida?',
          'Um talento secreto que quase ninguém sabe?',
          'Qual cheirinho te traz boas lembranças?',
          'Se você pudesse aprender algo novo agora, o que seria?',
          'Qual é a sua comida preferida de conforto?',
        ];
      case 4:
        return [
          'Qual é a sua estação do ano favorita?',
          'O que te faz sentir paz instantaneamente?',
          'Qual emoji te representa hoje?',
          'Se você pudesse mudar algo no mundo, o que seria?',
          'Qual é o seu passatempo ideal num domingo?',
        ];
      case 5:
        return [
          'Se você fosse uma flor, qual seria?',
          'Um elogio que marcou você?',
          'Qual foi o melhor presente que já recebeu?',
          'Qual é o seu lugar favorito no mundo?',
          'Que palavra resume o seu mês até agora?',
        ];
      case 6:
        return [
          'Quem é alguém que te inspira muito?',
          'Qual série ou filme você nunca se cansa de ver?',
          'Se tivesse um lema pessoal, qual seria?',
          'Um sabor que te lembra infância?',
          'Você prefere o nascer ou o pôr do sol?',
        ];
      case 7:
        return [
          'O que faz você se sentir confiante?',
          'Qual é o sonho que você ainda quer realizar?',
          'Se pudesse jantar com alguém famoso, quem seria?',
          'Qual é a sua comida favorita de festa?',
          'Qual foi a última vez que riu até chorar?',
        ];
      case 8:
        return [
          'Se você fosse uma cor, qual seria?',
          'Qual foi a coisa mais corajosa que já fez?',
          'Se pudesse voltar no tempo, pra onde iria?',
          'Qual frase te define melhor?',
          'O que faz um dia ser perfeito pra você?',
        ];
      case 9:
        return [
          'Qual é a sua estação do ano preferida?',
          'Se sua vida fosse um livro, qual seria o título do capítulo atual?',
          'O que te motiva a seguir em frente?',
          'Se fosse criar uma marca, qual seria o nome?',
          'Qual é o melhor conselho que já recebeu?',
        ];
      case 10:
        return [
          'Qual é o seu doce preferido?',
          'Se fosse um personagem de filme, quem seria?',
          'Um momento inesquecível da sua vida?',
          'Qual habilidade você gostaria de dominar?',
          'Como seria o seu dia ideal?',
        ];
      case 11:
        return [
          'O que faz você se sentir grata?',
          'Qual música te deixa instantaneamente feliz?',
          'Se fosse uma estação do ano, qual seria?',
          'Qual é a melhor parte das suas manhãs?',
          'Que pessoa famosa você adoraria conhecer?',
        ];
      case 12:
        return [
          'Qual é sua lembrança favorita do Natal?',
          'Se pudesse realizar um desejo agora, qual seria?',
          'O que você mais aprendeu este ano?',
          'Qual foi o momento mais especial de 2025 pra você?',
          'O que deseja para o próximo ano?',
        ];
      default:
        return [
          'Conte algo aleatório sobre você!',
          'Qual é seu maior sonho no momento?',
          'Um hábito que te faz bem?',
          'Qual música não sai da sua cabeça?',
          'Se você fosse um lugar, qual seria?',
        ];
    }
  }

  Future<void> _loadSavedData() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await SupabaseConfig.client
          .from('entries')
          .select('curiosities_answers')
          .eq('user_id', user.id)
          .eq('month', widget.month)
          .eq('year', widget.year)
          .maybeSingle();

      if (response != null && response['curiosities_answers'] != null) {
        final savedAnswers = List<String>.from(response['curiosities_answers']);
        for (int i = 0; i < _controllers.length; i++) {
          if (i < savedAnswers.length) {
            _controllers[i].text = savedAnswers[i];
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar respostas: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveData() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final currentAnswers = _controllers.map((c) => c.text.trim()).toList();

      await SupabaseConfig.client.from('entries').upsert({
        'user_id': user.id,
        'month': widget.month,
        'year': widget.year,
        'curiosities_answers': currentAnswers,
      }, onConflict: 'user_id,year,month');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Respostas salvas com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MonthPageTemplate(
      month: widget.month,
      year: widget.year,
      title: 'Curiosidades Aleatórias Sobre Mim',
      description: 'Colecione e reflita sobre tudo que você gosta, sente e se expressa... 🌸',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            ...List.generate(_questions.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _questions[index],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controllers[index],
                      decoration: InputDecoration(
                        hintText: 'Sua resposta',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                          BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveData,
                icon: const Icon(Icons.save),
                label: const Text('Salvar Respostas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
