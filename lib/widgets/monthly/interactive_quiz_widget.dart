import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:myyearmystory/utils/app_config.dart';

import 'package:myyearmystory/widgets/shared/remote_data_wrapper.dart';


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

  String _toSentenceCase(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    final lower = trimmed.toLowerCase();
    final chars = lower.characters;
    return '${chars.first.toUpperCase()}${chars.skip(1)}';
  }
  bool _isPremiumUser = false;

  bool hasSavedResult = false;
  bool _isLoading = true;
  bool _hasError = false;
  bool _initialized = false;
  

  String? quizTitle;
  String? resultTitleOnPage;
  String? resultDescOnPage;

  late PageController _pageController;
  int currentPage = 0;

  String _getLocalized(String? pt, String? en) {
  final lang = context.locale.languageCode;
  if (lang == "en" && en != null && en.isNotEmpty) return en;
  return pt ?? "";
}

  /* ---------------- INIT ---------------- */

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializePage() async {
  try {
    _isLoading = true;
    _hasError = false;

    await _checkPremiumStatus();
    await _loadQuiz();

    _initialized = true;
  } catch (e) {
    _hasError = true;
  } finally {
    _isLoading = false;
    if (mounted) setState(() {});
  }
}



  @override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (!_initialized) {
    _initializePage();
  }
}


  /* ---------------- DATA ---------------- */

Future<void> _checkPremiumStatus() async {
  final user = Supabase.instance.client.auth.currentUser;
  final email = user?.email;
  final isPremium = await AccessControl.isPremium();
  _isPremiumUser = isPremium || AppConfig.isAdmin(email);
}

Future<void> _loadQuiz() async {
  try {
    // 1️⃣ Carrega o quiz do mês
    final data = await Supabase.instance.client
        .from("quizzes")
        .select()
        .eq("month", widget.month)
        .maybeSingle();

    if (data == null) return;

    quizData = data;
    quizTitle = _getLocalized(data["title"], data["title_en"]);

    // 2️⃣ Busca o tipo salvo na entries
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final entry = await Supabase.instance.client
        .from('entries')
        .select('quiz_result_type')
        .eq('user_id', user.id)
        .eq('month', widget.month)
        .eq('year', widget.year)
        .maybeSingle();

    if (!mounted) return;

    final String? savedType = entry?['quiz_result_type'];
    if (savedType == null) return;

    // 3️⃣ Reconstrói o resultado usando quizzes.results
    final List results = quizData?['results'] ?? [];

    Map<String, dynamic>? result;

    for (final r in results) {
      if (r is Map && r['tipo'] == savedType) {
        result = Map<String, dynamic>.from(r);
        break;
      }
    }

    if (result != null && mounted) {
      final String? title   = result['title'] as String?;
      final String? titleEn = result['title_en'] as String?;
      final String? desc    = result['desc'] as String?;
      final String? descEn  = result['desc_en'] as String?;

      setState(() {
        hasSavedResult = true;
        resultTitleOnPage = _getLocalized(title, titleEn);
        resultDescOnPage  = _getLocalized(desc, descEn);
      });
    }

  } catch (e) {
   

    // 🔥 ESSA LINHA É A DIFERENÇA
    rethrow;
  }
}


  /* ---------------- SUBMIT ---------------- */

  Future<void> _submit() async {
    final results = quizData?["results"];
    if (results == null || results.isEmpty) return;

    final Map<String, int> typeCount = {};

    for (final entry in selectedOptions.entries) {
      final q = entry.key;
      final o = entry.value;

      final String? tipo =
          quizData?["questions"][q]["options"][o]["tipo"];

      if (tipo != null) {
        typeCount[tipo] = (typeCount[tipo] ?? 0) + 1;
      }
    }

    if (typeCount.isEmpty) return;

    final sorted = typeCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxValue = sorted.first.value;
    final tied = sorted.where((e) => e.value == maxValue).toList();

    String winningType;

    if (tied.length == 1) {
      winningType = tied.first.key;
    } else {
      final lastQuestionIndex =
          selectedOptions.keys.reduce((a, b) => a > b ? a : b);

      final lastOptionIndex =
          selectedOptions[lastQuestionIndex]!;

      winningType = quizData?["questions"]
          [lastQuestionIndex]["options"]
          [lastOptionIndex]["tipo"];
    }

    final result = results.firstWhere(
  (r) => r["tipo"] == winningType,
  orElse: () => null,
);

if (result == null) return;

    setState(() {
  // título do resultado NÃO vem do banco
  // vem do tipo (ou depois você pode mapear pra algo bonito)
  resultTitleOnPage =
    _getLocalized(result["title"], result["title_en"]);


  // descrição REAL vem do quizzes.results
  resultDescOnPage =
      _getLocalized(result["desc"], result["desc_en"]);

  // continua igual
  currentPage = quizData?["questions"]?.length ?? 0;
});

    final user = Supabase.instance.client.auth.currentUser;

if (user != null) {
  await Supabase.instance.client
      .from('entries')
      .upsert(
        {
          'user_id': user.id,
          'month': widget.month,
          'year': widget.year,
          'quiz_result_type': winningType,
        },
        onConflict: 'user_id,year,month',
      );
}



    _pageController.jumpToPage(currentPage);
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

    // Matches the “new card” framed style used across recent monthly screens.
    const accent = Color(0xFFc79fe2);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.all(14),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8DFF0),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: accent.withValues(alpha: 0.18),
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getLocalized(q["text"], q["text_en"]),
                  style: const TextStyle(
                    fontFamily: 'poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color.fromARGB(255, 143, 46, 88),
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

  Widget _buildOption(int qIndex, int opt, List<String> options) {
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
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? const Color(0xFFE2377D).withValues(alpha: 0.12)
                      : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? const Color(0xFFE2377D) : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.favorite,
                  size: 18,
                  color:
                      isSelected
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
                  setState(() => currentPage++);
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
    final isLogged =
        Supabase.instance.client.auth.currentUser != null;

    if (!_isPremiumUser && isLogged) {
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
                    color: Color(0xFF9E4A6E),
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
                    color: Color.fromARGB(255, 223, 50, 122),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    resultTitleOnPage ?? "",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'mono',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(255, 191, 50, 109),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    resultDescOnPage ?? "",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Color.fromARGB(255, 12, 12, 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 🔁 REFazer quiz (mantido)
          TextButton(
  onPressed: () {
    setState(() {
      selectedOptions.clear();
      resultTitleOnPage = null;
      resultDescOnPage = null;
      currentPage = 0;

      // 🔥 ISSO É O QUE ESTAVA FALTANDO
      hasSavedResult = false;
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
  return RemoteDataWrapper(
    isLoading: _isLoading,
    hasError: _hasError && !hasSavedResult,

    onRetry: _initializePage,
    child: _buildQuizContent(),
  );
}

Widget _buildQuizContent() {
  final hasResult = hasSavedResult;
  const accent = Color(0xFFc79fe2);

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
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.all(10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8DFF0),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: accent.withValues(alpha: 0.26),
                  width: 1.6,
                ),
              ),
              child: Text(
                _toSentenceCase(quizTitle!),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(255, 153, 58, 99),
                ),
              ),
            ),
          ),
        ),

      const SizedBox(height: 6),

      SizedBox(
        height: 420,
        child: PageView.builder(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalPages,
          itemBuilder: (context, index) {
            final qLen = quizData?['questions']?.length ?? 0;

            return index < qLen
                ? _buildQuestionPage(index)
                : _buildResultPage();
          },
        ),
      ),
    ],
  );
}

}
