import 'package:flutter/material.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';

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
  int? _entryId;

  String _themeTitle = '';
  String _themeDescription = '';
  List<String> _questions = [];
  List<TextEditingController> _controllers = [];

  int _insertionCount = 0; // controla quantas respostas o usuário não premium inseriu

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
      final response = await SupabaseConfig.client
          .from('curiosities_entries')
          .select('id, theme_title, theme_description, questions, answers')
          .eq('month', widget.month)
          .eq('year', widget.year)
          .maybeSingle();

      if (response != null) {
        _entryId = response['id'];
        _themeTitle = response['theme_title'] ?? '';
        _themeDescription = response['theme_description'] ?? '';
        _questions = List<String>.from(response['questions'] ?? []);
        _controllers = List.generate(_questions.length, (_) => TextEditingController());
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar perguntas: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSavedAnswers() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null || _entryId == null) return; // ✅ evita null

    try {
      final response = await SupabaseConfig.client
          .from('curiosities_entries')
          .select('answers')
          .eq('id', _entryId!) // ✅ forçando o tipo int não nulo
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null && response['answers'] != null) {
        final savedAnswers = List<String>.from(response['answers']);
        for (int i = 0; i < _controllers.length; i++) {
          if (i < savedAnswers.length) {
            _controllers[i].text = savedAnswers[i];
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar respostas: $e');
    }
  }

  Future<void> _saveAnswers() async {
    final user = SupabaseConfig.client.auth.currentUser;

    // 🩶 Convidado → mostra popup e bloqueia
    if (_isGuest) {
      showPremiumPrompt(context);
      return;
    }

    // 💕 Logada mas não premium → permite 1 inserção, depois bloqueia
    if (!_isPremiumUser && _insertionCount >= 1) {
      showPremiumPrompt(context);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentAnswers = _controllers.map((c) => c.text.trim()).toList();

      await SupabaseConfig.client.from('curiosities_entries').upsert({
        'id': _entryId,
        'user_id': user!.id,
        'month': widget.month,
        'year': widget.year,
        'answers': currentAnswers,
      }, onConflict: 'id, user_id');

      if (!_isPremiumUser) {
        _insertionCount++;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Respostas salvas com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar respostas: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MonthPageTemplate(
      month: widget.month,
      year: widget.year,
      title: _themeTitle.isNotEmpty ? _themeTitle : 'Curiosidades Aleatórias Sobre Mim',
      description: _themeDescription,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            ...List.generate(_questions.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _questions[index],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controllers[index],
                      decoration: InputDecoration(
                        hintText: 'Sua resposta',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      onChanged: (_) {
                        if (!_isPremiumUser && _insertionCount >= 1) {
                          showPremiumPrompt(context);
                        }
                      },
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
                label: const Text(
                  'Salvar Respostas',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 3,
                  shadowColor: Colors.purple[200],
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
