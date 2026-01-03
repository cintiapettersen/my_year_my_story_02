import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  String? quizTitle;
  String? resultTitleOnPage;
  String? resultDescOnPage;

  late PageController _pageController;
  int currentPage = 0; // 👈 contador

  String get _quizStoragePrefix =>
      _isPremiumUser ? "premium" : "guest";

  /* ---------------- FREE MONTH LOGIC ---------------- */

  Future<bool> _isWithinFreeMonth() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString("first_quiz_date");

    if (stored == null) {
      await prefs.setString(
        "first_quiz_date",
        DateTime.now().toIso8601String(),
      );
      return true;
    }

    final first = DateTime.parse(stored);
    return DateTime.now()
        .isBefore(first.add(const Duration(days: 30)));
  }

  /* ---------------- INIT ---------------- */

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializePage();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializePage() async {
    await _checkPremiumStatus();
    await _loadQuiz();
    await _loadSavedAnswers();
    await _loadSavedResult();

      if (resultTitleOnPage != null) {
      currentPage = quizData?["questions"]?.length ?? 0;
    }
    setState(() => loading = false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (resultTitleOnPage != null) {
        final qLen = quizData?["questions"]?.length ?? 0;
        _pageController.jumpToPage(qLen);
      }
    });
  }

  /* ---------------- DATA ---------------- */

  Future<void> _checkPremiumStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email;
    final isPremium = await AccessControl.isPremium();
    _isPremiumUser = isPremium || AppConfig.isAdmin(email);
  }

  Future<void> _loadQuiz() async {
    final data = await Supabase.instance.client
        .from("quizzes")
        .select()
        .eq("month", widget.month)
        .maybeSingle();

    if (data == null) return;

     quizData = data;
    quizTitle = _getLocalized(
      data["title"],
      data["title_en"],
    );
  }

  String _getLocalized(String? pt, String? en) {
    final lang = context.locale.languageCode;
    if (lang == "en" && en != null && en.isNotEmpty) return en;
    return pt ?? "";
  }

  /* ---------------- STORAGE ---------------- */

  Future<void> _saveAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
      "quiz_${_quizStoragePrefix}_${widget.month}_${widget.year}_answers",
      jsonEncode(selectedOptions),
    );
  }

  Future<void> _loadSavedAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(
      "quiz_${_quizStoragePrefix}_${widget.month}_${widget.year}_answers",
    );

    if (saved != null) {
      selectedOptions =
          Map<int, int>.from(jsonDecode(saved));
    }
  }

  Future<void> _loadSavedResult() async {
    final prefs = await SharedPreferences.getInstance();
    resultTitleOnPage = prefs.getString(
      "quiz_${_quizStoragePrefix}_${widget.month}_${widget.year}_result_title",
    );
    resultDescOnPage = prefs.getString(
      "quiz_${_quizStoragePrefix}_${widget.month}_${widget.year}_result_desc",
    );
  }

  /* ---------------- SUBMIT ---------------- */

  void _submit() async {
  final results = quizData?["results"];
  if (results == null || results.isEmpty) return;

  final Map<String, int> typeCount = {};

  for (final entry in selectedOptions.entries) {
    final int q = entry.key;
    final int o = entry.value;

    final String? tipo =
        quizData?["questions"][q]["options"][o]["tipo"];

    if (tipo != null) {
      typeCount[tipo] = (typeCount[tipo] ?? 0) + 1;
    }
  }

  if (typeCount.isEmpty) return;

  final sorted = typeCount.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final int maxValue = sorted.first.value;

  final tied =
      sorted.where((e) => e.value == maxValue).toList();

  String winningType;

  if (tied.length == 1) {
    winningType = tied.first.key;
  } else {
    // empate → usa a última resposta
    final lastQuestionIndex =
        selectedOptions.keys.reduce((a, b) => a > b ? a : b);

    final lastOptionIndex =
        selectedOptions[lastQuestionIndex]!;

    winningType = quizData?["questions"]
        [lastQuestionIndex]["options"]
        [lastOptionIndex]["tipo"];
  }

  // 🔎 agora TEM que existir
  final result = results.firstWhere(
    (r) => r["tipo"] == winningType,
  );

  final title =
      _getLocalized(result["title"], result["title_en"]);
  final desc =
      _getLocalized(result["desc"], result["desc_en"]);

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    "quiz_${_quizStoragePrefix}_${widget.month}_${widget.year}_result_title",
    title,
  );
  await prefs.setString(
    "quiz_${_quizStoragePrefix}_${widget.month}_${widget.year}_result_desc",
    desc,
  );

  setState(() {
    resultTitleOnPage = title;
    resultDescOnPage = desc;
    currentPage = quizData?["questions"]?.length ?? 0;
  });

  final qLen = quizData?["questions"]?.length ?? 0;
  _pageController.jumpToPage(qLen);
}


  /* ---------------- UI ---------------- */

  int get totalPages =>
      (quizData?["questions"]?.length ?? 0) + 1;

  Widget _buildQuestionPage(int i) {
    final q = quizData?["questions"][i];
    if (q == null) return const SizedBox();

    final options = List<String>.from(
      q["options"].map(
        (o) => _getLocalized(o["text"], o["text_en"]),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        color: const Color(0xFFF8DFF0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
  _getLocalized(q["text"], q["text_en"]),
  style: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  ),
),

                const SizedBox(height: 16),
                ...List.generate(
                  options.length,
                  (opt) => _buildOption(i, opt, options),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

 Widget _buildOption(
  int qIndex,
  int opt,
  List<String> options,
) {
  final isSelected = selectedOptions[qIndex] == opt;

  final totalQuestions = quizData?["questions"]?.length ?? 0;
  final isLastQuestion = qIndex == totalQuestions - 1;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      GestureDetector(
        onTap: () {
          setState(() {
            selectedOptions[qIndex] = opt;
          });
          _saveAnswers();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE2377D).withOpacity(0.12)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFE2377D)
                  : Colors.grey.shade300,
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
                  options[opt],
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),

      if (isSelected)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              if (isLastQuestion) {
                _submit();
              } else {
                setState(() {
                  currentPage++;
                });

                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            },
            child: Text(
              isLastQuestion
                  ? "quiz.button_result".tr()
                  : "quiz.next".tr(),
              style: const TextStyle(
                color: Color(0xFFE2377D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
    ],
  );
}


  Widget _buildResultPage() {
  return FutureBuilder<bool>(
    future: _isWithinFreeMonth(),
    builder: (context, snap) {
      if (!snap.hasData) {
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFE2377D),
          ),
        );
      }

      final canSeeResult = _isPremiumUser || snap.data!;

      // 🔒 BLOQUEADO (fim do mês grátis)
      if (!canSeeResult) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 4,
            color: const Color(0xFFF8DFF0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock,
                    size: 36,
                    color: Color(0xFFE2377D),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "quiz.premium_only".tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE2377D),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "quiz.premium_desc".tr(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => showPremiumPopup(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE2377D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text("quiz.unlock".tr()),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // ✨ RESULTADO LIBERADO
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 4,
              color: const Color(0xFFFDE6EF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite,
                      size: 40,
                      color: Color(0xFFE2377D),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      resultTitleOnPage ?? "",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'mono',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: Color(0xFFE2377D),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      resultDescOnPage ?? "",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Color(0xFF4F4F4F),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 🔁 refazer quiz (se quiser manter)
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();

                await prefs.remove(
                  "quiz_${_quizStoragePrefix}_${widget.month}_${widget.year}_answers",
                );
                await prefs.remove(
                  "quiz_${_quizStoragePrefix}_${widget.month}_${widget.year}_result_title",
                );
                await prefs.remove(
                  "quiz_${_quizStoragePrefix}_${widget.month}_${widget.year}_result_desc",
                );

                setState(() {
  selectedOptions.clear();
  resultTitleOnPage = null;
  resultDescOnPage = null;
  currentPage = 0;
});

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_pageController.hasClients) {
                    _pageController.jumpToPage(0);
                  }
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
          ],
        ),
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasResult = resultTitleOnPage != null;

    if (hasResult) {
      return _buildResultPage();
    }

    return Column(
      children: [
        if (quizTitle != null)
  Padding(
    padding: const EdgeInsets.only(
      top: 4,
      bottom: 12,
      left: 16,
      right: 16,
    ),
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8DFF0), // 💗 rosa clarinho
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        quizTitle!,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF9E4A6E),
          letterSpacing: 0.6,
        ),
      ),
    ),
  ),

       Column(
  children: [
    if (!hasResult &&
        currentPage < (quizData?["questions"]?.length ?? 0))
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          "${currentPage + 1}/${quizData?["questions"]?.length ?? 0}",
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9E4A6E),
          ),
        ),
      ),

    SizedBox(
      height: 420,
      child: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: totalPages,
        itemBuilder: (context, index) {
          final qLen =
              quizData?["questions"]?.length ?? 0;
          return index < qLen
              ? _buildQuestionPage(index)
              : _buildResultPage();
        },
      ),
    ),
  ],
),
      ],
    );
  }
}