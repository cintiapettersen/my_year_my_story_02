import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Popup Premium já existente
import 'package:myyearmystory/screens/premium/premium_popup.dart';

class MonthlyQuizWidget extends StatefulWidget {
  final int month;
  final int year;

  const MonthlyQuizWidget({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<MonthlyQuizWidget> createState() => _MonthlyQuizWidgetState();
}

class _MonthlyQuizWidgetState extends State<MonthlyQuizWidget> {
  Map<int, int> selectedOptions = {};
  Map<String, dynamic>? quizData;
  bool loading = true;

  // TODO: trocar depois pela lógica real
  bool userIsPremium = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    final data = await Supabase.instance.client
        .from('quizzes')
        .select()
        .eq('month', widget.month)
        .maybeSingle();

    setState(() {
      quizData = data;
      loading = false;
    });
  }

  // PT/EN vindo do Supabase
  String getLocalized(String? pt, String? en) {
    final lang = Localizations.localeOf(context).languageCode;
    if (lang == "en" && en != null && en.trim().isNotEmpty) {
      return en;
    }
    return pt ?? "";
  }

  // 🌸 Popup Rosinha: perguntas faltando
  void showMissingAnswersCutePopup(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "quiz.missing_answers_barrier".tr(),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, animation1, animation2, child) {
        final curved = Curves.easeInOut.transform(animation1.value) - 1.0;

        return Transform(
          transform: Matrix4.translationValues(0.0, curved * -40, 0.0),
          child: Opacity(
            opacity: animation1.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: const Color.fromARGB(255, 224, 134, 204),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 26,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 48,
                    color: Color(0xFFC03B66),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    "quiz.missing_title".tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC03B66),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "quiz.missing_message".tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF4F4F4F),
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 26),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC03B66),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                          elevation: 3,
                        shadowColor:
                            const Color(0xFFC03B66).withOpacity(0.3),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "quiz.missing_button".tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Popup de resultado
  void showResultPopup(String resultTitle, String resultDesc) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                resultTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFE2377D),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                resultDesc,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE2377D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text("quiz.result_close".tr()),
              )
            ],
          ),
        ),
      ),
    );
  }

  bool _allQuestionsAnswered() {
    final questions = quizData?["questions"];
    if (questions == null) return false;

    for (int i = 0; i < questions.length; i++) {
      if (!selectedOptions.containsKey(i)) return false;
    }
    return true;
  }

  // Lista de perguntas
  List<Widget> _buildQuestionsList() {
    final questions = quizData?["questions"];
    if (questions == null) return [];

    return List.generate(questions.length, (i) {
      final question = getLocalized(
        questions[i]["text"],
        questions[i]["text_en"],
      );

      final options = List<String>.from(
        questions[i]["options"]?.map(
              (o) => getLocalized(o["text"], o["text_en"]),
            ) ??
            [],
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),

          Text(
            question,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE2377D),
            ),
          ),

          const SizedBox(height: 12),

          ...List.generate(options.length, (optIndex) {
            final isSelected = selectedOptions[i] == optIndex;

            return GestureDetector(
              onTap: () => setState(() => selectedOptions[i] = optIndex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE2377D).withOpacity(0.12)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFE2377D)
                        : Colors.grey.shade300,
                    width: 1.4,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 18,
                      color: isSelected
                          ? const Color(0xFFE2377D)
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        options[optIndex],
                        style: TextStyle(
                          fontSize: 15.5,
                          color: isSelected
                              ? const Color(0xFFE2377D)
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      );
    });
  }

  // SUBMIT FINAL
  void _submit() {
    final questions = quizData?["questions"];
    final results = quizData?["results"];

    if (questions == null || results == null) return;

    if (!_allQuestionsAnswered()) {
      showMissingAnswersCutePopup(context);
      return;
    }

    if (!userIsPremium) {
      showPremiumPrompt(context);
      return;
    }

    final result = results[0];
    final title = getLocalized(result["title"], result["title_en"]);
    final desc = getLocalized(result["desc"], result["desc_en"]);

    showResultPopup(title, desc);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE2377D)),
      );
    }

    return MonthPageTemplate(
      month: widget.month,
      year: widget.year,
      title: "",
      pageLabel: "quiz.page_label".tr(),
      labelColor: const Color(0xFFE9B9C9),

      description: getLocalized(
        quizData?["description"],
        quizData?["description_en"],
      ),

      child: Column(
        children: [
          const SizedBox(height: 12),
          ..._buildQuestionsList(),
          const SizedBox(height: 28),

          // BOTÃO RESULTADO
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE2377D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _submit,
              child: Text(
                "quiz.button_result".tr(),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          TextButton(
            onPressed: () => setState(() => selectedOptions.clear()),
            child: Text(
              "quiz.button_retry".tr(),
              style: const TextStyle(
                color: Color(0xFFE2377D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
