import 'package:flutter/material.dart';
import 'package:my_year_my_story/services/interview_service.dart';
import 'package:my_year_my_story/widgets/shared/month_page_template.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class InterviewWidget extends StatefulWidget {
  final int month;
  final int year;

  const InterviewWidget({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<InterviewWidget> createState() => _InterviewWidgetState();
}

class _InterviewWidgetState extends State<InterviewWidget> {
  final _intervieweeController = TextEditingController();
  final Map<String, TextEditingController> _answerControllers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInterview();
  }

  Future<void> _loadInterview() async {
    setState(() => _isLoading = true);

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final data = await InterviewService.getInterview(
      widget.month,
      widget.year,
      user.id,
    );

    if (data.isNotEmpty) {
      _intervieweeController.text = data['interviewee'] ?? '';
      final answers = Map<String, String>.from(data['answers'] ?? {});
      for (final entry in answers.entries) {
        _answerControllers[entry.key] =
            TextEditingController(text: entry.value);
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveInterview() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final answers = {
      for (final entry in _answerControllers.entries)
        entry.key: entry.value.text,
    };

    final success = await InterviewService.saveInterview(
      _intervieweeController.text,
      answers,
      widget.month,
      widget.year,
      user.id,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrevista salva com sucesso!')),
      );
    }
  }

  Widget _buildQuestions() {
    final questions = [
      'Qual foi o momento mais marcante deste mês?',
      'Qual desafio você superou?',
      'O que mais te fez sorrir?',
      'Qual aprendizado você quer levar para o próximo mês?',
      'Que conselho você daria a si mesmo(a)?',
    ];

    return Column(
      children: questions.map((q) {
        _answerControllers.putIfAbsent(q, () => TextEditingController());
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextField(
            controller: _answerControllers[q],
            maxLines: 2,
            decoration: InputDecoration(
              labelText: q,
              border: const OutlineInputBorder(),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthName =
    DateFormat.MMMM('pt_BR').format(DateTime(widget.year, widget.month));

    return MonthPageTemplate(
      month: widget.month,
      year: widget.year,
      title: 'Hora da Entrevista',
      description:
      'Um espaço para refletir sobre o seu mês e registrar aprendizados, sorrisos e conquistas. 🌸',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Entrevista de $monthName',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _intervieweeController,
              decoration: const InputDecoration(
                labelText: 'Entrevistado(a)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _buildQuestions(),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveInterview,
              icon: const Icon(Icons.save),
              label: const Text('Salvar Entrevista'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _intervieweeController.dispose();
    for (final c in _answerControllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}
