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

String get _quizStoragePrefix {
  return _isPremiumUser ? "premium" : "guest";
}


  String? resultTitleOnPage;
  String? resultDescOnPage;

  late PageController _pageController;
  //int _currentPage = 0;
  



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
    setState(() => loading = false);
    
     WidgetsBinding.instance.addPostFrameCallback((_) {
    if (resultTitleOnPage != null) {
      final qLen = quizData?["questions"]?.length ?? 0;
      _pageController.jumpToPage(qLen);
    }
  });
}
  

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

    quizData = data;
  }

  String getLocalized(String? pt, String? en) {
    final lang = Localizations.localeOf(context).languageCode;
    if (lang == "en" && en != null && en.trim().isNotEmpty) {
      return en;
    }
    return pt ?? "";
  }

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
    selectedOptions = Map<int, int>.from(jsonDecode(saved));
  }
}


  Future<void> _saveResult(String title, String desc) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    "quiz_${_quizStoragePrefix}_${widget.month}_${widget.year}_result_title",
    title,
  );
  await prefs.setString(
    "quiz_${_quizStoragePrefix}_${widget.month}_${widget.year}_result_desc",
    desc,
  );
}

Future<void> _loadSavedResult() async {
  if (!_isPremiumUser) {
    resultTitleOnPage = null;
    resultDescOnPage = null;
    return;
  }

  final prefs = await SharedPreferences.getInstance();

  resultTitleOnPage = prefs.getString(
    "quiz_${_quizStoragePrefix}_${widget.month}_${widget.year}_result_title",
  );

  resultDescOnPage = prefs.getString(
    "quiz_${_quizStoragePrefix}_${widget.month}_${widget.year}_result_desc",
  );
}



 

  int get totalPages {
    final q = quizData?["questions"]?.length ?? 0;
    return q + 1;
  }
  Widget _buildQuestionPage(int i) {
    final questions = quizData?["questions"];
    if (questions == null) return const SizedBox();

    final question = getLocalized(
      questions[i]["text"],
      questions[i]["text_en"],
    );



    final options = List<String>.from(
      questions[i]["options"].map(
        (o) => getLocalized(o["text"], o["text_en"]),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        color: const Color(0xFFFDE6EF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
         child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Text(
                "quiz.question_counter".tr(
                  args: ["${i + 1}", "${questions.length}"],
                ),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9E4A6E),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                question,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFBD3A70),
                ),
              ),
              const SizedBox(height: 16),

              ...List.generate(
                options.length,
                (optIdx) => _buildOption(i, optIdx, options),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}


Widget _buildAnswersSummary() {
  final questions = quizData?["questions"];
  if (questions == null) return const SizedBox();

  return Column(
    children: List.generate(questions.length, (i) {
      final selected = selectedOptions[i];
      if (selected == null) return const SizedBox();

      final question = getLocalized(
        questions[i]["text"],
        questions[i]["text_en"],
      );

      final answer = getLocalized(
        questions[i]["options"][selected]["text"],
        questions[i]["options"][selected]["text_en"],
      );

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE2377D).withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE2377D).withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFFBD3A70),
              ),
            ),
            const SizedBox(height: 6),
            Text(answer),
          ],
        ),
      );
    }),
  );
}




  Widget _buildOption(int questionIndex, int optIdx, List<String> options) {
    final isSelected = selectedOptions[questionIndex] == optIdx;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              selectedOptions[questionIndex] = optIdx;
            });
            _saveAnswers();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFE2377D).withValues(alpha: 0.12)
                  : Colors.white,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFE2377D)
                    : Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.favorite,
                  size: 18,
                  color: isSelected
                      ? const Color(0xFFE2377D)
                      : Colors.grey[400],
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(options[optIdx])),
              ],
            ),
          ),
        ),

        if (isSelected)
  Align(
    alignment: Alignment.centerRight,
    child: TextButton(
      onPressed: () {
        final totalQuestions = quizData?["questions"]?.length ?? 0;

        if (questionIndex == totalQuestions - 1) {
          // 🏁 ÚLTIMA PERGUNTA → calcula resultado
          _submit();
        } else {
          // ➡️ Próxima pergunta
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      },
      child: Text(
        questionIndex == (quizData?["questions"]?.length ?? 1) - 1
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

  void _submit() async {
  // 🔒 bloqueia resultado para não premium
  if (!_isPremiumUser) {
    showPremiumPopup(context);
    return;
  }

  final results = quizData?["results"];
  if (results == null || results.isEmpty) return;

  // 🔢 soma das respostas selecionadas
  // 🧠 conta quantas vezes cada opção foi escolhida
final Map<int, int> optionCount = {};

for (final opt in selectedOptions.values) {
  optionCount[opt] = (optionCount[opt] ?? 0) + 1;
}

// 🎯 pega a opção mais escolhida
final sorted = optionCount.entries.toList()
  ..sort((a, b) => b.value.compareTo(a.value));

final resultIndex = sorted.first.key;

final result = results[resultIndex];

  final title = getLocalized(result["title"], result["title_en"]);
  final desc = getLocalized(result["desc"], result["desc_en"]);

  // 💾 salva resultado
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    "quiz_${_quizStoragePrefix}_${widget.month}_${widget.year}_result_title",
    title,
  );
  await prefs.setString(
    "quiz_${_quizStoragePrefix}_${widget.month}_${widget.year}_result_desc",
    desc,
  );

  // 🧠 atualiza estado
  setState(() {
    resultTitleOnPage = title;
    resultDescOnPage = desc;
  });

  // 👉 pula para a página final (resultado)
  final qLen = quizData?["questions"]?.length ?? 0;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_pageController.hasClients) {
      _pageController.jumpToPage(qLen);
    }
  });
}



Widget _buildResultPage() {
  // 🔒 VISÃO PARA NÃO PREMIUM
  if (!_isPremiumUser) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        color: const Color(0xFFFDE6EF),
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

  // ✨ VISÃO PARA PREMIUM (RESULTADO)
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Card(
          elevation: 4,
          color: const Color(0xFFFDE6EF), // 💗 rosinha suave
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.favorite, // ❤️ coração sólido
                  size: 36,
                  color: Color(0xFFE2377D),
                ),
                const SizedBox(height: 10),
                Text(
                  resultTitleOnPage ?? "",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'mono',
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: Color(0xFFE2377D),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  resultDescOnPage ?? "",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 🔁 REFAZER QUIZ (premium)
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
}

  

  @override
Widget build(BuildContext context) {
  // 🔹 1. loading sempre vem primeiro
  if (loading) {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFFE2377D),
      ),
    );
  }

  // 🔹 2. estado do resultado (somente premium)
  final hasResult = _isPremiumUser && resultTitleOnPage != null;

  // 🔹 3. se já tem resultado → mostra só o card final
  // (libera o swipe da página do mês)
  if (hasResult) {
    return _buildResultPage();
  }

  // 🔹 4. se ainda está respondendo → PageView do quiz
  return SizedBox(
    height: 420, // altura fixa pro PageView existir
    child: PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalPages,
      itemBuilder: (context, index) {
        final qLen = quizData?["questions"]?.length ?? 0;

        if (index < qLen) {
          return _buildQuestionPage(index);
        }

        return _buildResultPage();
      },
    ),
  );
}

}
