import 'package:flutter/material.dart';
import 'package:my_year_my_story/services/monthly_lists_service.dart';
import 'package:my_year_my_story/supabase/supabase_config.dart';
import 'package:my_year_my_story/widgets/monthly/monthly_page_template.dart';

class MonthlyListsWidget extends StatefulWidget {
  final int? month;
  final int? year;

  const MonthlyListsWidget({
    super.key,
    this.month,
    this.year,
  });

  @override
  State<MonthlyListsWidget> createState() => _MonthlyListsWidgetState();
}

class _MonthlyListsWidgetState extends State<MonthlyListsWidget>
    with AutomaticKeepAliveClientMixin {
  final supabase = SupabaseConfig.client;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _savedMessage;
  bool _isOfflineMode = false;
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

  final Map<String, Map<String, dynamic>> _listData = {
    'pra_ler': {'title': '📚 Pra Ler', 'color': Colors.blue},
    'pra_anotar': {'title': '📝 Pra Anotar', 'color': Colors.green},
    'pra_comprar': {'title': '🛍️ Pra Comprar', 'color': Colors.orange},
    'pra_ouvir': {'title': '🎵 Pra Ouvir', 'color': Colors.purple},
    'pra_guardar': {'title': '💎 Pra Guardar', 'color': Colors.cyan},
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

    // Fallback para evitar loading infinito se algo travar
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    });

    await _loadSavedData();
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

          for (var controller in _controllers[key]!) {
            controller.dispose();
          }

          _controllers[key] =
              savedList.map((item) => TextEditingController(text: item)).toList();

          while (_controllers[key]!.length < 5) {
            _controllers[key]!.add(TextEditingController());
          }
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
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa estar logada para salvar.'),
          backgroundColor: Colors.red,
        ),
      );
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

      final success = await MonthlyListsService.saveMonthlyLists(
        listsToSave,
        widget.month ?? DateTime.now().month,
        widget.year ?? DateTime.now().year,
        userId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Lista "$listKey" salva com sucesso!'
                : 'Erro ao salvar a lista "$listKey"'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao salvar lista "$listKey": $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar a lista "$listKey"'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addNewField(String listKey) {
    setState(() {
      _controllers[listKey]!.add(TextEditingController());
    });
  }

  void _removeField(String listKey, int index) {
    if (_controllers[listKey]!.length > 5) {
      setState(() {
        _controllers[listKey]![index].dispose();
        _controllers[listKey]!.removeAt(index);
      });
    }
  }

  @override
  void dispose() {
    for (String key in _controllers.keys) {
      for (var controller in _controllers[key]!) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final month = widget.month ?? DateTime.now().month;
    final year = widget.year ?? DateTime.now().year;

    return MonthlyPageTemplate(
      month: month,
      year: year,
      title: 'Listas do Mês',
      description: 'Organize suas ideias e planos para o mês',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isOfflineMode)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Modo offline: Você pode editar, mas faça login para salvar no Supabase.',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (_savedMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      _savedMessage!,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            ..._listData.entries.map(
                  (entry) => _buildList(entry.key, entry.value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(String listKey, Map<String, dynamic> listInfo) {
    final Color baseColor = listInfo['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: baseColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            listInfo['title'] as String,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: baseColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_controllers[listKey]!.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controllers[listKey]![index],
                      decoration: InputDecoration(
                        hintText: 'Item ${index + 1}...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  if (_controllers[listKey]!.length > 5)
                    IconButton(
                      onPressed: () => _removeField(listKey, index),
                      icon: Icon(Icons.remove_circle, color: Colors.red[400]),
                      tooltip: 'Remover item',
                    ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: () => _addNewField(listKey),
            icon: Icon(Icons.add, color: baseColor),
            label: Text(
              'Adicionar mais itens',
              style: TextStyle(color: baseColor),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : () => _saveSingleList(listKey),
              style: ElevatedButton.styleFrom(
                backgroundColor: baseColor,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.save),
              label: const Text('Salvar esta lista'),
            ),
          ),
        ],
      ),
    );
  }
}
