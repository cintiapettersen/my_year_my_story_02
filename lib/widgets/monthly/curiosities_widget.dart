import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/screens/premium/premium_protected_page.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:myyearmystory/utils/app_config.dart';

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
  bool _loading = true;
  bool _isPremiumUser = false;

  String _themeTitle = '';
  final String _descricaoFixa =
      "Um espaço só seu, para se observar com carinho e descobrir novos pedacinhos de quem você é. "
      "Aqui, você pode refletir, se ouvir e se permitir sentir — sem pressa, sem regras, só você.";

  List<String> _questions = [];
  List<TextEditingController> _controllers = [];

  String? curiosidadeAleatoria;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _checkPremiumStatus();
    await _loadThemeAndQuestions();
    await _loadSavedAnswers();
    await _loadCuriosityOfMonth();

    setState(() {
      _loading = false;
    });
  }

  // ------------------------------------------------------------
  // 🔑 CHECAGEM PREMIUM + ADMIN
  // ------------------------------------------------------------
  Future<void> _checkPremiumStatus() async {
    final user = SupabaseConfig.client.auth.currentUser;
    final email = user?.email;

    final isPremium = await AccessControl.isPremium();

    setState(() {
      _isPremiumUser = isPremium || AppConfig.isAdmin(email);
    });
  }

  // ------------------------------------------------------------
  // 🔄 CARREGA PERGUNTAS DO MÊS
  // ------------------------------------------------------------
  Future<void> _loadThemeAndQuestions() async {
  try {
    final res = await SupabaseConfig.client
        .from('curiosities_entries')
        .select('theme_title, questions, questions_en')
        .eq('month', widget.month)
        .eq('year', widget.year)
        .maybeSingle();

    if (res != null) {
      _themeTitle = res['theme_title'] ?? '';

      final String language = context.locale.languageCode;

      // 🔥 CARREGA A COLUNA CERTA CONFORME O IDIOMA DO APP
      _questions = language == 'en'
          ? List<String>.from(res['questions_en'] ?? [])
          : List<String>.from(res['questions'] ?? []);

      _controllers =
          List.generate(_questions.length, (_) => TextEditingController());
    }
  } catch (e) {
    debugPrint('Erro ao carregar curiosities_entries: $e');
  }
}

  // ------------------------------------------------------------
  // 🔄 CARREGA RESPOSTAS SALVAS
  // ------------------------------------------------------------
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

  // ------------------------------------------------------------
  // ❤️ SALVA RESPOSTAS
  // ------------------------------------------------------------
  Future<void> _saveAnswers() async {
    final user = SupabaseConfig.client.auth.currentUser;

    if (!_isPremiumUser) {
      showPremiumPopup(context);
      return;
    }

    try {
      final answers =
          _controllers.map((c) => c.text.trim()).toList(growable: false);

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
        const SnackBar(content: Text("Respostas salvas com sucesso!")),
      );
    } catch (e) {
      debugPrint('Erro ao salvar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao salvar: $e")),
      );
    }
  }

  // ------------------------------------------------------------
  // 🎁 CURIOSIDADE ALEATÓRIA DE MESES PASSADOS
  // ------------------------------------------------------------
  Future<void> _loadCuriosityOfMonth() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    try {
      final res = await SupabaseConfig.client
          .from('entries')
          .select('curiosities_answers, month, year')
          .eq('user_id', user.id)
          .eq('month', widget.month)
          .eq('year', widget.year)
          .maybeSingle();

      if (res == null) {
        curiosidadeAleatoria = null;
        return;
      }

      final answers = res['curiosities_answers'];

      if (answers != null && answers is List && answers.isNotEmpty) {
        final combined = <Map<String, String>>[];

        for (int i = 0; i < answers.length; i++) {
          combined.add({
            "answer": answers[i],
            "month": res["month"].toString(),
            "year": res["year"].toString(),
          });
        }

        combined.shuffle();
        final selected = combined.first;

        curiosidadeAleatoria =
            "${selected['answer']} (${_formatarMesAno(selected['month']!)} ${selected['year']!})";
      }
    } catch (e) {
      curiosidadeAleatoria = null;
    }
  }

  String _formatarMesAno(String month) {
    const meses = [
      "",
      "jan",
      "fev",
      "mar",
      "abr",
      "mai",
      "jun",
      "jul",
      "ago",
      "set",
      "out",
      "nov",
      "dez"
    ];

    final m = int.tryParse(month) ?? 0;
    if (m < 1 || m > 12) return month;

    return meses[m];
  }

  // ------------------------------------------------------------
  // 🌈 UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isPremiumUser) {
      return PremiumProtectedPage(
        child: const Center(child: Text("Carregando...")),
      );
    }

    return MonthPageTemplate(
      month: widget.month,
      year: widget.year,
      title: '',
      pageLabel: 'curiosities.title'.tr(),
      labelColor: const Color(0xFFc79fe2),
      description: "curiosities.description_fixed".tr(),
      child: SingleChildScrollView(
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
        // ❤️ Coração + Pergunta lado a lado
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite,
              size: 18,
              color: Color(0xFFE25BA6),
            ),
            const SizedBox(width: 8),

            // texto da pergunta traduzida
            Expanded(
              child: Text(
                _questions[index], // ← AGORA TRADUZ!
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color.fromARGB(255, 189, 62, 125),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Campo de resposta
        TextField(
          controller: _controllers[index],
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'curiosities.answer_hint'.tr(), // ← também traduz
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
                onPressed: _loading ? null : _saveAnswers,
                icon: const Icon(Icons.favorite, color: Colors.white),
                label: Text(
                  'curiosities.save'.tr(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE25BA6),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 3,
                ),
              ),
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
    super.dispose();
  }
}
