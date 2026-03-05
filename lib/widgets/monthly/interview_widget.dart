import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/services/interview_service.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/screens/popups/coming_soon.dart';
import 'package:myyearmystory/screens/popups/popup_login.dart';
import 'package:myyearmystory/widgets/shared/remote_data_wrapper.dart';

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

  bool _isLoading = true;
  bool _hasError = false;
  bool _isSaving = false;

  bool _isPremiumUser = false;
  final bool _showAllQuestions = false;

  final List<TextEditingController> _controllers = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _relationController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  List<String> _questions = [];
  String _description = '';

  @override
  bool get wantKeepAlive => true;

  bool get isGuest => supabase.auth.currentUser == null;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  // ---------------- INIT ----------------

  Future<void> _initialize() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      await _checkPremiumStatus();

      final data = await InterviewService.getInterviewData(
        widget.month ?? DateTime.now().month,
        context.locale.languageCode,
      );

      _questions = List<String>.from(data['questions'] ?? []);
      _description = "interview.fixed_description".tr();

      _controllers
        ..clear()
        ..addAll(
          List.generate(
            _questions.length,
            (_) => TextEditingController(),
          ),
        );

      await _loadSavedAnswers();
    } catch (e) {
      
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  // ---------------- SAVE ----------------

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

    if (!answers.any((a) => a.isNotEmpty)) {
      _showEmptyWarning();
      return;
    }

    await _saveInterviewAnswers(user!.id, answers);
  }

  Future<void> _saveInterviewAnswers(
      String userId, List<String> answers) async {
    if (!mounted) return;

    setState(() => _isSaving = true);

    try {
      await InterviewService.saveInterviewAnswers(
        questions: _questions,
        answers: answers,
        month: widget.month ?? DateTime.now().month,
        year: widget.year ?? DateTime.now().year,
        userId: userId,
        interviewName: _nameController.text.trim(),
        interviewRelation: _relationController.text.trim(),
        interviewAge: _ageController.text.trim(),
      );

      if (!mounted) return;
      _showSuccessSnack();
    } catch (e) {
      if (!mounted) return;
      _showErrorSnack();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ---------------- UI HELPERS ----------------

  void _showEmptyWarning() {
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
  }

  void _showSuccessSnack() {
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

  void _showErrorSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        content: Text("interview.save_error".tr()),
      ),
    );
  }

  // ---------------- BUILD ----------------

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
      child: RemoteDataWrapper(
        isLoading: _isLoading,
        hasError: _hasError,
        onRetry: _initialize,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildPersonForm(),
              const SizedBox(height: 20),
              _buildQuestions(visibleQuestions),
              const SizedBox(height: 20),
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- SUB WIDGETS ----------------

  Widget _buildHeader() => Center(
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
      );

  Widget _buildPersonForm() => Container(
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
      );

  Widget _buildQuestions(List<String> questions) => Column(
        children: questions.asMap().entries.map((entry) {
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
	                  autocorrect: true,
	                  enableSuggestions: true,
	                  smartQuotesType: SmartQuotesType.enabled,
	                  smartDashesType: SmartDashesType.enabled,
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
        }).toList(),
      );

  Widget _buildButtons() => Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveInterview,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA1A8F0),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text("interview.save_button".tr()),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => showComingSoonPrompt(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC881D5),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text("interview.audio_button".tr()),
            ),
          ),
        ],
      );

  Widget _buildFieldBase({
    required TextEditingController controller,
    required String hint,
	  }) =>
	      TextField(
	        controller: controller,
	        autocorrect: true,
	        enableSuggestions: true,
	        smartQuotesType: SmartQuotesType.enabled,
	        smartDashesType: SmartDashesType.enabled,
	        decoration: InputDecoration(
	          hintText: hint,
	          filled: true,
	          fillColor: Colors.white,
	          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _buildFieldBase(controller: controller, hint: hint),
        ],
      );
}
