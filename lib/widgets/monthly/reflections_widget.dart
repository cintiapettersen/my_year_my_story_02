import 'package:flutter/material.dart';
import 'package:myyearmystory/services/reflections_service.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:myyearmystory/utils/label_colors.dart';
import 'package:easy_localization/easy_localization.dart';

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

  String? _currentUserId;
  bool isPremiumUser = false;

  /// Free users: só pode salvar 1 reflexão.
  int _freeSaveCount = 0;

  @override
  bool get wantKeepAlive => true;

  /// 🔸 Lista de prompts traduzíveis
  final List<Map<String, String>> _reflectionPrompts = [
    {
      'key': 'biggest_lesson',
      'title': 'reflection.biggest_lesson_title',
      'prompt': 'reflection.biggest_lesson_prompt',
    },
    {
      'key': 'most_grateful',
      'title': 'reflection.most_grateful_title',
      'prompt': 'reflection.most_grateful_prompt',
    },
    {
      'key': 'proudest_moment',
      'title': 'reflection.proudest_moment_title',
      'prompt': 'reflection.proudest_moment_prompt',
    },
    {
      'key': 'biggest_challenge',
      'title': 'reflection.biggest_challenge_title',
      'prompt': 'reflection.biggest_challenge_prompt',
    },
    {
      'key': 'personal_growth',
      'title': 'reflection.personal_growth_title',
      'prompt': 'reflection.personal_growth_prompt',
    },
    {
      'key': 'unexpected_joy',
      'title': 'reflection.unexpected_joy_title',
      'prompt': 'reflection.unexpected_joy_prompt',
    },
    {
      'key': 'next_month_focus',
      'title': 'reflection.next_month_focus_title',
      'prompt': 'reflection.next_month_focus_prompt',
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

    await _loadPremiumStatus();
    await _loadReflections();
  }

  Future<void> _loadPremiumStatus() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      isPremiumUser = false;
      return;
    }

    final profile = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    isPremiumUser = AccessControl.isPremium(profile);
  }

  Future<void> _loadReflections() async {
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
      }
    } catch (e) {
      debugPrint('Erro ao carregar reflexões: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveReflections() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      showPremiumPopup(context);
      return;
    }

    /// Free user tentando salvar mais de 1 reflexão
    if (!isPremiumUser && _freeSaveCount >= 1) {
      showPremiumPopup(context);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final data = <String, String>{};

      for (var entry in _controllers.entries) {
        if (entry.value.text.trim().isNotEmpty) {
          data[entry.key] = entry.value.text.trim();
        }
      }

      final success = await ReflectionsService.saveReflections(
        data,
        widget.month ?? DateTime.now().month,
        widget.year ?? DateTime.now().year,
        user.id,
      );

      if (!isPremiumUser) _freeSaveCount++;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'reflection.saved'.tr()
              : 'reflection.save_error'.tr()),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('reflection.save_error'.tr())),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return MonthPageTemplate(
      month: widget.month ?? DateTime.now().month,
      year: widget.year ?? DateTime.now().year,

      /// Etiqueta no topo!
      pageLabel: 'reflection.page_label'.tr(),
      labelColor: const Color(0xFFcf78f7),

      /// Título oculto
      title: '',

      description: 'reflection.description'.tr(),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          ..._reflectionPrompts.map((prompt) {
            final controller = _controllers[prompt['key']!]!;

            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
                border: Border.all(color: const Color(0xFFF2D7E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prompt['title']!.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color.fromARGB(255, 192, 59, 161),
                      shadows: [
    Shadow(
      blurRadius: 2,
      offset: Offset(0, 1),
      color: Colors.black12,
    ),
  ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    prompt['prompt']!.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
  controller: controller,
  maxLines: 4,

  readOnly: !isPremiumUser && _freeSaveCount >= 1,

  onTap: () {
    if (!isPremiumUser && _freeSaveCount >= 1) {
      showPremiumPopup(context);
    }
  },

  decoration: InputDecoration(
    hintText: 'reflection.hint'.tr(),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    filled: true,
    fillColor: const Color(0xFFFFF7FA),
  ),
),

                ],
              ),
            );
          }),

          const SizedBox(height: 20),

          
          /// Botão SALVAR — padronizado + checagem premium
SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: _isSaving
        ? null
        : () {
            if (!isPremiumUser && _freeSaveCount >= 1) {
              showPremiumPopup(context);
              return;
            }
            _saveReflections();
          },
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color.fromARGB(255, 183, 54, 159),
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    child: Text(
      'reflection.save_button'.tr(),
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
),

        ],
      ),
    );
  }
}
