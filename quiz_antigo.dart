import 'package:flutter/material.dart';
import 'package:my_year_my_story/supabase/supabase_config.dart';
import 'package:my_year_my_story/widgets/monthly/monthly_page_template.dart';
import 'dart:math';


class InteractiveQuizWidget extends StatefulWidget {
  final int? month;
  final int? year;

  const InteractiveQuizWidget({super.key, this.month, this.year});

  @override
  State<InteractiveQuizWidget> createState() => _InteractiveQuizWidgetState();
}

class _InteractiveQuizWidgetState extends State<InteractiveQuizWidget> {
  final _supabase = SupabaseConfig.client;
  bool _isLoading = false;
  bool _isSaving = false;

  late int _month;
  late int _year;

  Map<int, Map<String, dynamic>> _quizAnswers = {};
  String finalResult = '';
  String? _savedResult; // ✅ adiciona aqui!


  Future<void> _calculateResult() async {
    final counts = <String, int>{};
    for (var answer in _quizAnswers.values.map((a) => a['tipo'])) {
      counts[answer] = (counts[answer] ?? 0) + 1;
    }


    final maxCount = counts.values.reduce((a, b) => a > b ? a : b);
    final dominantTypes = counts.entries
        .where((e) => e.value == maxCount)
        .map((e) => e.key)
        .toList();

    // ✨ mensagens fofas pra empates
    final tieMessages = [
      "✨ Difícil te definir, porque você é muitas coisas lindas ao mesmo tempo 💕",
      "🌸 Você é um mix único — cheio(a) de cores, ideias e jeitos de ser ✨",
      "💫 Não dá pra escolher só um tipo... você é um universo inteiro de possibilidades 💖",
    ];

    final random = Random();

    // 💫 Mostra um dialog “calculando seu resultado...”
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(color: Color(0xFFE18B50)),
                SizedBox(height: 16),
                Text(
                  "Calculando seu resultado...",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: Color(0xFF4F4F4F),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // ⏳ aguarda 2 segundos pra dar aquele suspense
    await Future.delayed(const Duration(seconds: 2));

    Navigator.of(context, rootNavigator: true).pop(); // fecha só o dialog sem sair da tela


    final quizData = _getQuizData(_month);

// Encontra o resultado correspondente
    Map<String, dynamic>? matchedResult;
    if (dominantTypes.length == 1) {
      matchedResult = quizData['results'].firstWhere(
            (r) => r['title'].toLowerCase().contains(dominantTypes.first.toLowerCase()),
        orElse: () => {},
      );
    }

    setState(() {
      if (dominantTypes.length > 1) {
        finalResult = tieMessages[random.nextInt(tieMessages.length)];
      } else if (matchedResult != null && matchedResult.isNotEmpty) {
        finalResult = "💖 ${matchedResult['title']} 💖\n\n${matchedResult['desc']}";
      } else {
        finalResult = "✨ Seu resultado é: ${dominantTypes.first} 🎉";
      }
    });


// Mostra o popup com o resultado
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                " Resultado",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE91E63),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                finalResult,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: Color(0xFF4F4F4F),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Fechar"),
              ),
            ],
          ),
        ),
      ),
    );

  }

  Future<void> _saveResultToSupabase(String result) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Cria o JSON bonitinho pra guardar
      final quizJson = {
        'result': result,
        'saved_at': DateTime.now().toIso8601String(),
      };

      Future<void> _saveResultToSupabase(String result) async {
        try {
          final user = _supabase.auth.currentUser;
          if (user == null) return;

          // Cria o JSON bonitinho pra guardar
          final quizJson = {
            'result': result,
            'saved_at': DateTime.now().toIso8601String(),
          };

          // Verifica se já existe o registro do mês atual
          final existing = await _supabase
              .from('entries')
              .select('id')
              .eq('user_id', user.id)
              .eq('month', _month)
              .eq('year', _year)
              .maybeSingle();

          if (existing == null) {
            // Cria novo registro
            await _supabase.from('entries').insert({
              'user_id': user.id,
              'month': _month,
              'year': _year,
              'quiz_data': quizJson,
            });
          } else {
            // Atualiza o registro existente
            await _supabase
                .from('entries')
                .update({'quiz_data': quizJson})
                .eq('id', existing['id']);
          }

          setState(() {
            _savedResult = result;
          });
        } catch (e) {
          debugPrint('Erro ao salvar quiz: $e');
        }
      }

// 👇 Adiciona logo aqui o carregamento do resultado salvo:
      Future<void> _loadSavedResult() async {
        try {
          final user = _supabase.auth.currentUser;
          if (user == null) return;

          final response = await _supabase
              .from('entries')
              .select('quiz_data')
              .eq('user_id', user.id)
              .eq('month', _month)
              .eq('year', _year)
              .maybeSingle();

          if (response != null && response['quiz_data'] != null) {
            final quizData = response['quiz_data'];
            setState(() {
              _savedResult = quizData['result'];
            });
          }
        } catch (e) {
          debugPrint('Erro ao carregar quiz salvo: $e');
        }
      }

      // Verifica se já existe o registro do mês atual
      final existing = await _supabase
          .from('entries')
          .select('id')
          .eq('user_id', user.id)
          .eq('month', _month)
          .eq('year', _year)
          .maybeSingle();

      if (existing == null) {
        // Cria novo registro (primeira vez do mês)
        await _supabase.from('entries').insert({
          'user_id': user.id,
          'month': _month,
          'year': _year,
          'quiz_data': quizJson,
        });
      } else {
        // Atualiza o registro existente
        await _supabase.from('entries').update({
          'quiz_data': quizJson,
        }).eq('id', existing['id']);
      }

      setState(() {
        _savedResult = result;
      });
    } catch (e) {
      debugPrint('Erro ao salvar quiz: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = widget.month ?? now.month;
    _year = widget.year ?? now.year;
    _loadSavedData();
  }

  void _loadSavedData() {
    // TODO: implementar carregamento do Supabase (opcional futuramente)
  }

  @override
  Widget build(BuildContext context) {
    final quizData = _getQuizData(_month);

    return MonthlyPageTemplate(
      month: _month,
      year: _year,
      title: quizData['title'],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          ..._buildQuizQuestions(quizData['questions']),
          const SizedBox(height: 40),

          // 👇 Novo botão "Ver resultado"
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE18B50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _calculateResult,
              child: const Text(
                "Ver resultado ✨",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );


  }

  List<Widget> _buildQuizQuestions(List<dynamic> questions) {
    return List.generate(questions.length, (index) {
      final q = questions[index];
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              q['q'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(q['a'].length, (i) {
              final a = q['a'][i];
              return RadioListTile<String>(
                value: a['tipo'],
                groupValue: _quizAnswers[index]?['tipo'],
                onChanged: (val) {
                  setState(() {
                    _quizAnswers[index] = {
                      'tipo': val,
                      'text': a['text'],
                    };
                  });
                },
                title: Text(
                  a['text'],
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
                activeColor: Color(0xFFE18B50),
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      );
    });
  }

  Widget _buildQuizResult(List<dynamic> results) {
    if (_quizAnswers.isEmpty) {
      return const SizedBox();
    }

    final counts = <String, int>{};
    for (var ans in _quizAnswers.values) {
      counts[ans['tipo']] = (counts[ans['tipo']] ?? 0) + 1;
    }

    final dominantType = counts.entries.reduce(
          (a, b) => a.value >= b.value ? a : b,
    ).key;

    final result = results.firstWhere(
          (r) => r['title'].toLowerCase().contains(dominantType.toLowerCase()),
      orElse: () => <String, String>{
        'title': 'Resultado Padrão',
        'desc': 'Não encontramos um resultado específico para você. 😉',
      },
    );



    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            result['emoji'],
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            result['title'],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE18B50),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            result['desc'],
            style: const TextStyle(fontSize: 16, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  }

  Map<String, dynamic> _getQuizData(int month) {
    final quizzes = {
      // 👇 Aqui entram todos os quizzes mensais (de janeiro a dezembro)
      // Exemplo:
      1: {
        'title': 'Descubra sua Super Habilidade 💫',
        'description': 'Vamos ver qual talento seu brilha mais!',
        'questions': [
          {
            'q': 'Quando surge um problema inesperado...',
            'a': [
              {'text': 'Penso com calma antes de agir.', 'tipo': 'racional'},
              {'text': 'Sigo o coração e confio no instinto.', 'tipo': 'emocional'},
              {'text': 'Procuro uma solução criativa.', 'tipo': 'criativa'},
              {'text': 'Analiso o que já deu certo antes.', 'tipo': 'conservadora'},
            ],
          },
        ],
        'results': [
          {
            'emoji': '🧠',
            'title': 'Racional',
            'desc': 'Você pensa antes de agir e sempre encontra a melhor saída!',
          },
          {
            'emoji': '💖',
            'title': 'Emocional',
            'desc': 'Você confia nas emoções e se conecta com as pessoas facilmente.',
          },
          {
            'emoji': '🎨',
            'title': 'Criativa',
            'desc': 'Sua imaginação é o motor que move suas ideias.',
          },
          {
            'emoji': '🌿',
            'title': 'Conservadora',
            'desc': 'Você valoriza estabilidade e gosta de manter tradições.',
          },
        ],
      },
      // ... (demais meses seguem aqui)
      // ===== MÊS 2 =====
      2: {
        'title': 'Como Você Enfrenta Desafios? 💪',
        'description': 'Descubra seu jeito de lidar com situações difíceis e o que te faz continuar mesmo quando as coisas não saem como o esperado.',
        'questions': [
          {
            'q': 'Quando algo dá errado, o que você faz primeiro?',
            'a': [
              {'text': 'Procuro entender o que aconteceu e planejar de novo', 'tipo': 'analítica'},
              {'text': 'Fico chateada, mas logo busco uma solução', 'tipo': 'resiliente'},
              {'text': 'Peço ajuda e converso com alguém de confiança', 'tipo': 'colaborativa'},
              {'text': 'Transformo o problema em uma ideia nova', 'tipo': 'criativa'},
            ],
          },
          {
            'q': 'Quando alguém duvida de você...',
            'a': [
              {'text': 'Prova com resultados', 'tipo': 'analítica'},
              {'text': 'Se motiva ainda mais', 'tipo': 'resiliente'},
              {'text': 'Mostra que pode sim, com calma e confiança', 'tipo': 'colaborativa'},
              {'text': 'Dá um jeito diferente de mostrar seu valor', 'tipo': 'criativa'},
            ],
          },
          {
            'q': 'O que te ajuda a seguir em frente?',
            'a': [
              {'text': 'Fazer um plano detalhado e prático', 'tipo': 'analítica'},
              {'text': 'Pensar que tudo passa e eu consigo', 'tipo': 'resiliente'},
              {'text': 'Conversar e ouvir palavras de apoio', 'tipo': 'colaborativa'},
              {'text': 'Criar algo bonito pra me inspirar de novo', 'tipo': 'criativa'},
            ],
          },
          {
            'q': 'Como você reage ao fracasso?',
            'a': [
              {'text': 'Analiso o que deu errado e aprendo', 'tipo': 'analítica'},
              {'text': 'Tento de novo, de outro jeito', 'tipo': 'resiliente'},
              {'text': 'Aceito e me conforto com quem me apoia', 'tipo': 'colaborativa'},
              {'text': 'Penso em algo novo pra transformar a situação', 'tipo': 'criativa'},
            ],
          },
          {
            'q': 'O que o desafio te ensina?',
            'a': [
              {'text': 'Que planejar é essencial', 'tipo': 'analítica'},
              {'text': 'Que desistir não é opção', 'tipo': 'resiliente'},
              {'text': 'Que ter apoio é fundamental', 'tipo': 'colaborativa'},
              {'text': 'Que a criatividade sempre ajuda', 'tipo': 'criativa'},
            ],
          },
        ],
        'results': [
          {
            'emoji': '🧩',
            'title': 'Analítica',
            'desc': 'Você enfrenta desafios com estratégia e lógica. Gosta de entender o que deu errado e encontrar uma solução inteligente.'
          },
          {
            'emoji': '🔥',
            'title': 'Resiliente',
            'desc': 'Nada te derruba por muito tempo. Você sente, mas se levanta e tenta de novo — sempre mais forte.'
          },
          {
            'emoji': '💞',
            'title': 'Colaborativa',
            'desc': 'Você encontra força nas conexões. Saber que tem com quem contar te dá coragem pra seguir.'
          },
          {
            'emoji': '🎨',
            'title': 'Criativa',
            'desc': 'Você transforma obstáculos em inspiração. Sempre acha um novo jeito de recomeçar.'
          },
        ],
      },

// ===== MÊS 3 =====
      3: {
        'title': 'O Que Te Faz Brilhar? ✨',
        'description': 'Descubra o que desperta o seu brilho interior e como você se destaca naturalmente.',
        'questions': [
          {
            'q': 'Quando você se sente mais confiante?',
            'a': [
              {'text': 'Quando tudo está sob controle', 'tipo': 'organizada'},
              {'text': 'Quando posso ser eu mesma', 'tipo': 'autêntica'},
              {'text': 'Quando estou rodeada de pessoas queridas', 'tipo': 'social'},
              {'text': 'Quando faço algo criativo', 'tipo': 'inspirada'},
            ],
          },
          {
            'q': 'Qual elogio te deixa mais feliz?',
            'a': [
              {'text': '“Você é muito responsável”', 'tipo': 'organizada'},
              {'text': '“Adoro sua energia!”', 'tipo': 'autêntica'},
              {'text': '“Você alegra todo mundo”', 'tipo': 'social'},
              {'text': '“Que ideia incrível!”', 'tipo': 'inspirada'},
            ],
          },
          {
            'q': 'Se pudesse escolher um símbolo pra você, seria...',
            'a': [
              {'text': 'Um cristal reluzente', 'tipo': 'organizada'},
              {'text': 'Um sol radiante', 'tipo': 'autêntica'},
              {'text': 'Um coração brilhante', 'tipo': 'social'},
              {'text': 'Uma estrela colorida', 'tipo': 'inspirada'},
            ],
          },
          {
            'q': 'O que te faz sentir que valeu o dia?',
            'a': [
              {'text': 'Cumprir tudo o que planejei', 'tipo': 'organizada'},
              {'text': 'Sentir que fui verdadeira comigo', 'tipo': 'autêntica'},
              {'text': 'Ver alguém sorrir por minha causa', 'tipo': 'social'},
              {'text': 'Criar ou imaginar algo novo', 'tipo': 'inspirada'},
            ],
          },
          {
            'q': 'Seu brilho vem de...',
            'a': [
              {'text': 'Fazer tudo com dedicação', 'tipo': 'organizada'},
              {'text': 'Ser quem eu sou, sem medo', 'tipo': 'autêntica'},
              {'text': 'Levar alegria pros outros', 'tipo': 'social'},
              {'text': 'Ver beleza em tudo', 'tipo': 'inspirada'},
            ],
          },
        ],
        'results': [
          {
            'emoji': '💎',
            'title': 'Organizada',
            'desc': 'Você brilha com disciplina e foco. O seu segredo é transformar esforço em resultados.'
          },
          {
            'emoji': '🌞',
            'title': 'Autêntica',
            'desc': 'Seu brilho é natural. Você encanta sendo você, com coragem e verdade.'
          },
          {
            'emoji': '🌈',
            'title': 'Social',
            'desc': 'Você ilumina os outros com sua presença. Seu brilho está em espalhar alegria e boas energias.'
          },
          {
            'emoji': '🎨',
            'title': 'Inspirada',
            'desc': 'Sua luz vem da imaginação. Tudo o que você toca ganha cor e significado.'
          },
        ],
      },

// ===== MÊS 4 =====
      4: {
        'title': 'Qual é o Seu Jeito de Cuidar das Pessoas? 💕',
        'description': 'Cuidar é uma forma de amar. Descubra como você demonstra carinho e apoio para quem está ao seu redor.',
        'questions': [
          {
            'q': 'Quando alguém que você gosta está triste, o que você faz?',
            'a': [
              {'text': 'Dá um abraço e fica junto em silêncio', 'tipo': 'acolhedora'},
              {'text': 'Faz de tudo pra animar a pessoa', 'tipo': 'divertida'},
              {'text': 'Escuta e tenta aconselhar', 'tipo': 'racional'},
              {'text': 'Escreve ou cria algo bonito pra confortar', 'tipo': 'criativa'},
            ],
          },
          {
            'q': 'Como você demonstra carinho no dia a dia?',
            'a': [
              {'text': 'Com palavras gentis', 'tipo': 'racional'},
              {'text': 'Com gestos e surpresas fofas', 'tipo': 'criativa'},
              {'text': 'Com presença e companhia', 'tipo': 'acolhedora'},
              {'text': 'Com brincadeiras e leveza', 'tipo': 'divertida'},
            ],
          },
          {
            'q': 'O que você faz quando alguém precisa de ajuda?',
            'a': [
              {'text': 'Escuta e dá conselhos práticos', 'tipo': 'racional'},
              {'text': 'Fica ao lado e mostra apoio', 'tipo': 'acolhedora'},
              {'text': 'Procura arrancar um sorriso', 'tipo': 'divertida'},
              {'text': 'Pensa em um jeito criativo de resolver', 'tipo': 'criativa'},
            ],
          },
          {
            'q': 'O que é cuidar pra você?',
            'a': [
              {'text': 'Dar amor e atenção', 'tipo': 'acolhedora'},
              {'text': 'Fazer rir mesmo nos dias ruins', 'tipo': 'divertida'},
              {'text': 'Ajudar com sabedoria e calma', 'tipo': 'racional'},
              {'text': 'Criar momentos especiais', 'tipo': 'criativa'},
            ],
          },
          {
            'q': 'Quem você mais gosta de cuidar?',
            'a': [
              {'text': 'Das pessoas da minha família', 'tipo': 'acolhedora'},
              {'text': 'Dos meus amigos', 'tipo': 'divertida'},
              {'text': 'De quem precisa de conselhos', 'tipo': 'racional'},
              {'text': 'De quem me inspira e me motiva', 'tipo': 'criativa'},
            ],
          },
        ],
        'results': [
          {
            'emoji': '💞',
            'title': 'Acolhedora',
            'desc': 'Você cuida com presença e carinho. Estar ao seu lado é sentir-se seguro e amado.'
          },
          {
            'emoji': '🌸',
            'title': 'Divertida',
            'desc': 'Você faz o outro esquecer os problemas. Seu cuidado vem em forma de sorrisos e leveza.'
          },
          {
            'emoji': '🧠',
            'title': 'Racional',
            'desc': 'Você cuida com sabedoria e calma. Sabe o que dizer na hora certa e transmite segurança.'
          },
          {
            'emoji': '🎁',
            'title': 'Criativa',
            'desc': 'Seu jeito de cuidar é cheio de surpresas e detalhes. Você transforma carinho em arte.'
          },
        ],
      },


// ===== MÊS 5 =====
      5: {
        'title': 'Como Você Espalha Alegria? ☀️',
        'description': 'Descubra como o seu jeito deixa o dia das pessoas mais leve e colorido.',
        'questions': [
          {
            'q': 'O que você faz quando alguém está desanimado?',
            'a': [
              {'text': 'Conto algo engraçado', 'tipo': 'divertida'},
              {'text': 'Digo algo motivador', 'tipo': 'inspiradora'},
              {'text': 'Faço companhia e deixo a pessoa à vontade', 'tipo': 'acolhedora'},
              {'text': 'Crio uma surpresa ou gesto carinhoso', 'tipo': 'criativa'},
            ],
          },
          {
            'q': 'Como você costuma animar um grupo?',
            'a': [
              {'text': 'Com piadas e brincadeiras', 'tipo': 'divertida'},
              {'text': 'Com palavras e energia positiva', 'tipo': 'inspiradora'},
              {'text': 'Fazendo todos se sentirem incluídos', 'tipo': 'acolhedora'},
              {'text': 'Com ideias diferentes e inesperadas', 'tipo': 'criativa'},
            ],
          },
          {
            'q': 'O que te deixa feliz instantaneamente?',
            'a': [
              {'text': 'Ver alguém sorrindo por minha causa', 'tipo': 'acolhedora'},
              {'text': 'Ouvir uma boa música', 'tipo': 'divertida'},
              {'text': 'Ter uma boa conversa', 'tipo': 'inspiradora'},
              {'text': 'Fazer algo artístico', 'tipo': 'criativa'},
            ],
          },
          {
            'q': 'Como você reage a um dia ruim?',
            'a': [
              {'text': 'Procuro rir da situação', 'tipo': 'divertida'},
              {'text': 'Penso que amanhã será melhor', 'tipo': 'inspiradora'},
              {'text': 'Converso com alguém que gosto', 'tipo': 'acolhedora'},
              {'text': 'Crio algo novo pra aliviar a mente', 'tipo': 'criativa'},
            ],
          },
          {
            'q': 'Alegrar alguém é...',
            'a': [
              {'text': 'Mostrar que rir é um ótimo remédio', 'tipo': 'divertida'},
              {'text': 'Espalhar esperança e energia boa', 'tipo': 'inspiradora'},
              {'text': 'Oferecer conforto e empatia', 'tipo': 'acolhedora'},
              {'text': 'Criar momentos únicos e leves', 'tipo': 'criativa'},
            ],
          },
        ],
        'results': [
          {
            'emoji': '😂',
            'title': 'Divertida',
            'desc': 'Você alegra o ambiente com bom humor e leveza. Sua risada é contagiante!'
          },
          {
            'emoji': '💫',
            'title': 'Inspiradora',
            'desc': 'Você motiva e encoraja. Sua alegria vem de dentro e se espalha naturalmente.'
          },
          {
            'emoji': '💛',
            'title': 'Acolhedora',
            'desc': 'Você traz conforto e empatia. As pessoas se sentem bem só de estar perto.'
          },
          {
            'emoji': '🎈',
            'title': 'Criativa',
            'desc': 'Você inventa jeitos únicos de fazer os outros sorrirem. Alegria pra você é arte!'
          },
        ],
      },

// ===== MÊS 6 =====
      6: {
        'title': 'O Que Te Motiva a Continuar? 🌱',
        'description': 'Descubra de onde vem sua força quando a vida pede mais paciência e coragem.',
        'questions': [
          {
            'q': 'Quando pensa em desistir, o que te faz seguir?',
            'a': [
              {'text': 'Pensar nas pessoas que amo', 'tipo': 'emocional'},
              {'text': 'Lembrar do meu objetivo final', 'tipo': 'racional'},
              {'text': 'Acreditar que tudo acontece por um motivo', 'tipo': 'sonhadora'},
              {'text': 'Criar novas formas de tentar', 'tipo': 'criativa'},
            ],
          },
          {
            'q': 'O que te inspira a levantar todos os dias?',
            'a': [
              {'text': 'As pessoas que me apoiam', 'tipo': 'emocional'},
              {'text': 'Minhas metas e responsabilidades', 'tipo': 'racional'},
              {'text': 'Meus sonhos e esperanças', 'tipo': 'sonhadora'},
              {'text': 'A possibilidade de algo novo', 'tipo': 'criativa'},
            ],
          },
          {
            'q': 'Como você reage diante de um obstáculo?',
            'a': [
              {'text': 'Penso em quem depende de mim', 'tipo': 'emocional'},
              {'text': 'Busco soluções práticas', 'tipo': 'racional'},
              {'text': 'Tento ver o lado bom da situação', 'tipo': 'sonhadora'},
              {'text': 'Uso a criatividade pra contornar o problema', 'tipo': 'criativa'},
            ],
          },
          {
            'q': 'O que te dá sensação de conquista?',
            'a': [
              {'text': 'Ver alguém orgulhoso de mim', 'tipo': 'emocional'},
              {'text': 'Cumprir o que prometi', 'tipo': 'racional'},
              {'text': 'Perceber o quanto cresci', 'tipo': 'sonhadora'},
              {'text': 'Transformar algo simples em especial', 'tipo': 'criativa'},
            ],
          },
          {
            'q': 'Quando algo é difícil...',
            'a': [
              {'text': 'Eu me lembro do amor que me sustenta', 'tipo': 'emocional'},
              {'text': 'Eu foco na lógica e sigo firme', 'tipo': 'racional'},
              {'text': 'Eu acredito que tudo tem um propósito', 'tipo': 'sonhadora'},
              {'text': 'Eu busco uma saída criativa', 'tipo': 'criativa'},
            ],
          },
        ],
        'results': [
          {
            'emoji': '💖',
            'title': 'Emocional',
            'desc': 'Você se move pelo amor e pela conexão. São as pessoas e sentimentos que te impulsionam.'
          },
          {
            'emoji': '⚙️',
            'title': 'Racional',
            'desc': 'Sua força está no foco e na lógica. Você segue firme até alcançar o que quer.'
          },
          {
            'emoji': '🌙',
            'title': 'Sonhadora',
            'desc': 'Você acredita em recomeços e no poder das boas intenções. Sua esperança é o que te guia.'
          },
          {
            'emoji': '🎨',
            'title': 'Criativa',
            'desc': 'Você se renova com ideias e imaginação. Enxerga caminhos mesmo quando ninguém mais vê.'
          },
        ],
      },
// ===== MÊS 7 =====
      7: {
        'title': 'O Que Te Motiva a Continuar? 🌻',
        'description': 'Descubra o que te dá força quando precisa seguir em frente — mesmo quando parece difícil.',
        'questions': [
          {
            'q': 'O que te faz levantar da cama nos dias difíceis?',
            'a': [
              {'text': 'Lembrar que cada dia é uma nova chance', 'tipo': 'esperançosa'},
              {'text': 'Pensar nas pessoas que amo', 'tipo': 'emocional'},
              {'text': 'Planejar algo que quero muito', 'tipo': 'determinada'},
              {'text': 'Ouvir uma música que me anima', 'tipo': 'leve'},
            ],
          },
          {
            'q': 'Quando algo dá errado...',
            'a': [
              {'text': 'Eu busco o lado bom da situação', 'tipo': 'esperançosa'},
              {'text': 'Eu me apoio nas pessoas certas', 'tipo': 'emocional'},
              {'text': 'Eu traço outro plano e sigo', 'tipo': 'determinada'},
              {'text': 'Eu respiro fundo e deixo fluir', 'tipo': 'leve'},
            ],
          },
          {
            'q': 'O que te dá energia?',
            'a': [
              {'text': 'Acreditar que as coisas vão melhorar', 'tipo': 'esperançosa'},
              {'text': 'O amor das pessoas à minha volta', 'tipo': 'emocional'},
              {'text': 'A sensação de estar no controle', 'tipo': 'determinada'},
              {'text': 'Fazer algo simples e prazeroso', 'tipo': 'leve'},
            ],
          },
          {
            'q': 'O que te ajuda a recomeçar?',
            'a': [
              {'text': 'Ver o que já conquistei', 'tipo': 'determinada'},
              {'text': 'Ter fé de que o futuro será melhor', 'tipo': 'esperançosa'},
              {'text': 'Conversar com quem me entende', 'tipo': 'emocional'},
              {'text': 'Fazer algo que me acalma', 'tipo': 'leve'},
            ],
          },
          {
            'q': 'Você continua porque...',
            'a': [
              {'text': 'Acredita que tudo tem um propósito', 'tipo': 'esperançosa'},
              {'text': 'Ama com intensidade', 'tipo': 'emocional'},
              {'text': 'Quer ver seus sonhos realizados', 'tipo': 'determinada'},
              {'text': 'Sabe que o tempo cura tudo', 'tipo': 'leve'},
            ],
          },
        ],
        'results': [
          {
            'emoji': '🌱',
            'title': 'Esperançosa',
            'desc': 'Você segue acreditando, mesmo quando tudo parece incerto. Sua força vem da fé e da esperança.'
          },
          {
            'emoji': '💖',
            'title': 'Emocional',
            'desc': 'O amor te move. Você se apoia nas conexões e nas pessoas que fazem tudo valer a pena.'
          },
          {
            'emoji': '⚡️',
            'title': 'Determinada',
            'desc': 'Você não desiste fácil. Quando quer algo, vai até o fim — e aprende muito no caminho.'
          },
          {
            'emoji': '☁️',
            'title': 'Leve',
            'desc': 'Você segue com calma e otimismo. Acredita que tudo se ajeita e que recomeçar também é crescer.'
          },
        ],
      },

// ===== MÊS 8 =====
      8: {
        'title': 'Como Você Lida com Mudanças? 🍃',
        'description': 'As mudanças fazem parte da vida. Descubra como você reage quando o novo aparece no seu caminho.',
        'questions': [
          {
            'q': 'Quando algo inesperado acontece...',
            'a': [
              {'text': 'Fico curiosa e quero entender mais', 'tipo': 'curiosa'},
              {'text': 'Respiro fundo e tento me adaptar', 'tipo': 'tranquila'},
              {'text': 'Me assusto, mas logo encontro um jeito', 'tipo': 'flexível'},
              {'text': 'Planejo o que preciso fazer a seguir', 'tipo': 'estratégica'},
            ],
          },
          {
            'q': 'Mudanças te fazem sentir...',
            'a': [
              {'text': 'Animada com o que vem', 'tipo': 'curiosa'},
              {'text': 'Um pouco ansiosa, mas aberta', 'tipo': 'flexível'},
              {'text': 'Em paz, acreditando que tudo tem um motivo', 'tipo': 'tranquila'},
              {'text': 'Motivada a organizar a nova fase', 'tipo': 'estratégica'},
            ],
          },
          {
            'q': 'Qual é sua reação diante do novo?',
            'a': [
              {'text': 'Explorar e descobrir tudo', 'tipo': 'curiosa'},
              {'text': 'Pensar e agir com calma', 'tipo': 'tranquila'},
              {'text': 'Me adaptar e aprender com o tempo', 'tipo': 'flexível'},
              {'text': 'Traçar um plano e seguir', 'tipo': 'estratégica'},
            ],
          },
          {
            'q': 'O que te ajuda a lidar com mudanças?',
            'a': [
              {'text': 'Aprender algo novo', 'tipo': 'curiosa'},
              {'text': 'Conversar e entender melhor a situação', 'tipo': 'flexível'},
              {'text': 'Aceitar e deixar o tempo agir', 'tipo': 'tranquila'},
              {'text': 'Organizar e se preparar', 'tipo': 'estratégica'},
            ],
          },
          {
            'q': 'Pra você, mudar é...',
            'a': [
              {'text': 'Uma oportunidade de crescer', 'tipo': 'curiosa'},
              {'text': 'Um desafio que vale a pena', 'tipo': 'flexível'},
              {'text': 'Um processo natural da vida', 'tipo': 'tranquila'},
              {'text': 'Uma chance de planejar o futuro', 'tipo': 'estratégica'},
            ],
          },
        ],
        'results': [
          {
            'emoji': '🦋',
            'title': 'Curiosa',
            'desc': 'Você encara mudanças com entusiasmo e curiosidade. Ama descobrir novos caminhos.'
          },
          {
            'emoji': '🍀',
            'title': 'Flexível',
            'desc': 'Você se adapta com leveza. Mesmo com medo, encontra jeitos de se ajustar e crescer.'
          },
          {
            'emoji': '🌸',
            'title': 'Tranquila',
            'desc': 'Você entende que o tempo ajuda em tudo. Muda no seu ritmo, com calma e confiança.'
          },
          {
            'emoji': '🧭',
            'title': 'Estratégica',
            'desc': 'Você enfrenta mudanças com foco e clareza. Se organiza, se prepara e faz o novo dar certo.'
          },
        ],
      },

// ===== MÊS 9 =====
      9: {
        'title': 'Qual o Seu Estilo de Amizade? 🤗',
        'description': 'Cada amizade tem seu jeito. Descubra o papel que você costuma ter nos grupos e laços mais próximos.',
        'questions': [
          {
            'q': 'Como seus amigos te descrevem?',
            'a': [
              {'text': 'A que sempre anima o grupo', 'tipo': 'divertida'},
              {'text': 'A que dá conselhos e escuta', 'tipo': 'conselheira'},
              {'text': 'A que organiza os encontros', 'tipo': 'lider'},
              {'text': 'A que está sempre presente', 'tipo': 'leal'},
            ],
          },
          {
            'q': 'O que mais valoriza em uma amizade?',
            'a': [
              {'text': 'Lealdade e confiança', 'tipo': 'leal'},
              {'text': 'Alegria e leveza', 'tipo': 'divertida'},
              {'text': 'Apoio e compreensão', 'tipo': 'conselheira'},
              {'text': 'Companheirismo e união', 'tipo': 'lider'},
            ],
          },
          {
            'q': 'Quando um amigo precisa de você...',
            'a': [
              {'text': 'Largo tudo e vou ajudar', 'tipo': 'leal'},
              {'text': 'Penso em uma forma de animar', 'tipo': 'divertida'},
              {'text': 'Escuto e dou o melhor conselho', 'tipo': 'conselheira'},
              {'text': 'Organizo uma forma de resolver juntos', 'tipo': 'lider'},
            ],
          },
          {
            'q': 'Você é a amiga que...',
            'a': [
              {'text': 'Faz todo mundo rir', 'tipo': 'divertida'},
              {'text': 'Lembra as datas importantes', 'tipo': 'leal'},
              {'text': 'Dá ótimos conselhos', 'tipo': 'conselheira'},
              {'text': 'Junta a galera pra se ver', 'tipo': 'lider'},
            ],
          },
          {
            'q': 'Sua amizade é...',
            'a': [
              {'text': 'Cheia de aventuras e risadas', 'tipo': 'divertida'},
              {'text': 'Forte e duradoura', 'tipo': 'leal'},
              {'text': 'Profunda e verdadeira', 'tipo': 'conselheira'},
              {'text': 'Unida e acolhedora', 'tipo': 'lider'},
            ],
          },
        ],
        'results': [
          {
            'emoji': '🎉',
            'title': 'Divertida',
            'desc': 'Você é a alma do grupo! Traz leveza, risadas e boas histórias pra qualquer amizade.'
          },
          {
            'emoji': '🫶',
            'title': 'Leal',
            'desc': 'Você é aquela amiga pra todas as horas. Confiável, constante e sempre presente.'
          },
          {
            'emoji': '💬',
            'title': 'Conselheira',
            'desc': 'Você tem empatia e sabedoria. Seus amigos te procuram quando precisam de clareza.'
          },
          {
            'emoji': '🌟',
            'title': 'Líder',
            'desc': 'Você junta as pessoas e faz tudo acontecer. Sua energia une e inspira o grupo.'
          },
        ],
      },

// ===== MÊS 10 =====
      10: {
        'title': 'Como Você Celebra Suas Conquistas? 🎉',
        'description': 'Descubra o que faz você se sentir realizada e como gosta de comemorar suas vitórias.',
        'questions': [
          {
            'q': 'Quando conquista algo importante...',
            'a': [
              {'text': 'Comemoro com quem amo', 'tipo': 'coletiva'},
              {'text': 'Guardo pra mim e reflito', 'tipo': 'introspectiva'},
              {'text': 'Planejo o próximo passo', 'tipo': 'focada'},
              {'text': 'Crio algo pra registrar o momento', 'tipo': 'criativa'},
            ],
          },
          {
            'q': 'Qual a melhor forma de celebrar?',
            'a': [
              {'text': 'Com uma boa festa', 'tipo': 'coletiva'},
              {'text': 'Com um tempo só pra mim', 'tipo': 'introspectiva'},
              {'text': 'Com uma nova meta', 'tipo': 'focada'},
              {'text': 'Com algo simbólico e pessoal', 'tipo': 'criativa'},
            ],
          },
          {
            'q': 'O que te faz sentir orgulho?',
            'a': [
              {'text': 'Compartilhar minha alegria', 'tipo': 'coletiva'},
              {'text': 'Reconhecer meu próprio esforço', 'tipo': 'introspectiva'},
              {'text': 'Ver resultado do meu foco', 'tipo': 'focada'},
              {'text': 'Transformar um sonho em algo bonito', 'tipo': 'criativa'},
            ],
          },
          {
            'q': 'Você comemora até as pequenas vitórias?',
            'a': [
              {'text': 'Sempre, toda conquista importa!', 'tipo': 'coletiva'},
              {'text': 'Às vezes, em silêncio', 'tipo': 'introspectiva'},
              {'text': 'Quando sinto que cumpri bem um objetivo', 'tipo': 'focada'},
              {'text': 'Sim, de um jeito criativo e leve', 'tipo': 'criativa'},
            ],
          },
          {
            'q': 'Celebrar é...',
            'a': [
              {'text': 'Compartilhar momentos felizes', 'tipo': 'coletiva'},
              {'text': 'Agradecer e reconhecer o caminho', 'tipo': 'introspectiva'},
              {'text': 'Reforçar minha determinação', 'tipo': 'focada'},
              {'text': 'Dar um toque de arte à vida', 'tipo': 'criativa'},
            ],
          },
        ],
        'results': [
          {
            'emoji': '🎊',
            'title': 'Coletiva',
            'desc': 'Você adora dividir alegrias. Comemorar com os outros faz tudo ficar mais especial!'
          },
          {
            'emoji': '🌙',
            'title': 'Introspectiva',
            'desc': 'Você prefere celebrar em silêncio, valorizando o seu próprio processo e crescimento.'
          },
          {
            'emoji': '🏁',
            'title': 'Focada',
            'desc': 'Pra você, cada conquista é um degrau. Você celebra olhando pra frente, com disciplina e orgulho.'
          },
          {
            'emoji': '🎨',
            'title': 'Criativa',
            'desc': 'Você transforma comemoração em expressão. Cada conquista vira um momento de inspiração.'
          },
        ],
      },

// ===== MÊS 11 =====
      11: {
        'title': 'Como Você Transforma o Mundo ao Seu Redor? 🌍',
        'description': 'Descubra o impacto positivo que o seu jeito de ser causa nas pessoas e no ambiente à sua volta.',
        'questions': [
          {
            'q': 'Quando vê algo injusto...',
            'a': [
              {'text': 'Age e busca soluções', 'tipo': 'ativa'},
              {'text': 'Conversa e tenta conscientizar', 'tipo': 'comunicativa'},
              {'text': 'Ajuda de forma discreta', 'tipo': 'silenciosa'},
              {'text': 'Cria algo pra inspirar mudanças', 'tipo': 'criativa'},
            ],
          },
          {
            'q': 'Como você ajuda o mundo a ser melhor?',
            'a': [
              {'text': 'Ajudando quem precisa', 'tipo': 'ativa'},
              {'text': 'Falando sobre temas importantes', 'tipo': 'comunicativa'},
              {'text': 'Fazendo pequenos gestos todos os dias', 'tipo': 'silenciosa'},
              {'text': 'Espalhando beleza e boas ideias', 'tipo': 'criativa'},
            ],
          },
          {
            'q': 'O que te faz sentir orgulho?',
            'a': [
              {'text': 'Ver que fiz diferença na vida de alguém', 'tipo': 'ativa'},
              {'text': 'Conseguir inspirar outras pessoas', 'tipo': 'criativa'},
              {'text': 'Ensinar algo importante', 'tipo': 'comunicativa'},
              {'text': 'Fazer o bem sem precisar aparecer', 'tipo': 'silenciosa'},
            ],
          },
          {
            'q': 'Qual o seu lema pra mudar o mundo?',
            'a': [
              {'text': 'Ação muda tudo', 'tipo': 'ativa'},
              {'text': 'Palavras certas têm poder', 'tipo': 'comunicativa'},
              {'text': 'Bondade não precisa de aplausos', 'tipo': 'silenciosa'},
              {'text': 'Criar é transformar', 'tipo': 'criativa'},
            ],
          },
          {
            'q': 'Você faz a diferença quando...',
            'a': [
              {'text': 'Age com coragem', 'tipo': 'ativa'},
              {'text': 'Usa sua voz e ideias', 'tipo': 'comunicativa'},
              {'text': 'Faz o bem em silêncio', 'tipo': 'silenciosa'},
              {'text': 'Cria algo que toca as pessoas', 'tipo': 'criativa'},
            ],
          },
        ],
        'results': [
          {
            'emoji': '💪',
            'title': 'Ativa',
            'desc': 'Você faz acontecer! Age com coragem e determinação pra criar um mundo mais justo.'
          },
          {
            'emoji': '🗣️',
            'title': 'Comunicativa',
            'desc': 'Sua voz inspira. Você acredita no poder das palavras e das boas conversas.'
          },
          {
            'emoji': '🌷',
            'title': 'Silenciosa',
            'desc': 'Você muda o mundo com gentileza e exemplos diários. Sua força é serena e constante.'
          },
          {
            'emoji': '🎭',
            'title': 'Criativa',
            'desc': 'Você inspira transformações por meio da arte, da expressão e de novas ideias.'
          },
        ],
      },

// ===== MÊS 12 =====
      12: {
        'title': 'Qual o Seu Espírito Natalino? 🎄',
        'description': 'Descubra o que o Natal desperta em você — generosidade, alegria, reflexão ou amor.',
        'questions': [
          {
            'q': 'O que mais ama no Natal?',
            'a': [
              {'text': 'A união com a família', 'tipo': 'afetiva'},
              {'text': 'As tradições e histórias', 'tipo': 'nostálgica'},
              {'text': 'Os presentes e a festa', 'tipo': 'animada'},
              {'text': 'O clima de paz e reflexão', 'tipo': 'espiritual'},
            ],
          },
          {
            'q': 'Como você gosta de celebrar?',
            'a': [
              {'text': 'Com todos juntos à mesa', 'tipo': 'afetiva'},
              {'text': 'Revendo fotos e lembranças', 'tipo': 'nostálgica'},
              {'text': 'Com música e risadas', 'tipo': 'animada'},
              {'text': 'Com gratidão e momentos calmos', 'tipo': 'espiritual'},
            ],
          },
          {
            'q': 'O que o Natal representa pra você?',
            'a': [
              {'text': 'Amor e união', 'tipo': 'afetiva'},
              {'text': 'Memórias e tradições', 'tipo': 'nostálgica'},
              {'text': 'Alegria e celebração', 'tipo': 'animada'},
              {'text': 'Luz e renovação interior', 'tipo': 'espiritual'},
            ],
          },
          {
            'q': 'Qual momento você mais gosta?',
            'a': [
              {'text': 'A ceia em família', 'tipo': 'afetiva'},
              {'text': 'Abrir os presentes', 'tipo': 'animada'},
              {'text': 'Assistir filmes natalinos', 'tipo': 'nostálgica'},
              {'text': 'Refletir e agradecer pelo ano', 'tipo': 'espiritual'},
            ],
          },
          {
            'q': 'Pra você, o Natal é...',
            'a': [
              {'text': 'Amor compartilhado', 'tipo': 'afetiva'},
              {'text': 'Lembranças que aquecem o coração', 'tipo': 'nostálgica'},
              {'text': 'Festa e alegria', 'tipo': 'animada'},
              {'text': 'Um tempo de fé e gratidão', 'tipo': 'espiritual'},
            ],
          },
        ],
        'results': [
          {
            'emoji': '❤️',
            'title': 'Afetiva',
            'desc': 'Você vive o Natal com o coração. Pra você, o amor e a união são o verdadeiro presente.'
          },
          {
            'emoji': '🌟',
            'title': 'Nostálgica',
            'desc': 'Você ama relembrar e reviver tradições. O Natal é tempo de memórias e abraços quentinhos.'
          },
          {
            'emoji': '🎁',
            'title': 'Animada',
            'desc': 'Você traz o clima de festa! Espalha risadas, alegria e muita energia boa por onde passa.'
          },
          {
            'emoji': '🕯️',
            'title': 'Espiritual',
            'desc': 'Você sente o Natal como um renascimento. Valoriza o silêncio, a fé e a gratidão.'
          },
        ],
      },

    };

    // 🔹 Retorna o quiz do mês atual ou o padrão
    return quizzes[month] ?? _defaultQuiz();
  }

  Map<String, dynamic> _defaultQuiz() {
    return {
      'title': 'Quiz do Mês 💫',
      'description': 'Descubra algo novo sobre você neste mês ✨',
      'questions': [],
      'results': [],
    };
  }


