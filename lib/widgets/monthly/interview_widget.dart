import 'package:flutter/material.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/services/interview_service.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';

class InterviewScreen extends StatefulWidget {
  final int? month;
  final int? year;

  const InterviewScreen({
    super.key,
    this.month,
    this.year,
  });

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

  /// Controle de perguntas visíveis
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
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);

    _currentUserId = supabase.auth.currentUser?.id;
    _isPremiumUser = await AccessControl.isPremium();

    /// Buscar texto + perguntas do Supabase
    final interviewData = await InterviewService.getInterviewData(
      widget.month ?? DateTime.now().month,
      context.locale.languageCode,
    );

    _questions = List<String>.from(interviewData['questions'] ?? []);
    _description =
        "interview.fixed_description".tr(); // agora fixa, sempre traduzida

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
    final questionsData =
        List<Map<String, dynamic>>.from(data['questions'] ?? []);

    _nameController.text = person['name'] ?? '';
    _relationController.text = person['relation'] ?? '';
    _ageController.text = person['age'] ?? '';

    _controllers.clear();
    for (int i = 0; i < _questions.length; i++) {
      final answer = i < questionsData.length
          ? questionsData[i]['a'] ?? ''
          : '';
      _controllers.add(TextEditingController(text: answer));
    }
  }

  Future<void> _saveInterview() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      showPremiumPopup(context);
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
      debugPrint("Erro ao salvar entrevista: $e");
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

    /// Usuários Free só veem 5 perguntas
    final visibleQuestions = _isPremiumUser || _showAllQuestions
        ? _questions
        : _questions.take(5).toList();

    return MonthPageTemplate(
      month: month,
      year: year,
      title: "",
      pageLabel: "interview.page_label".tr(),
      labelColor: const Color(0xFFa1a8f0),
      description: _description,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Texto "Quem você está entrevistando?"
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
                  ),
                ),
              ),
            ),

            /// Card com nome / relação / idade
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFE7F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _buildTextField(
                    label: "interview.name_label".tr(),
                    controller: _nameController,
                    hint: "interview.name_hint".tr(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildFieldBase(
                          controller: _relationController,
                          hint: "interview.relation_hint".tr(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: _buildFieldBase(
                          controller: _ageController,
                          hint: "interview.age_hint".tr(),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// Título “Perguntas”
            Center(
              child: Text(
                "interview.ask".tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 152, 70, 139),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// Lista de perguntas
            ...visibleQuestions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE4EC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF2D7E0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 22,
                        ),
                      ),
                    )
                  ],
                ),
              );
            }),

            /// Mostrar mais perguntas (free)
            if (!_isPremiumUser && !_showAllQuestions)
              Center(
                child: TextButton(
                  onPressed: () => showPremiumPopup(context),
                  child: Text(
                    "interview.show_more".tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF722E7A),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            /// Botões
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isPremiumUser ? _saveInterview : () {
                      showPremiumPopup(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA1A8F0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "interview.save_button".tr(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => showPremiumPopup(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC881D5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "interview.audio_button".tr(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Helper – campo base
  Widget _buildFieldBase({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Helper – campo com label
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _buildFieldBase(
          controller: controller,
          hint: hint,
        ),
      ],
    );
  }
}
