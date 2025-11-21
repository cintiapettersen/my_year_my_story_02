import 'package:flutter/material.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:myyearmystory/utils/label_colors.dart';

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
  bool _isLoading = false;
  bool _isPremiumUser = false;
  bool _isGuest = false;

  String _themeTitle = '';
  String _themeDescription = '';
  List<String> _questions = [];

  List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    await _checkUserStatus();
    await _loadThemeAndQuestions();
    await _loadSavedAnswers();
  }

  Future<void> _checkUserStatus() async {
    final user = SupabaseConfig.client.auth.currentUser;

    if (user == null) {
      setState(() {
        _isGuest = true;
        _isPremiumUser = false;
      });
      return;
    }

    final profile = await SupabaseConfig.client
        .from('profiles')
        .select('is_premium')
        .eq('id', user.id)
        .maybeSingle();

    setState(() {
      _isGuest = false;
      _isPremiumUser = profile?['is_premium'] ?? false;
    });
  }

  Future<void> _loadThemeAndQuestions() async {
    setState(() => _isLoading = true);

    try {
      final res = await SupabaseConfig.client
          .from('curiosities_entries')
          .select('theme_title, theme_description, questions')
          .eq('month', widget.month)
          .eq('year', widget.year)
          .maybeSingle();

      if (res != null) {
        _themeTitle = res['theme_title'] ?? '';
        _themeDescription = res['theme_description'] ?? '';
        _questions = List<String>.from(res['questions'] ?? []);

        _controllers = List.generate(
          _questions.length,
          (_) => TextEditingController(),
        );
      }
    } catch (e) {
      debugPrint('Erro ao carregar curiosities_entries: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSavedAnswers() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    try {
      final res = await SupabaseConfig.client
          .from('entries')
          .select('curiosities_answers')
          .eq('user_id', user.id)
          .eq('year', widget.year)
          .eq('month', widget.month)
          .maybeSingle();

      if (res != null && res['curiosities_answers'] != null) {
        final saved = List<String>.from(res['curiosities_answers']);
        for (int i = 0; i < _controllers.length; i++) {
          if (i < saved.length) {
            _controllers[i].text = saved[i];
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar respostas salvas: $e');
    }
  }

  Future<void> _saveAnswers() async {
    final user = SupabaseConfig.client.auth.currentUser;

    if (_isGuest || !_isPremiumUser) {
      showPremiumPopup(context);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final answers = _controllers.map((c) => c.text.trim()).toList();

      await SupabaseConfig.client.from('entries').upsert(
        {
          'user_id': user!.id,
          'year': widget.year,
          'month': widget.month,
          'curiosities_answers': answers,
        },
        onConflict: 'user_id, year, month',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Respostas salvas com sucesso!')),
      );
    } catch (e) {
      debugPrint('Erro ao salvar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MonthPageTemplate(
      month: widget.month,
      year: widget.year,
      title: '',
      pageLabel: 'curiosities.title'.tr(),
      labelColor: const Color(0xFFc79fe2),
      description: _themeDescription.isNotEmpty
          ? _themeDescription
          : 'curiosities.description'.tr(),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),

                  ...List.generate(_questions.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _questions[index],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Color.fromARGB(255, 189, 62, 125),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _controllers[index],
                            minLines: 2,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'curiosities.answer_hint'.tr(),
                              filled: true,
                              fillColor: const Color(0xFFFCEAF4),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE8B3D0),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE25BA6),
                                  width: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveAnswers,
                      icon: const Icon(Icons.favorite, color: Colors.white),
                      label: Text(
                        'curiosities.save'.tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE25BA6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
