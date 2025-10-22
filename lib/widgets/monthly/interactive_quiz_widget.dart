import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_year_my_story/widgets/shared/month_page_template.dart'; // 🌸 novo template

class InteractiveQuizWidget extends StatefulWidget {
  final int month;
  final int year;
  final String? monthName;

  const InteractiveQuizWidget({
    Key? key,
    required this.month,
    required this.year,
    this.monthName,
  }) : super(key: key);

  @override
  State<InteractiveQuizWidget> createState() => _InteractiveQuizWidgetState();
}

class _InteractiveQuizWidgetState extends State<InteractiveQuizWidget> {
  final _supabase = Supabase.instance.client;

  Map<String, dynamic>? _quizData;
  String? _quizTitle;
  int _currentQuestion = 0;
  String? _selectedOption;
  bool _isLoading = true;
  bool _showingResult = false;
  Map<String, int> _scores = {};
  Map<String, dynamic>? _finalResult;
  late final String resolvedMonthName;

  @override
  void initState() {
    super.initState();
    resolvedMonthName = widget.monthName ?? _getMonthName(widget.month);
    _fetchQuizData().then((_) => _checkQuizCompletion());
  }

  String _getMonthName(int month) {
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return months[month - 1];
  }

  Future<void> _fetchQuizData() async {
    try {
      final data = await _supabase
          .from('quizzes')
          .select()
          .eq('month', widget.month)
          .eq('year', widget.year)
          .maybeSingle();

      if (data != null) {
        setState(() {
          _quizData = data;
          _quizTitle = data['quiz_title'] ?? 'Quiz de $resolvedMonthName 💕';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Erro ao buscar quiz: $e');
    }
  }

  Future<void> _checkQuizCompletion() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final entry = await _supabase
          .from('entries')
          .select('quiz_result, quiz_title')
          .eq('user_id', user.id)
          .eq('month', widget.month)
          .eq('year', widget.year)
          .maybeSingle();

      if (entry != null && entry['quiz_result'] != null) {
        setState(() {
          _showingResult = true;
          _finalResult = {
            'emoji': '🎉',
            'desc': entry['quiz_result'],
          };
          _quizTitle = entry['quiz_title'] ?? 'Quiz de $resolvedMonthName 💕';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao verificar quiz_result: $e');
    }
  }

  void _nextQuestion(String tipo) {
    setState(() {
      _scores[tipo] = (_scores[tipo] ?? 0) + 1;
    });

    if (_currentQuestion < _quizData!['questions'].length - 1) {
      setState(() {
        _currentQuestion++;
        _selectedOption = null;
      });
    } else {
      _showResult();
    }
  }

  Future<void> _showResult() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    final highest = _scores.entries.reduce((a, b) => a.value >= b.value ? a : b);

    final resultList = _quizData!['results'] as List<dynamic>;
    final result = resultList.firstWhere(
          (r) => r['title'].toString().toLowerCase() == highest.key.toLowerCase(),
      orElse: () => resultList.first,
    );

    setState(() {
      _finalResult = result;
      _isLoading = false;
      _showingResult = true;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final existing = await _supabase
          .from('entries')
          .select('id')
          .eq('user_id', user.id)
          .eq('month', widget.month)
          .eq('year', widget.year)
          .maybeSingle();

      if (existing == null) {
        await _supabase.from('entries').insert({
          'user_id': user.id,
          'month': widget.month,
          'year': widget.year,
          'quiz_title': _quizTitle,
          'quiz_result': result['desc'],
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        await _supabase.from('entries').update({
          'quiz_title': _quizTitle,
          'quiz_result': result['desc'],
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existing['id']);
      }
    } catch (e) {
      debugPrint('Erro ao salvar quiz_result: $e');
    }
  }

  void _resetQuiz() {
    setState(() {
      _currentQuestion = 0;
      _selectedOption = null;
      _scores.clear();
      _finalResult = null;
      _showingResult = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MonthPageTemplate(
      title: 'Quiz de $resolvedMonthName 💕',
      description:
      'Descubra um pouquinho mais sobre você e divirta-se com as perguntas deste mês! 💫',
      month: widget.month,
      year: widget.year,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quizData == null
          ? const Center(
        child: Text(
          'Nenhum quiz encontrado para este mês 😅',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: Color(0xFF4F4F4F),
          ),
          textAlign: TextAlign.center,
        ),
      )
          : _showingResult
          ? _buildResult()
          : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildQuizContent(),
            const SizedBox(height: 16),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizContent() {
    final question = _quizData!['questions'][_currentQuestion];
    final options = question['options'] as List<dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_quizTitle != null && _quizTitle!.isNotEmpty) ...[
          Center(
            child: Text(
              _quizTitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFFC03B66),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        Text(
          'Pergunta ${_currentQuestion + 1} de ${_quizData!['questions'].length}',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Color(0xFF9E9E9E),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          question['text'],
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4F4F4F),
          ),
        ),
        const SizedBox(height: 24),
        ...options.map((option) {
          final isSelected = _selectedOption == option['text'];
          return GestureDetector(
            onTap: () => setState(() => _selectedOption = option['text']),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFC03B66)
                    : const Color(0xFFFCE7EE),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.circle_outlined,
                    color: isSelected ? Colors.white : const Color(0xFFC03B66),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option['text'],
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color:
                        isSelected ? Colors.white : const Color(0xFF4F4F4F),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildBottomButton() {
    final isLastQuestion =
        _currentQuestion == _quizData!['questions'].length - 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          onPressed: _selectedOption == null
              ? null
              : () {
            final tipo = (_quizData!['questions'][_currentQuestion]
            ['options'] as List<dynamic>)
                .firstWhere((opt) => opt['text'] == _selectedOption)['tipo'];
            _nextQuestion(tipo);
          },
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          label: Text(isLastQuestion ? 'Finalizar' : 'Próximo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC03B66),
            foregroundColor: Colors.white,
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    final result = _finalResult;
    if (result == null) return const SizedBox.shrink();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Você completou o quiz! ${result['emoji'] ?? '🎉'}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFFC03B66),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              result['desc'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                color: Color(0xFF4F4F4F),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _resetQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC03B66),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Refazer quiz',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
