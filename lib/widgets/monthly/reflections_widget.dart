import 'package:flutter/material.dart';
import 'package:my_year_my_story/services/reflections_service.dart';
import 'package:my_year_my_story/supabase/supabase_config.dart';
import 'package:my_year_my_story/widgets/shared/month_page_template.dart';
import 'package:my_year_my_story/screens/premium/premium_popup.dart';

class ReflectionsWidget extends StatefulWidget {
  final int? month;
  final int? year;

  const ReflectionsWidget({
    super.key,
    this.month,
    this.year,
  });

  @override
  State<ReflectionsWidget> createState() => _ReflectionsWidgetState();
}

class _ReflectionsWidgetState extends State<ReflectionsWidget>
    with AutomaticKeepAliveClientMixin {
  final _supabase = SupabaseConfig.client;
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isOfflineMode = false;
  String? _currentUserId;
  bool isPremiumUser = false;
  int _insertCount = 0; // 💕 Controle de quantas inserções a usuária fez

  @override
  bool get wantKeepAlive => true;

  final List<Map<String, String>> _reflectionPrompts = [
    {
      'key': 'biggest_lesson',
      'title': 'Maior Aprendizado',
      'prompt': 'Qual foi o maior aprendizado que você teve este mês?'
    },
    {
      'key': 'most_grateful',
      'title': 'Maior Gratidão',
      'prompt': 'Pelo que você é mais grata neste mês?'
    },
    {
      'key': 'proudest_moment',
      'title': 'Momento de Orgulho',
      'prompt': 'Qual foi seu momento de maior orgulho este mês?'
    },
    {
      'key': 'biggest_challenge',
      'title': 'Maior Desafio',
      'prompt': 'Qual foi o maior desafio que você enfrentou e como o superou?'
    },
    {
      'key': 'personal_growth',
      'title': 'Crescimento Pessoal',
      'prompt': 'Como você cresceu como pessoa neste mês?'
    },
    {
      'key': 'unexpected_joy',
      'title': 'Alegria Inesperada',
      'prompt': 'Qual alegria inesperada você descobriu este mês?'
    },
    {
      'key': 'next_month_focus',
      'title': 'Foco Próximo Mês',
      'prompt': 'No que você quer focar no próximo mês?'
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAndLoad();
  }

  void _initializeControllers() {
    for (var prompt in _reflectionPrompts) {
      _controllers[prompt['key']!] = TextEditingController();
    }
  }

  Future<void> _initializeAndLoad() async {
    _currentUserId = _supabase.auth.currentUser?.id;
    _isOfflineMode = _currentUserId == null;

    await _checkPremiumStatus();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    });

    await _loadReflectionsData();
  }

  // 💎 Verifica status Premium ou convidado
  Future<void> _checkPremiumStatus() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() => isPremiumUser = false);
      return;
    }

    final response = await _supabase
        .from('users')
        .select('is_premium')
        .eq('id', user.id)
        .maybeSingle();

    setState(() {
      isPremiumUser = response != null && response['is_premium'] == true;
    });
  }

  Future<void> _loadReflectionsData() async {
    setState(() => _isLoading = true);
    try {
      if (_currentUserId != null) {
        final reflections = await ReflectionsService.getReflections(
          widget.month ?? DateTime.now().month,
          widget.year ?? DateTime.now().year,
          _currentUserId!,
        );

        reflections.forEach((key, value) {
          if (_controllers.containsKey(key)) {
            _controllers[key]!.text = value;
          }
        });
      } else {
        _isOfflineMode = true;
      }
    } catch (e) {
      debugPrint('Erro ao carregar reflexões: $e');
      _isOfflineMode = true;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveReflectionsData() async {
    final user = _supabase.auth.currentUser;

    // 🩶 Se convidado → popup login/premium
    if (user == null) {
      showPremiumPrompt(context);
      return;
    }

    // 💕 Logada, mas não premium → só 1 inserção antes de bloquear
    if (!isPremiumUser && _insertCount >= 1) {
      showPremiumPrompt(context);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final reflections = <String, String>{};
      for (var entry in _controllers.entries) {
        if (entry.value.text.trim().isNotEmpty) {
          reflections[entry.key] = entry.value.text.trim();
        }
      }

      final success = await ReflectionsService.saveReflections(
        reflections,
        widget.month ?? DateTime.now().month,
        widget.year ?? DateTime.now().year,
        user.id,
      );

      if (!isPremiumUser) _insertCount++; // 💕 Conta 1 inserção

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Reflexões salvas com sucesso!'
                : 'Erro ao salvar reflexões'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao salvar reflexões: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao salvar reflexões'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return MonthPageTemplate(
      month: widget.month ?? DateTime.now().month,
      year: widget.year ?? DateTime.now().year,
      title: 'Reflexões do Mês',
      child: AnimatedOpacity(
        opacity: _isLoading ? 0 : 1,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            const Text(
              'Tire um momento para refletir sobre seu mês: o que te fez crescer, '
                  'o que te desafiou e o que te trouxe alegria 💭',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 50),

            // 📝 Lista de reflexões
            ..._reflectionPrompts.asMap().entries.map((entry) {
              final index = entry.key;
              final prompt = entry.value;
              final controller = _controllers[prompt['key']!]!;

              return AnimatedOpacity(
                opacity: 1,
                duration: Duration(milliseconds: 300 + (index * 120)),
                curve: Curves.easeOut,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFF2D7E0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prompt['title']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFC03B66),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        prompt['prompt']!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller,
                        maxLines: 4,
                        readOnly:
                        !isPremiumUser && _insertCount >= 1, // 💕 bloqueia input
                        onTap: () {
                          if (!isPremiumUser && _insertCount >= 1) {
                            showPremiumPrompt(context);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Escreva sua reflexão aqui...',
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                            const BorderSide(color: Color(0xFFF2D7E0)),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFC03B66)),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFFF7FA),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 12,
                          ),
                        ),
                        style: const TextStyle(
                            fontSize: 15, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            // 💾 Botão salvar
            Center(
              child: GestureDetector(
                onTapDown: (_) => setState(() => _isSaving = true),
                onTapUp: (_) => Future.delayed(
                    const Duration(milliseconds: 200),
                        () => setState(() => _isSaving = false)),
                onTapCancel: () => setState(() => _isSaving = false),
                onTap: _saveReflectionsData,
                child: AnimatedScale(
                  scale: _isSaving ? 0.96 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: AnimatedOpacity(
                    opacity: 1,
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeIn,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC03B66),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Salvar Reflexões',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
