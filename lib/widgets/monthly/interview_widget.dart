import 'package:flutter/material.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/services/interview_service.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/screens/popups/coming_soon.dart';
import 'package:easy_localization/easy_localization.dart';

class InterviewScreen extends StatefulWidget {
  final int? month;
  final int? year;

  const InterviewScreen({super.key, this.month, this.year});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen>
    with AutomaticKeepAliveClientMixin {
  final supabase = SupabaseConfig.client;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isPremiumUser = false;
  String? _currentUserId;
  int _saveCount = 0;
  bool _showAllQuestions = false;

  final List<TextEditingController> _controllers = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _relationController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  List<String> _questions = [];
  String _description = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    setState(() => _isLoading = true);
    _currentUserId = supabase.auth.currentUser?.id;

    if (_currentUserId != null) {
      _isPremiumUser = await AccessControl.checkPremiumStatus(_currentUserId!);
    }

    final interviewData = await InterviewService.getInterviewData(
      widget.month ?? DateTime.now().month,
      'pt',
    );

    _questions = List<String>.from(interviewData['questions'] ?? []);
    _description = interviewData['description'] ?? '';

    await _loadSavedAnswers();

    setState(() => _isLoading = false);
  }

  Future<void> _loadSavedAnswers() async {
    if (_currentUserId == null) return;

    final data = await InterviewService.getInterviewDataFromEntries(
      widget.month ?? DateTime.now().month,
      widget.year ?? DateTime.now().year,
      _currentUserId!,
    );

    final person = data['person'] ?? {};
    final questionsData = List<Map<String, dynamic>>.from(data['questions'] ?? []);

    _nameController.text = person['name'] ?? '';
    _relationController.text = person['relation'] ?? '';
    _ageController.text = person['age'] ?? '';

    _controllers.clear();
    for (int i = 0; i < _questions.length; i++) {
      String answer = '';
      if (i < questionsData.length) {
        answer = questionsData[i]['a'] ?? '';
      }
      _controllers.add(TextEditingController(text: answer));
    }
  }

  Future<void> _saveInterview() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      AccessControl.showLoginPopup(context);
      return;
    }

    if (!_isPremiumUser) {
      _saveCount++;
      if (_saveCount >= 3) {
        AccessControl.showPremiumPopup(
          context,
          widget.month ?? DateTime.now().month,
          widget.year ?? DateTime.now().year,
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final answers = _controllers.map((c) => c.text.trim()).toList();

      await InterviewService.saveInterviewAnswers(
        questions: _questions,
        answers: answers,
        month: widget.month ?? DateTime.now().month,
        year: widget.year ?? DateTime.now().year,
        userId: user.id,
        interviewName: _nameController.text.trim(),
        interviewRelation: _relationController.text.trim(),
        interviewAge: _ageController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('interview.saved_success'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao salvar entrevista: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('interview.save_error'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final month = widget.month ?? DateTime.now().month;
    final year = widget.year ?? DateTime.now().year;
    final visibleQuestions = _showAllQuestions || _isPremiumUser
        ? _questions
        : _questions.take(5).toList();

    return MonthPageTemplate(
      month: month,
      year: year,
      title: 'interview.title'.tr(),
      description: _description.isNotEmpty
          ? _description
          : 'Um espaço para registrar suas respostas e refletir sobre o que te inspira, motiva e faz crescer ✨',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🩷 Introdução fixa — centralizada
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  'De quem você vai guardar as memórias este mês?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            ),

            // 🔹 Campos fixos (nome / relação / idade)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0x8cdfcdcd),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Qual é o nome do entrevistado?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Digite o nome completo...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.pink.shade100,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _relationController,
                          decoration: InputDecoration(
                            hintText: 'Quem é essa pessoa pra você?',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Color(0xffedcfcf),
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _ageController,
                          decoration: InputDecoration(
                            hintText: 'Idade',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.pink.shade100,
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 💬 Separador “PERGUNTE...”
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'PERGUNTE...',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC03B66),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // 🔹 Perguntas vindas do Supabase
            ...visibleQuestions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;

              if (_controllers.length <= index) {
                _controllers.add(TextEditingController());
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xfffce4ec),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _controllers[index],
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'interview.answer_hint'.tr(),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.pink.shade100,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            if (!_isPremiumUser && !_showAllQuestions)
              Center(
                child: TextButton(
                  onPressed: () {
                    AccessControl.showPremiumPopup(context, month, year);
                  },
                  child: const Text(
                    'Ver mais perguntas',
                    style: TextStyle(
                      color: Color(0xffc50d59),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),


            const SizedBox(height: 10),

            // 💾 Botão Salvar
            Center(
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveInterview,
                icon: const Icon(Icons.favorite, color: Colors.white),
                label: const Text('Salvar memória'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffd1186c),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🎙️ Botão Gravar Áudio (Coming Soon)
            Center(
              child: ElevatedButton.icon(
                onPressed: () => showComingSoonPrompt(context),
                icon: const Icon(Icons.mic, color: Colors.white),
                label: const Text('Gravar áudio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff3983c6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 16,
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
