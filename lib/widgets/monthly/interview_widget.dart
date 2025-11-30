import 'package:flutter/material.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/services/interview_service.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:myyearmystory/utils/month_colors.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/screens/popups/coming_soon.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/utils/month_colors.dart';

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
      context.locale.languageCode,
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
      showPremiumPopup(context);
      return;
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

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final month = widget.month ?? DateTime.now().month;
    final year = widget.year ?? DateTime.now().year;
    final currentButtonColor = getMonthColor(month);

    final visibleQuestions = _showAllQuestions || _isPremiumUser
        ? _questions
        : _questions.take(5).toList();

    return MonthPageTemplate(
      month: month,
      year: year,
      title: "",
      pageLabel: "interview.page_label".tr(),
      labelColor: const Color(0xFFa1a8f0),

      description: _description.isNotEmpty
          ? _description
          : "interview.default_description".tr(),

      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// TÍTULO SUPERIOR
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  "interview.who_prompt".tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color.fromARGB(221, 149, 41, 110),
                    height: 1.5,
                  ),
                ),
              ),
            ),

            /// CAMPOS FIXOS (nome, parentesco, idade)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFE7F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    "interview.name_label".tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: "interview.name_hint".tr(),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.purple.shade100,
                          width: 1.1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _relationController,
                          decoration: InputDecoration(
                            hintText: "interview.relation_hint".tr(),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.purple.shade100,
                                width: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _ageController,
                          decoration: InputDecoration(
                            hintText: "interview.age_hint".tr(),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.pink.shade100,
                                width: 1.1,
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

            /// TÍTULO DAS PERGUNTAS
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  "interview.ask".tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 152, 70, 139),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            /// LISTA DE PERGUNTAS
            ...visibleQuestions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;

              if (_controllers.length <= index) {
                _controllers.add(TextEditingController());
              }

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xfffce4ec),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFF2D7E0),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
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
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _controllers[index],
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: "interview.answer_hint".tr(),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 22,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.pink.shade100,
                            width: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            /// MOSTRAR MAIS (somente para não premium)
            if (!_isPremiumUser && !_showAllQuestions)
              Center(
                child: TextButton(
                  onPressed: () {
                    showPremiumPopup(context);
                  },
                  child: Text(
                    "interview.show_more".tr(),
                    style: const TextStyle(
                      color: Color.fromARGB(255, 114, 46, 121),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            /// BOTÕES FINAIS
            Row(
              children: [
                /// BOTÃO SALVAR (COR DO MÊS)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (!_isPremiumUser) {
                        showPremiumPopup(context);
                        return;
                      }
                      if (!_isSaving) _saveInterview();
                    },
                    child: AnimatedContainer(
  duration: const Duration(milliseconds: 180),
  padding: const EdgeInsets.symmetric(vertical: 14), // sem horizontal
  decoration: BoxDecoration(
    color: _isPremiumUser
        ? currentButtonColor
        : currentButtonColor,
    borderRadius: BorderRadius.circular(10),
    boxShadow: [
      BoxShadow(
        color: currentButtonColor.withOpacity(0.4),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: Center(
    child: Text(
      "interview.save_button".tr(),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
),

                  ),
                ),

                const SizedBox(width: 12),

                /// BOTÃO ÁUDIO
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => showComingSoonPrompt(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 200, 129, 213),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "interview.audio_button".tr(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
