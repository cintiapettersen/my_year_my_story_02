import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:myyearmystory/screens/popups/popup_login.dart';

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
  int _currentPage = 0;

  final PageController _pageController = PageController();

  List<String> _questions = [];
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

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Premium é carregado, mas NÃO controla acesso à página
    _isPremiumUser = await AccessControl.isPremium();
    await _loadQuestions();

    if (mounted) setState(() {});
  }

  Future<void> _loadQuestions() async {
    final language = context.locale.languageCode;

    final res = await SupabaseConfig.client
        .from('curiosities_entries')
        .select('questions, questions_en')
        .eq('month', widget.month)
        .order('group_number');

    final allQuestions = <String>[];

    for (final row in res) {
      final questions = language == 'en'
          ? List<String>.from(row['questions_en'] ?? [])
          : List<String>.from(row['questions'] ?? []);
      allQuestions.addAll(questions);
    }

    _questions = allQuestions;
    _controllers =
        List.generate(_questions.length, (_) => TextEditingController());
  }

  // 🔐 Login / Premium SÓ AQUI
  Future<void> _saveAnswers() async {
    final user = SupabaseConfig.client.auth.currentUser;

    // 👤 Convidado
    if (user == null) {
      showLoginPrompt(context);
      return;
    }

    // 👤 Free
    if (!_isPremiumUser) {
      showPremiumPopup(context);
      return;
    }

    final answers =
        _controllers.map((c) => c.text.trim()).toList(growable: false);

    await SupabaseConfig.client.from('entries').upsert(
      {
        'user_id': user.id,
        'year': widget.year,
        'month': widget.month,
        'curiosities_answers': answers,
      },
      onConflict: 'user_id, year, month',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFFDF0F4),
        content: Text(
          'curiosities.saved_success'.tr(),
          style: const TextStyle(color: Colors.black),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MonthPageTemplate(
      month: widget.month,
      year: widget.year,
      title: '',
      pageLabel: 'curiosities.title'.tr(),
      labelColor: const Color(0xFFc79fe2),
      description: 'curiosities.description_fixed'.tr(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            if (_questions.isNotEmpty)
              Text(
                '${_currentPage + 1} / ${_questions.length}',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),

            const SizedBox(height: 12),

            SizedBox(
              height: 320,
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _questions.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite,
                        color: heartColors[index % heartColors.length],
                        size: 22,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _questions[index],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFBD3E7D),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _controllers[index],
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'curiosities.answer_hint'.tr(),
                          filled: true,
                          fillColor: const Color(0xFFFCEAF4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _saveAnswers,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE25BA6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text('curiosities.save'.tr()),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 18),
                  onPressed: _currentPage > 0
                      ? () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          )
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 18),
                  onPressed: _currentPage < _questions.length - 1
                      ? () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
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

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }
}
