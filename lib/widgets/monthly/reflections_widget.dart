import 'package:flutter/material.dart';
import 'package:myyearmystory/services/reflections_service.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:myyearmystory/screens/popups/popup_login.dart';


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
  bool _isPremiumUser = false;

  /// Free users podem salvar APENAS 1 reflexão
  int _freeSaveCount = 0;

  @override
  bool get wantKeepAlive => true;

  bool get isGuest {
  return _supabase.auth.currentUser == null;
}

  /// Lista de prompts traduzidos
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

    _isPremiumUser = await AccessControl.isPremium();
    await _loadReflections();
  }

  Future<void> _loadReflections() async {
    if (_currentUserId == null) return;

    setState(() => _isLoading = true);

    try {
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveReflections() async {
  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) {
    showLoginPrompt(context);
    return;
  }

  if (!_isPremiumUser && _freeSaveCount >= 1) {
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

    if (!mounted) return;

    if (success) {
      if (!_isPremiumUser) _freeSaveCount++;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color.fromARGB(255, 215, 126, 194),
          content: Text('reflection.saved'.tr()),
        ),
      );
    } else {
      // 👇 AQUI é o offline
      ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
  behavior: SnackBarBehavior.floating,
  backgroundColor: const Color.fromARGB(255, 215, 126, 194),
  content: Text('offline.save_warning'.tr()),
),

      );
    }
  } catch (e) {
    if (!mounted) return;

    // erro inesperado (não conexão)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('reflection.save_error'.tr()),
      ),
    );
  } finally {
    if (mounted) setState(() => _isSaving = false);
  }
}


// BUILD
  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final month = widget.month ?? DateTime.now().month;
    final year = widget.year ?? DateTime.now().year;

    return MonthPageTemplate(
      month: month,
      year: year,
      pageLabel: 'reflection.page_label'.tr(),
      labelColor: const Color.fromARGB(255, 180, 107, 214),
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
                border: Border.all(color: const Color(0xFFF2D7E0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(31, 199, 84, 163),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
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
                    readOnly: !_isPremiumUser && _freeSaveCount >= 1,
                    onTap: () {
                      if (!_isPremiumUser && _freeSaveCount >= 1) {
                        showPremiumPopup(context);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'reflection.hint'.tr(),
                      filled: true,
                      fillColor: const Color(0xFFFFF7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 20),

          /// BOTÃO SALVAR
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      if (!_isPremiumUser && _freeSaveCount >= 1) {
                        showPremiumPopup(context);
                        return;
                      }
                      _saveReflections();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 183, 103, 199),
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

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
