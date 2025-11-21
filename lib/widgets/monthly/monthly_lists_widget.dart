import 'package:flutter/material.dart';
import 'package:myyearmystory/services/monthly_lists_service.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:myyearmystory/utils/label_colors.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';

class MonthlyListsWidget extends StatefulWidget {
  final int? month;
  final int? year;

  const MonthlyListsWidget({super.key, this.month, this.year});

  @override
  State<MonthlyListsWidget> createState() => _MonthlyListsWidgetState();
}

class _MonthlyListsWidgetState extends State<MonthlyListsWidget>
    with AutomaticKeepAliveClientMixin {
  final supabase = SupabaseConfig.client;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isPremiumUser = false;
  String? _currentUserId;

  @override
  bool get wantKeepAlive => true;

  final Map<String, List<TextEditingController>> _controllers = {
    'pra_ler': [],
    'pra_anotar': [],
    'pra_comprar': [],
    'pra_ouvir': [],
    'pra_guardar': [],
  };

  // 🌸 Stickers minimalistas
  final Map<String, Map<String, dynamic>> _stickers = {
    'pra_ler': {
      'label': 'Leitura do mês'.tr(),
      'icon': Icons.menu_book_rounded,
    },
    'pra_anotar': {
      'label': 'Pensamentos soltos'.tr(),
      'icon': Icons.edit_rounded,
    },
    'pra_comprar': {
      'label': 'Coisinhas que quero'.tr(),
      'icon': Icons.shopping_bag_rounded,
    },
    'pra_ouvir': {
      'label': 'Músicas que amei'.tr(),
      'icon': Icons.music_note_rounded,
    },
    'pra_guardar': {
      'label': 'Essas eu guardo'.tr(),
      'icon': Icons.push_pin_rounded,
    },
  };

  // Cores e ícones das categorias
  final Map<String, Map<String, dynamic>> _listData = {
    'pra_ler': {
      'title': 'lists.read',
      'color': const Color(0xffe569bf),
    },
    'pra_anotar': {
      'title': 'lists.write',
      'color': const Color(0xFFdbaf35),
    },
    'pra_comprar': {
      'title': 'lists.buy',
      'color': const Color(0xFF679bd3),
    },
    'pra_ouvir': {
      'title': 'lists.listen',
      'color': const Color(0xFFfcdde8),
    },
    'pra_guardar': {
      'title': 'lists.keep',
      'color': const Color(0xFFbeb6f2),
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    _currentUserId = supabase.auth.currentUser?.id;

    if (_currentUserId != null) {
      await _checkPremiumStatus();
      await _loadSavedData();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _checkPremiumStatus() async {
    final response = await supabase
        .from('profiles')
        .select('is_premium')
        .eq('id', _currentUserId!)
        .maybeSingle();

    _isPremiumUser = response?['is_premium'] == true;
  }

  void _initializeControllers() {
    for (String key in _controllers.keys) {
      _controllers[key] = List.generate(5, (_) => TextEditingController());
    }
  }

  Future<void> _loadSavedData() async {
    setState(() => _isLoading = true);

    final lists = await MonthlyListsService.getMonthlyLists(
      widget.month ?? DateTime.now().month,
      widget.year ?? DateTime.now().year,
      _currentUserId!,
    );

    for (String key in _controllers.keys) {
      final savedList = lists[key] ?? <String>[];
      _controllers[key] = List.generate(
        savedList.length > 5 ? savedList.length : 5,
        (i) => TextEditingController(
            text: i < savedList.length ? savedList[i] : ''),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveSingleList(String listKey) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      AccessControl.showLoginPopup(context);
      return;
    }

    if (!_isPremiumUser) {
      showPremiumPopup(context);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final listsToSave = <String, List<String>>{};
      for (String key in _controllers.keys) {
        listsToSave[key] = _controllers[key]!
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .toList();
      }

      await MonthlyListsService.saveMonthlyLists(
        listsToSave,
        widget.month ?? DateTime.now().month,
        widget.year ?? DateTime.now().year,
        user.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('lists.saved'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addNewField(String listKey) {
    if (!_isPremiumUser) {
      showPremiumPopup(context);
      return;
    }

    setState(() {
      _controllers[listKey]!.add(TextEditingController());
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
      pageLabel: 'Minhas Listas',
      labelColor: const Color.fromARGB(255, 78, 83, 150),
      description:
          'Um espaço para anotar o que marcou seu mês — livros, músicas, ideias, compras e lembranças especiais. 💖',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          children: [
            ..._listData.entries.map((entry) => _buildList(entry.key)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(String key) {
    final info = _listData[key]!;
    final bgColor = info['color'] as Color;

    final sticker = _stickers[key]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🌸 Sticker minimalista acima do título
          Row(
            children: [
              Icon(
                sticker['icon'],
                size: 16,
                color: Colors.black.withOpacity(0.5),
              ),
              const SizedBox(width: 4),
              Text(
                sticker['label'],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withOpacity(0.55),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 🔹 Título da categoria
          Text(
            info['title'].toString().tr(),
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black38,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 🔹 Campos de texto com animação
          ..._controllers[key]!.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 1, end: controller.text.isEmpty ? 1 : 1.02),
              duration: const Duration(milliseconds: 150),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: '${"lists.item".tr()} ${index + 1}',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          BorderSide(color: bgColor.withOpacity(0.18)),
                    ),
                  ),
                ),
              ),
            );
          }),

          // ➕ Adicionar mais
          Center(
            child: TextButton.icon(
              onPressed: () => _addNewField(key),
              icon:
                  const Icon(Icons.add_circle_outline, color: Colors.white),
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

          // 💾 Botão salvar estilizado
          Center(
            child: ElevatedButton(
              onPressed: _isSaving ? null : () => _saveSingleList(key),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: bgColor,
                side: BorderSide(color: bgColor),
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'lists.save'.tr(),
                style: const TextStyle(
                  fontSize: 16,
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
