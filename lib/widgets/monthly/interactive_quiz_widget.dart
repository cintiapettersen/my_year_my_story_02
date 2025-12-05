import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:myyearmystory/utils/month_colors.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:myyearmystory/utils/app_config.dart';

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

  bool _isPremiumUser = false;

  // Resultado salvo
  String? resultTitleOnPage;
  String? resultDescOnPage;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  // ---------------------------------------------------
  // 🔄 Inicialização completa
  // ---------------------------------------------------
  Future<void> _initializePage() async {
    await _checkPremiumStatus();
    await _loadQuiz();
    await _loadSavedAnswers();
    await _loadSavedResult();

    setState(() => loading = false);
  }

  // ---------------------------------------------------
  // 🔑 PREMIUM + ADMIN
  // ---------------------------------------------------
  Future<void> _checkPremiumStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email;
    final isPremium = await AccessControl.isPremium();

    setState(() {
      _isPremiumUser = isPremium || AppConfig.isAdmin(email);
    });
  }

  // ---------------------------------------------------
  // 🔄 Carrega quiz do Supabase
  // ---------------------------------------------------
  Future<void> _loadQuiz() async {
    final data = await Supabase.instance.client
        .from("quizzes")
        .select()
        .eq("month", widget.month)
        .maybeSingle();

    quizData = data;
  }

  // ---------------------------------------------------
  // 🌸 Localização PT/EN
  // ---------------------------------------------------
  String getLocalized(String? pt, String? en) {
    final lang = Localizations.localeOf(context).languageCode;
    if (lang == "en" && en != null && en.trim().isNotEmpty) {
      return en;
    }
    return pt ?? "";
  }

  // ---------------------------------------------------
  // 💾 SALVAR RESPOSTAS
  // ---------------------------------------------------
  Future<void> _saveAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
      "quiz_${widget.month}_${widget.year}_answers",
      jsonEncode(selectedOptions),
    );
  }

  // ---------------------------------------------------
  // 🔄 CARREGAR RESPOSTAS
  // ---------------------------------------------------
  Future<void> _loadSavedAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    final saved =
        prefs.getString("quiz_${widget.month}_${widget.year}_answers");

    if (saved != null) {
      setState(() {
        selectedOptions = Map<int, int>.from(jsonDecode(saved));
      });
    }
  }

  // ---------------------------------------------------
  // 💾 SALVAR RESULTADO
  // ---------------------------------------------------
  Future<void> _saveResult(String title, String desc) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("quiz_${widget.month}_${widget.year}_result_title", title);
    prefs.setString("quiz_${widget.month}_${widget.year}_result_desc", desc);
  }

  // ---------------------------------------------------
  // 🔄 CARREGAR RESULTADO
  // ---------------------------------------------------
  Future<void> _loadSavedResult() async {
    final prefs = await SharedPreferences.getInstance();

    final t =
        prefs.getString("quiz_${widget.month}_${widget.year}_result_title");
    final d =
        prefs.getString("quiz_${widget.month}_${widget.year}_result_desc");

    if (t != null && d != null) {
      setState(() {
        resultTitleOnPage = t;
        resultDescOnPage = d;
      });
    }
  }

  // ---------------------------------------------------
  // ⚠️ Popup faltando respostas
  // ---------------------------------------------------
  void showMissingAnswersCutePopup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFE086CC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 48, color: Color(0xFFC03B66)),
            const SizedBox(height: 12),
            Text(
              "quiz.missing_title".tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC03B66),
              ),
            ),
            const SizedBox(height: 8),
            Text("quiz.missing_message".tr(),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC03B66)),
              onPressed: () => Navigator.pop(context),
              child: Text("quiz.missing_button".tr()),
            ),
          ],
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

  // ---------------------------------------------------
  // 🔮 Lista de perguntas
  // ---------------------------------------------------
  List<Widget> _buildQuestionsList() {
    final questions = quizData?["questions"];
    if (questions == null) return [];

    return List.generate(questions.length, (i) {
      final question = getLocalized(
        questions[i]["text"],
        questions[i]["text_en"],
      );

      final options = List<String>.from(
        questions[i]["options"].map(
              (o) => getLocalized(o["text"], o["text_en"]),
            ),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          Text(
            question,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFFBD3A70),
            ),
          ),
          const SizedBox(height: 10),

          ...List.generate(options.length, (optIdx) {
            final isSelected = selectedOptions[i] == optIdx;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedOptions[i] = optIdx;
                });
                _saveAnswers(); // salva imediatamente
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE2377D).withOpacity(0.12)
                      : Colors.white,
                  border: Border.all(
                    color:
                        isSelected ? const Color(0xFFE2377D) : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.favorite,
                        size: 18,
                        color: isSelected
                            ? const Color(0xFFE2377D)
                            : Colors.grey[400]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        options[optIdx],
                        style: TextStyle(
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

  // ---------------------------------------------------
  // 🎉 SUBMIT FINAL
  // ---------------------------------------------------
  void _submit() {
    final results = quizData?["results"];
    if (results == null) return;

    if (!_allQuestionsAnswered()) {
      showMissingAnswersCutePopup();
      return;
    }

    if (!_isPremiumUser) {
      showPremiumPopup(context);
      return;
    }

    final result = results[0];
    final title = getLocalized(result["title"], result["title_en"]);
    final desc = getLocalized(result["desc"], result["desc_en"]);

    setState(() {
      resultTitleOnPage = title;
      resultDescOnPage = desc;
    });

    _saveResult(title, desc);
  }

  // ---------------------------------------------------
  // 🖼️ UI
  // ---------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE2377D)),
      );
    }

    final buttonColor = getMonthColor(widget.month);

    final quizTitle = getLocalized(quizData?["title"], quizData?["title_en"]);
    final quizDesc =
        getLocalized(quizData?["description"], quizData?["description_en"]);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // TÍTULO
          Text(
            quizTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE2377D),
            ),
          ),

          // DESCRIÇÃO
          if (quizDesc.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 18),
              child: Text(
                quizDesc,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
            ),

          // PERGUNTAS
          ..._buildQuestionsList(),
          const SizedBox(height: 20),

          // BOTÃO
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _submit,
            child: Text(
              "quiz.button_result".tr(),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(height: 10),

          // RESET
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              prefs.remove("quiz_${widget.month}_${widget.year}_answers");
              prefs.remove("quiz_${widget.month}_${widget.year}_result_title");
              prefs.remove("quiz_${widget.month}_${widget.year}_result_desc");

              setState(() {
                selectedOptions.clear();
                resultTitleOnPage = null;
                resultDescOnPage = null;
              });
            },
            child: Text(
              "quiz.button_retry".tr(),
              style: const TextStyle(
                color: Color(0xFFE2377D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // RESULTADO
          if (resultTitleOnPage != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFFE2377D)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resultTitleOnPage!,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE2377D)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    resultDescOnPage!,
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ]
        ],
      ),
    );
  }
}
