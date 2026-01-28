import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:myyearmystory/screens/popups/popup_login.dart';
import 'dart:async';


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

  int _currentPage = 0;

  final PageController _pageController = PageController();


  late final StreamSubscription _authSub; 

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

  _authSub = SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
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
  if (_initialized) {
  _loadQuestions().then((_) {
    _loadSavedAnswers();
  });
}
}

  Future<void> _initialize() async {
  _isPremiumUser = await AccessControl.isPremium();
  await _loadQuestions();
  await _loadSavedAnswers(); // 👈 ESSENCIAL
  _initialized = true;
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

  // guarda textos atuais (ex: troca de idioma sem perder digitação)
  final Map<int, String> tempAnswers = {};
  for (int i = 0; i < _controllers.length; i++) {
    tempAnswers[i] = _controllers[i].text;
  }

  // limpa controllers antigos
  for (final c in _controllers) {
    c.dispose();
  }

  _questions = allQuestions;

  // cria controllers vazios (ou com o que já estava digitado)
  _controllers = List.generate(
    _questions.length,
    (i) => TextEditingController(
      text: tempAnswers[i] ?? '',
    ),
  );

  if (mounted) setState(() {});
}


//_loadSavedAnswers

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

  List<Map<String, dynamic>> savedCuriosities = [];

  if (saved != null && saved['curiosities'] is List) {
    savedCuriosities = (saved['curiosities'] as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  final Map<int, String> answeredMap = {
    for (final c in savedCuriosities)
      if (c['index'] != null && c['answer'] != null)
        int.tryParse(c['index'].toString())!: c['answer'] as String,
  };

  for (int i = 0; i < _controllers.length; i++) {
    _controllers[i].text = answeredMap[i] ?? '';
  }

  if (mounted) setState(() {});
}

  // =====================================================
  // SALVAR RESPOSTA
  // =====================================================
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

  // 🔥 remove resposta anterior pelo INDEX (não pelo texto)
  curiosities.removeWhere((c) =>
    c['index'] != null &&
    int.tryParse(c['index'].toString()) == index
  );

  if (!_isPremiumUser && curiosities.length >= 3) {
    showPremiumPopup(context);
    return;
  }

  // ✅ salva no formato novo e estável
  curiosities.add({
    'index': index,
    'answer': answer,
  });

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

  // =====================================================
  // BUILD
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return MonthPageTemplate(
      month: widget.month,
      year: widget.year,
      title: '',
      pageLabel: 'curiosities.title'.tr(),
      labelColor: const Color(0xFFc79fe2),
      description: 'curiosities.description_fixed'.tr(),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              if (_questions.isNotEmpty &&
                  _controllers.length == _questions.length)
                Text(
                  '${_currentPage + 1} / ${_questions.length}',
                  style:
                      const TextStyle(fontSize: 13, color: Colors.black54),
                ),

              const SizedBox(height: 12),

              SizedBox(
                height: 320,
                child: (!_initialized)
                    ? const Center(child: CircularProgressIndicator())
                    : PageView.builder(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _questions.length,
                        onPageChanged: (i) =>
                            setState(() => _currentPage = i),
                        itemBuilder: (context, index) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.favorite,
                                color: heartColors[
                                    index % heartColors.length],
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
                                  hintText:
                                      'curiosities.answer_hint'.tr(),
                                  filled: true,
                                  fillColor:
                                      const Color(0xFFFCEAF4),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () =>
                                    _saveCurrentAnswer(index),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFFE25BA6),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(30),
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
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        size: 18),
                    onPressed: _currentPage > 0
                        ? () => _pageController.previousPage(
                              duration: const Duration(
                                  milliseconds: 250),
                              curve: Curves.easeOut,
                            )
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios,
                        size: 18),
                    onPressed:
                        _currentPage < _questions.length - 1
                            ? () => _pageController.nextPage(
                                  duration: const Duration(
                                      milliseconds: 250),
                                  curve: Curves.easeOut,
                                )
                            : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

 
}
