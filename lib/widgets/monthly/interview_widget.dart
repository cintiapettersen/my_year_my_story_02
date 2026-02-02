import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/services/interview_service.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/screens/popups/coming_soon.dart';
import 'package:myyearmystory/screens/popups/popup_login.dart';


class AppConfig {
  static bool isDev = true;
  static bool isAdmin(String? email) =>
      email != null && email.endsWith("@sonhodepapel.com");
}

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
  bool _showAllQuestions = false;

  final List<TextEditingController> _controllers = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _relationController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  List<String> _questions = [];
  String _description = '';

  @override
  bool get wantKeepAlive => true;

  bool get isGuest {
  return supabase.auth.currentUser == null;
}

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);

    await _checkPremiumStatus();

    final data = await InterviewService.getInterviewData(
      widget.month ?? DateTime.now().month,
      context.locale.languageCode,
    );

    _questions = List<String>.from(data['questions'] ?? []);
    _description = "interview.fixed_description".tr();

    _controllers.clear();
    for (int i = 0; i < _questions.length; i++) {
      _controllers.add(TextEditingController());
    }

    await _loadSavedAnswers();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkPremiumStatus() async {
    final user = supabase.auth.currentUser;
    final email = user?.email;
    final isPremium = await AccessControl.isPremium();

    if (!mounted) return;
    setState(() {
      _isPremiumUser =
          isPremium || AppConfig.isAdmin(email) || AppConfig.isDev;
    });
  }

  Future<void> _loadSavedAnswers() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final data = await InterviewService.getInterviewDataFromEntries(
      widget.month ?? DateTime.now().month,
      widget.year ?? DateTime.now().year,
      userId,
    );

    final person = data['person'] ?? {};
    final questionsData =
        List<Map<String, dynamic>>.from(data['questions'] ?? []);

    _nameController.text = person['name'] ?? '';
    _relationController.text = person['relation'] ?? '';
    _ageController.text = person['age'] ?? '';

    for (int i = 0; i < _controllers.length; i++) {
      if (i < questionsData.length) {
        _controllers[i].text = questionsData[i]['a'] ?? '';
      }
    }
  }

  Future<void> _saveInterview() async {
    final user = supabase.auth.currentUser;

if (isGuest) {
  showLoginPrompt(context);
  return;
}

if (!_isPremiumUser) {
  showPremiumPopup(context);
  return;
}


    final visibleCount =
        _isPremiumUser || _showAllQuestions ? _questions.length : 5;

    final answers = _controllers
        .take(visibleCount)
        .map((c) => c.text.trim())
        .toList();

    // 🚫 nenhuma resposta
    if (!answers.any((a) => a.isNotEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFF3D6E4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text(
            "interview.empty_warning".tr(),
            style: const TextStyle(
              color: Color(0xFF6D2C4A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await InterviewService.saveInterviewAnswers(
        questions: _questions,
        answers: answers,
        month: widget.month ?? DateTime.now().month,
        year: widget.year ?? DateTime.now().year,
        userId: user!.id,
        interviewName: _nameController.text.trim(),
        interviewRelation: _relationController.text.trim(),
        interviewAge: _ageController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFA1A8F0),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            content: Text(
              "interview.saved_success".tr(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            content: Text("interview.save_error".tr()),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
                      ),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

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
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6D5C74),
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

            if (!_isPremiumUser && !_showAllQuestions)
              Center(
                child: TextButton(
                  onPressed: () {
                 if (isGuest) {
                 showLoginPrompt(context);
                 return;
               }
               showPremiumPopup(context);
            },
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

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveInterview,
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
                    onPressed: () => showComingSoonPrompt(context),
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
