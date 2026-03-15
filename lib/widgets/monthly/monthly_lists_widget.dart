import 'package:flutter/material.dart';
import 'package:myyearmystory/services/monthly_lists_service.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/screens/popups/popup_login.dart';
import 'package:myyearmystory/widgets/shared/app_pill_button.dart';

/// Config DEV/Admin igual à InterviewScreen
class AppConfig {
  static bool isDev = true; // Altere para false na versão final
  static bool isAdmin(String? email) =>
      email != null && email.endsWith("@sonhodepapel.com");
}

class MonthlyListsWidget extends StatefulWidget {
  final int? month;
  final int? year;

  const MonthlyListsWidget({super.key, this.month, this.year});

  @override
  State<MonthlyListsWidget> createState() => _MonthlyListsWidgetState();
}

class _MonthlyListsWidgetState extends State<MonthlyListsWidget>
    with AutomaticKeepAliveClientMixin {
  final _supabase = SupabaseConfig.client;

  bool _isLoading = false;
  bool _isSaving = false;

  bool _isPremiumUser = false;
  String? _currentUserId;

  @override
  bool get wantKeepAlive => true;

  bool get isGuest {
  return _supabase.auth.currentUser == null;
}

  /// Controllers por categoria
  final Map<String, List<TextEditingController>> _controllers = {
    'pra_ler': [],
    'pra_anotar': [],
    'pra_comprar': [],
    'pra_ouvir': [],
    'pra_guardar': [],
  };

  /// Stickers traduzidos
  final Map<String, Map<String, dynamic>> _stickers = {
    'pra_ler': {'label': 'lists.sticker_read'.tr()},
    'pra_anotar': {'label': 'lists.sticker_write'.tr()},
    'pra_comprar': {'label': 'lists.sticker_buy'.tr()},
    'pra_ouvir': {'label': 'lists.sticker_listen'.tr()},
    'pra_guardar': {'label': 'lists.sticker_keep'.tr()},
  };

  /// Informações das listas
  final Map<String, Map<String, dynamic>> _listData = {
    'pra_ler': {'title': 'lists.read', 'color': Color(0xffe569bf)},
    'pra_anotar': {'title': 'lists.write', 'color': Color(0xFFdbaf35)},
    'pra_comprar': {'title': 'lists.buy', 'color': Color(0xFF679bd3)},
    'pra_ouvir': {'title': 'lists.listen', 'color': Color(0xFFF3CDDB)},
    'pra_guardar': {'title': 'lists.keep', 'color': Color(0xFFbeb6f2)},
  };

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAndLoad();
  }

  void _initializeControllers() {
    for (String key in _controllers.keys) {
      _controllers[key] = List.generate(5, (_) => TextEditingController());
    }
  }

  Future<void> _initializeAndLoad() async {
    setState(() => _isLoading = true);

    await _checkPremiumStatus();

    _currentUserId = _supabase.auth.currentUser?.id;

    if (_currentUserId != null) {
      await _loadSavedData();
    }

    setState(() => _isLoading = false);
  }

  /// Premium + Dev + Admin
  Future<void> _checkPremiumStatus() async {
    final user = _supabase.auth.currentUser;
    final email = user?.email;

    final isPremium = await AccessControl.isPremium();

    setState(() {
      _isPremiumUser =
          isPremium || AppConfig.isAdmin(email) || AppConfig.isDev;
    });
  }

  /// Carrega listas salvas
  Future<void> _loadSavedData() async {
    setState(() => _isLoading = true);

    final lists = await MonthlyListsService.getMonthlyLists(
      widget.month ?? DateTime.now().month,
      widget.year ?? DateTime.now().year,
      _currentUserId!,
    );

    for (String key in _controllers.keys) {
      final saved = lists[key] ?? <String>[];
      _controllers[key] = List.generate(
        saved.length > 5 ? saved.length : 5,
        (i) => TextEditingController(text: i < saved.length ? saved[i] : ''),
      );
    }

    setState(() => _isLoading = false);
  }

  /// Salvar listas
  Future<void> _saveList(String listKey) async {
  final user = _supabase.auth.currentUser;

  if (isGuest) {
  showLoginPrompt(context);
  return;
}

if (!_isPremiumUser) {
  showPremiumPopup(context);
  return;
}


  // 🔍 Checa se TODAS as listas estão vazias
 // 1️⃣ validação antes de tudo
final hasAtLeastOneFilled = _controllers.values.any(
  (listControllers) =>
      listControllers.any((c) => c.text.trim().isNotEmpty),
);

if (!hasAtLeastOneFilled) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: const Color(0xFFa652b6),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      content: Text(
        'lists.empty_warning'.tr(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
  return;
}

// 2️⃣ começa o save real
setState(() => _isSaving = true);

final Map<String, List<String>> listsToSave = {};

for (final key in _controllers.keys) {
  listsToSave[key] = _controllers[key]!
      .map((c) => c.text.trim())
      .where((t) => t.isNotEmpty)
      .toList();
}


try {
  await MonthlyListsService.saveMonthlyLists(
    listsToSave,
    widget.month ?? DateTime.now().month,
    widget.year ?? DateTime.now().year,
    user!.id,
  );

  if (!mounted) return;

  // ✅ sucesso SÓ aqui
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: const Color(0xFFa652b6),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      content: Text(
        'lists.saved'.tr(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
} catch (e) {
  if (!mounted) return;

  // ❌ erro offline
  showOfflineSaveWarning(context);
} finally {
  if (mounted) {
    setState(() => _isSaving = false);
  }
}
}


void showOfflineSaveWarning(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: const Color(0xFFa652b6),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      content: Text(
        'offline.save_warning'.tr(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}


  /// Adicionar novo campo com animação cute ✨
  void _addField(String listKey) {
  if (isGuest) {
    showLoginPrompt(context);
    return;
  }

  if (!_isPremiumUser) {
    showPremiumPopup(context);
    return;
  }

    setState(() {
      final newController = TextEditingController();
      _controllers[listKey]!.add(newController);
    });

    // animação para suavizar
    Future.delayed(const Duration(milliseconds: 20), () {
      AnimatedOpacity(
        opacity: 1,
        duration: const Duration(milliseconds: 250),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final month = widget.month ?? DateTime.now().month;
    final year = widget.year ?? DateTime.now().year;

    return MonthPageTemplate(
      month: month,
      year: year,
      title: '',
      pageLabel: 'lists.page_label'.tr(),
      labelColor: const Color.fromARGB(255, 95, 101, 178),
      description: 'lists.description'.tr(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          children: _listData.keys.map((key) => _buildList(key)).toList(),
        ),
      ),
    );
  }

  Widget _buildList(String key) {
    final info = _listData[key]!;
    final bgColor = info['color'] as Color;
    final sticker = _stickers[key]!;

    final isListenBlock = key == 'pra_ouvir';

    final titleColor = isListenBlock
        ? const Color.fromARGB(255, 199, 70, 113)
        : Colors.white.withOpacity(0.92);

    final saveTextColor =
        isListenBlock ? const Color(0xFFE9628F) : bgColor;

    final saveBorderColor =
        isListenBlock ? const Color(0xFFcda5b2) : bgColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Sticker
          Text(
            sticker['label'],
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.white.withOpacity(0.55),
            ),
          ),

          const SizedBox(height: 14),

          /// Título
          Text(
            info['title'].toString().tr(),
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: titleColor,
            ),
          ),

          const SizedBox(height: 16),

          /// Campos
          ..._controllers[key]!.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;

            return AnimatedSlide(
              offset: const Offset(0, 0.08),
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              child: AnimatedOpacity(
                opacity: 1,
                duration: const Duration(milliseconds: 240),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
	                  child: TextField(
	                    controller: controller,
	                    autocorrect: true,
	                    enableSuggestions: true,
	                    smartQuotesType: SmartQuotesType.enabled,
	                    smartDashesType: SmartDashesType.enabled,
	                    decoration: InputDecoration(
	                      filled: true,
	                      fillColor: Colors.white,
	                      hintText: "${"lists.item".tr()} ${index + 1}",
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFF2F0F0),
                          width: 1.3,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xffC03B66),
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),

          /// Botão "Add More"
          Center(
            child: TextButton.icon(
              onPressed: () => _addField(key),
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: Text(
                'lists.add_more'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// Save
          Center(
            child: AppPillButton(
              text: 'lists.save'.tr(),
              onPressed: _isSaving ? null : () => _saveList(key),
              backgroundColor: saveBorderColor,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
