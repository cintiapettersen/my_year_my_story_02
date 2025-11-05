import 'package:flutter/material.dart';
import 'package:my_year_my_story/services/monthly_lists_service.dart';
import 'package:my_year_my_story/supabase/supabase_config.dart';
import 'package:my_year_my_story/widgets/shared/month_page_template.dart';
import 'package:my_year_my_story/screens/premium/premium_page.dart';

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
  bool _isOfflineMode = false;
  bool _isPremiumUser = false; // ✅ flag premium real
  String? _currentUserId;
  int _saveCount = 0;

  @override
  bool get wantKeepAlive => true;

  final Map<String, List<TextEditingController>> _controllers = {
    'pra_ler': [],
    'pra_anotar': [],
    'pra_comprar': [],
    'pra_ouvir': [],
    'pra_guardar': [],
  };

  final Map<String, Map<String, dynamic>> _listData = {
    'pra_ler': {
      'title': 'Pra Ler',
      'icon': Icons.book_outlined,
      'color': const Color(0xffe569bf),
    },
    'pra_anotar': {
      'title': 'Pra Anotar',
      'icon': Icons.edit_note_outlined,
      'color': const Color(0xFFdbaf35),
    },
    'pra_comprar': {
      'title': 'Pra Comprar',
      'icon': Icons.shopping_bag_outlined,
      'color': const Color(0xFF679bd3),
    },
    'pra_ouvir': {
      'title': 'Pra Ouvir',
      'icon': Icons.music_note_outlined,
      'color': const Color(0xFFfcdde8),
    },
    'pra_guardar': {
      'title': 'Pra Guardar',
      'icon': Icons.favorite_border,
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
    _isOfflineMode = _currentUserId == null;

    if (_currentUserId != null) {
      await _checkPremiumStatus(); // ✅ verifica status premium real
    }

    await _loadSavedData();
  }

  /// 🔎 Checa no Supabase se o usuário é premium
  Future<void> _checkPremiumStatus() async {
    try {
      final response = await supabase
          .from('profiles')
          .select('is_premium')
          .eq('id', _currentUserId!)
          .maybeSingle();

      if (response != null && response['is_premium'] == true) {
        _isPremiumUser = true;
      } else {
        _isPremiumUser = false;
      }
    } catch (e) {
      debugPrint('Erro ao verificar status premium: $e');
      _isPremiumUser = false;
    }
  }

  void _initializeControllers() {
    for (String key in _controllers.keys) {
      _controllers[key] = List.generate(5, (_) => TextEditingController());
    }
  }

  Future<void> _loadSavedData() async {
    setState(() => _isLoading = true);
    try {
      if (_currentUserId != null) {
        final lists = await MonthlyListsService.getMonthlyLists(
          widget.month ?? DateTime.now().month,
          widget.year ?? DateTime.now().year,
          _currentUserId!,
        );
        for (String key in _controllers.keys) {
          final savedList = lists[key] ?? <String>[];
          _controllers[key] = List.generate(
            5,
                (i) => TextEditingController(text: i < savedList.length ? savedList[i] : ''),
          );
        }
      } else {
        _isOfflineMode = true;
      }
    } catch (e) {
      debugPrint('Erro ao carregar listas: $e');
      _isOfflineMode = true;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSingleList(String listKey) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      // 🔒 Se não estiver logado → leva pra PremiumPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PremiumPage(
            month: widget.month ?? DateTime.now().month,
            year: widget.year ?? DateTime.now().year,
          ),
        ),
      );
      return;
    } else if (!_isPremiumUser) {
      _saveCount++;
      if (_saveCount >= 3) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PremiumPage(
              month: widget.month ?? DateTime.now().month,
              year: widget.year ?? DateTime.now().year,
            ),
          ),
        );
        return;
      }
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
          const SnackBar(
            content: Text('💖 Lista salva com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao salvar lista: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao salvar a lista.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addNewField(String listKey) {
    final user = supabase.auth.currentUser;

    if (user == null || !_isPremiumUser) {
      // 🔒 Redireciona pra tela Premium
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PremiumPage(
            month: widget.month ?? DateTime.now().month,
            year: widget.year ?? DateTime.now().year,
          ),
        ),
      );
      return;
    }

    setState(() {
      _controllers[listKey]!.add(TextEditingController());
    });
  }

  @override
  void dispose() {
    for (var controllers in _controllers.values) {
      for (var c in controllers) c.dispose();
    }
    super.dispose();
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
      title: 'Listas do Mês',
      description:
      'Um espaço para anotar o que marcou seu mês — livros, músicas, ideias, compras e lembranças especiais. 💖',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            ..._listData.entries.map((entry) => _buildList(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(String key, Map<String, dynamic>? info) {
    if (info == null) return const SizedBox();

    final Color bgColor = (info['color'] ?? Colors.grey[300]) as Color;
    final IconData icon = (info['icon'] ?? Icons.list_alt) as IconData;
    final String title = info['title'] ?? 'Lista';

    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._controllers[key]!.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Item ${index + 1}',
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: bgColor.withOpacity(0.3)),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          Center(
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : () => _saveSingleList(key),
              icon: const Icon(Icons.favorite_rounded),
              label: const Text('Salvar lista'),
              style: ElevatedButton.styleFrom(
                backgroundColor: bgColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: () => _addNewField(key),
              icon: const Icon(Icons.add_circle_outline, color: Colors.black54),
              label: const Text(
                'Adicionar mais itens',
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
