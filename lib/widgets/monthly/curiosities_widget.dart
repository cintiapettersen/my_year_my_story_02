import 'dart:async';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:myyearmystory/screens/popups/popup_login.dart';
import 'package:myyearmystory/widgets/shared/remote_data_wrapper.dart';
import 'package:myyearmystory/widgets/shared/app_pill_button.dart';
import 'package:myyearmystory/widgets/monthly/curiosity_fallback.dart';


class CuriositiesWidget extends StatefulWidget {
  final int month;
  final int year;

  const CuriositiesWidget({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<CuriositiesWidget> createState() => _CuriositiesWidgetState();
}

class _CuriositiesWidgetState extends State<CuriositiesWidget> {
  bool _isPremiumUser = false;
  bool _initialized = false;
  bool _isLoading = true;
  bool _hasError = false;

  

  int _currentPage = 0;

  final PageController _pageController = PageController();
  late final StreamSubscription _authSub;

  List<Map<String, String>> _questions = [];
  List<TextEditingController> _controllers = [];

  final List<Color> heartColors = const [
    Color(0xFFE57373),
    Color(0xFFF06292),
    Color(0xFFBA68C8),
    Color(0xFF9575CD),
    Color(0xFF64B5F6),
    Color(0xFF4DD0E1),
    Color(0xFF4DB6AC),
    Color(0xFFAED581),
    Color(0xFFFF8A65),
    Color(0xFFFFB74D),
  ];

  static const Color _aboutMeAccent = Color(0xFFc79fe2);

  @override
  void initState() {
    super.initState();

    _authSub =
        SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        _loadSavedAnswers();
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialize();
    }
  }


//INITIALIZAÇÃO

  Future<void> _initialize() async {
  try {
    _isLoading = true;
    _hasError = false;

    _isPremiumUser = await AccessControl.isPremium();
    await _loadQuestions();
    await _loadSavedAnswers();

    _initialized = true;
  } catch (e) {
    _hasError = true;
  } finally {
    _isLoading = false;
    if (mounted) setState(() {});
  }
}


  // ==============================
  // CARREGAR PERGUNTAS
  // ==============================
  Future<void> _loadQuestions() async {
    final language = context.locale.languageCode;

    final res = await SupabaseConfig.client
        .from('curiosities_entries')
        .select('questions, questions_en')
        .eq('year', widget.year)
        .eq('month', widget.month)
        .order('group_number');

    final List<Map<String, String>> allQuestions = [];
    var globalIndex = 0;

    for (final row in res) {
      final rawQuestions =
          language == 'en' ? row['questions_en'] : row['questions'];

      if (rawQuestions is List) {
        for (int i = 0; i < rawQuestions.length; i++) {
          final q = rawQuestions[i];
          if (q is String && q.trim().isNotEmpty) {
            allQuestions.add({
              'id': globalIndex.toString(),
              'text': q.trim(),
            });
            globalIndex++;
          }
        }
      }
    }

    if (allQuestions.isEmpty) {
      final fallback =
          language == 'en'
              ? (curiosityFallbackQuestionsEn[widget.month] ?? const [])
              : (curiosityFallbackQuestionsPt[widget.month] ?? const []);
      for (final q in fallback) {
        final text = q.trim();
        if (text.isEmpty) continue;
        allQuestions.add({'id': globalIndex.toString(), 'text': text});
        globalIndex++;
      }
    }

    

    // preserva respostas digitadas
    final Map<String, String> tempAnswers = {};
    for (int i = 0;
        i < _controllers.length && i < _questions.length;
        i++) {
      tempAnswers[_questions[i]['id']!] = _controllers[i].text;
    }

    for (final c in _controllers) {
      c.dispose();
    }

    _questions = allQuestions;
    _controllers = List.generate(
      _questions.length,
      (i) => TextEditingController(
        text: tempAnswers[_questions[i]['id']] ?? '',
      ),
    );

    if (mounted) setState(() {});
  }

  // ==============================
  // CARREGAR RESPOSTAS SALVAS
  // ==============================
  Future<void> _loadSavedAnswers() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    final saved = await SupabaseConfig.client
        .from('entries')
        .select('curiosities')
        .eq('user_id', user.id)
        .eq('year', widget.year)
        .eq('month', widget.month)
        .maybeSingle();

    if (saved == null || saved['curiosities'] is! List) return;

    final savedList = (saved['curiosities'] as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    for (final item in savedList) {
      final index = item['index'];
      final answer = item['answer'];
      if (index is int &&
          index < _controllers.length &&
          answer is String) {
        _controllers[index].text = answer;
      }
    }

    if (mounted) setState(() {});
  }

  // ==============================
  // SALVAR RESPOSTA
  // ==============================
  Future<void> _saveCurrentAnswer(int index) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      showLoginPrompt(context);
      return;
    }

    final answer = _controllers[index].text.trim();
    if (answer.isEmpty) return;

    final existing = await SupabaseConfig.client
        .from('entries')
        .select('curiosities')
        .eq('user_id', user.id)
        .eq('year', widget.year)
        .eq('month', widget.month)
        .maybeSingle();

    List<Map<String, dynamic>> curiosities = [];
    if (existing != null && existing['curiosities'] is List) {
      curiosities = (existing['curiosities'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    curiosities.removeWhere((c) => c['index'] == index);

    if (!_isPremiumUser && curiosities.length >= 3) {
      showPremiumPopup(context);
      return;
    }

    curiosities.add({'index': index, 'answer': answer});

    await SupabaseConfig.client.from('entries').upsert(
      {
        'user_id': user.id,
        'year': widget.year,
        'month': widget.month,
        'curiosities': curiosities,
      },
      onConflict: 'user_id, year, month',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    backgroundColor: const Color(0xFFE25BA6), // rosa do app 🌸
    content: Text(
      'curiosities.saved_success'.tr(),
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    ),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    margin: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 12,
    ),
    duration: const Duration(seconds: 2),
  ),
);
}


  // ==============================
  // BUILD
  // ==============================
@override
Widget build(BuildContext context) {
  return MonthPageTemplate(
    month: widget.month,
    year: widget.year,
    title: '',
    pageLabel: 'curiosities.title'.tr(),
    labelColor: _aboutMeAccent,
    description: 'curiosities.description_fixed'.tr(),

child: RemoteDataWrapper(
  isLoading: _isLoading,
  hasError: _hasError,
  onRetry: _initialize,
  child: Column(
    children: [
      if (_questions.isNotEmpty)
        Text(
          '${_currentPage + 1} / ${_questions.length}',
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        )
      else
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            'dashboard.no_curiosity_message'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black.withValues(alpha: 0.55)),
          ),
        ),

      const SizedBox(height: 12),

      if (_questions.isNotEmpty)
        SizedBox(
          height: 340,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: _questions.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, index) => LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight - 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite,
                          color: heartColors[index % heartColors.length],
                          size: 22,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _questions[index]['text'] ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFBD3E7D),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: _aboutMeAccent.withValues(alpha: 0.42),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFCEAF4),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: _aboutMeAccent.withValues(alpha: 0.18),
                                width: 1.2,
                              ),
                            ),
                            child: TextField(
                              controller: _controllers[index],
                              autocorrect: true,
                              enableSuggestions: true,
                              smartQuotesType: SmartQuotesType.enabled,
                              smartDashesType: SmartDashesType.enabled,
                              maxLines: 5,
                              decoration: InputDecoration(
                                hintText: 'curiosities.answer_hint'.tr(),
                                hintStyle: TextStyle(
                                  color: Colors.black.withValues(alpha: 0.35),
                                ),
                                filled: true,
                                fillColor: Colors.transparent,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppPillButton(
                          backgroundColor: _aboutMeAccent,
                          text: 'curiosities.save'.tr(),
                          onPressed: () => _saveCurrentAnswer(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

      const SizedBox(height: 12),

      if (_questions.isNotEmpty)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: _currentPage > 0
                  ? () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      )
                  : null,
            ),
            Row(
              children: List.generate(_questions.length, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 10 : 8,
                  height: isActive ? 10 : 8,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFE25BA6) : Colors.black26,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: _currentPage < _questions.length - 1
                  ? () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      )
                  : null,
            ),
          ],
        ),
    ],
  ),
),
  );
  }
}
