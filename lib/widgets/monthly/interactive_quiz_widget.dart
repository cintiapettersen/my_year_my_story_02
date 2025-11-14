import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:myyearmystory/widgets/shared/show_login_prompt.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class InteractiveQuizWidget extends StatefulWidget {
  final int month;
  final int year;
  final String monthName;

  const InteractiveQuizWidget({
    Key? key,
    required this.month,
    required this.year,
    required this.monthName,
  }) : super(key: key);

  @override
  State<InteractiveQuizWidget> createState() => _InteractiveQuizWidgetState();
}

class _InteractiveQuizWidgetState extends State<InteractiveQuizWidget> {
  bool _isLoading = false;
  bool _quizFinished = false;

  List<dynamic> _questions = [];
  List<dynamic> _results = [];
  String _quizTitle = '';
  String _quizDescription = '';
  String _introText = '';
  int _score = 0;

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _loadQuiz();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('quizzes')
          .select()
          .eq('month', widget.month)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _quizTitle = response['title'] ?? '';
          _quizDescription = response['description'] ?? '';
          _questions = List<Map<String, dynamic>>.from(response['questions']);
          _results = List<Map<String, dynamic>>.from(response['results']);
          _introText = response['intro'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar quiz: $e');
    }

    setState(() => _isLoading = false);
  }

  void _selectOption(int questionIndex, int optionIndex) {
    setState(() {
      for (var i = 0; i < _questions[questionIndex]['options'].length; i++) {
        _questions[questionIndex]['options'][i]['selected'] = false;
      }
      _questions[questionIndex]['options'][optionIndex]['selected'] = true;
    });
  }

  void _calculateResult() {
    int score = 0;

    for (final q in _questions) {
      for (final opt in q['options']) {
        if (opt['selected'] == true) {
          score += (opt['value'] ?? 0) as int;
        }
      }
    }

    setState(() {
      _score = score;
      _quizFinished = true;
    });

    _confettiController.play();
  }

  void _resetQuiz() {
    setState(() {
      for (final q in _questions) {
        for (final opt in q['options']) {
          opt['selected'] = false;
        }
      }
      _score = 0;
      _quizFinished = false;
    });
  }

  String _getResultDescription() {
    if (_results.isEmpty) return '';

    final index =
    (_score ~/ (_questions.length * 2)).clamp(0, _results.length - 1);
    return _results[index]['desc'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final monthName =
    DateFormat.MMMM('pt_BR').format(DateTime(widget.year, widget.month));

    return Stack(
      children: [
        MonthPageTemplate(
          month: widget.month,
          year: widget.year,
          title: _quizTitle.isNotEmpty
              ? _quizTitle
              : 'Quiz de $monthName',
          description: _quizDescription.isNotEmpty
              ? _quizDescription
              : 'Descubra algo novo sobre você neste mês ',
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _questions.isEmpty
              ? const Center(
            child:
            Text('Nenhuma pergunta disponível para este mês.'),
          )
              : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: !_quizFinished
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                ..._questions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final q = entry.value;
                  return Padding(
                    padding:
                    const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          q['text'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...q['options']
                            .asMap()
                            .entries
                            .map((optEntry) {
                          final optIndex = optEntry.key;
                          final opt = optEntry.value;
                          final selected =
                              opt['selected'] ?? false;

                          return GestureDetector(
                            onTap: () => _selectOption(
                                index, optIndex),
                            child: Container(
                              margin:
                              const EdgeInsets.symmetric(
                                  vertical: 6),
                              padding:
                              const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFFFE3EC)
                                    : Colors.white,
                                borderRadius:
                                BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFFC03B66)
                                      : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    selected
                                        ? Icons.favorite
                                        : Icons
                                        .favorite_border,
                                    color: selected
                                        ? const Color(
                                        0xFFC03B66)
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      opt['text'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: selected
                                            ? const Color(
                                            0xFFC03B66)
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final user = Supabase
                          .instance.client.auth.currentUser;

                      if (user == null) {
                        showLoginPrompt(context);
                        return;
                      }

                      final profileResponse = await Supabase
                          .instance.client
                          .from('profiles')
                          .select()
                          .eq('id', user.id)
                          .maybeSingle();

                      final userProfile =
                          profileResponse ?? {};

                      final canAccess = AccessControl
                          .canAccessPremium(userProfile);

                      if (!canAccess) {
                        showPremiumPrompt(context);
                        return;
                      }

                      setState(() {
                        _calculateResult();
                      });
                    },
                    icon: const Icon(Icons.stars,
                        color: Colors.white),
                    label: const Text(
                      'Ver Resultado 💫',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFFC03B66),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(30),
                      ),
                      elevation: 3,
                      shadowColor: Colors.pinkAccent
                          .withOpacity(0.3),
                    ),
                  ),
                ),
              ],
            )
                : _buildResultSection(),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            maxBlastForce: 20,
            minBlastForce: 8,
            emissionFrequency: 0.05,
            numberOfParticles: 25,
            gravity: 0.2,
            colors: const [
              Color(0xFFC03B66),
              Colors.pinkAccent,
              Colors.amber,
              Colors.white,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.favorite, color: Color(0xFFC03B66), size: 60),
        const SizedBox(height: 20),
        const Text(
          'Seu Resultado 💫',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFFC03B66),
          ),
        ),
        const SizedBox(height: 20),
        AnimatedOpacity(
          opacity: _quizFinished ? 1 : 0,
          duration: const Duration(seconds: 1),
          child: Text(
            _getResultDescription(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, height: 1.6),
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: _resetQuiz,
          icon: const Icon(Icons.refresh, color: Colors.white),
          label: const Text(
            'Refazer Quiz',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC03B66),
            padding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 3,
            shadowColor: Colors.pinkAccent.withOpacity(0.3),
          ),
        ),
      ],
    );
  }
}
