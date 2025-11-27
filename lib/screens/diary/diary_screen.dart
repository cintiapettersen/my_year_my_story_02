import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:myyearmystory/models/diary_entry.dart';
import 'package:myyearmystory/services/diary_service.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/widgets/shared/show_login_prompt.dart';
import 'package:myyearmystory/widgets/shared/main_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final TextEditingController _entryController = TextEditingController();
  List<DiaryEntryModel> _entries = [];
  bool _isLoading = false;
  bool _isPremiumUser = false;
  DateTime _selectedDate = DateTime.now();

  final int _maxFreeEntries = 3;

  // NOVO: ícone selecionado para cada entrada
  final List<String> moodIcons = ["😊", "😢", "🍀", "😐", "🤯"];
  String _selectedIcon = "😊";

  // 5 temas da paleta
  final List<Color> diaryUserThemes = [
    const Color(0xFFE04CB7),
    const Color(0xFFA1A8F0),
    const Color(0xFFDBAF35),
    const Color(0xFF7654A3),
    const Color(0xFFC79FE2),
  ];

  Color _userThemeColor = const Color(0xFFE04CB7);

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
    _loadEntries();
  }

  Future<void> _checkPremiumStatus() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      setState(() => _isPremiumUser = false);
      return;
    }

    final response = await SupabaseConfig.client
        .from('users')
        .select('is_premium')
        .eq('id', user.id)
        .maybeSingle();

    setState(() {
      _isPremiumUser = response != null && response['is_premium'] == true;
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);

    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId != null) {
        final entries = await DiaryService.getEntries(userId);
        setState(() {
          _entries = entries;
          _isLoading = false;
        });
      } else {
        setState(() {
          _entries = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar entradas: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleNewEntry() async {
    final user = SupabaseConfig.client.auth.currentUser;

    if (user == null) {
      showLoginPrompt(context);
      return;
    }

    if (!_isPremiumUser && _entries.length >= _maxFreeEntries) {
      showPremiumPopup(context);
      return;
    }

    _showNewEntryDialog();
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 3,
      body: Stack(
        children: [
          // 🌈 FUNDO — apenas a cor base
          Container(color: _userThemeColor.withOpacity(0.10)),

          Column(
            children: [
              // 🌸 Banner com efeito vidro
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.35),
                          Colors.white.withOpacity(0.10),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.2,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/imagens/logo_512px.png',
                          height: 56,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Diário Pessoal'.tr(),
                          style: GoogleFonts.courierPrime(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Seu espaço livre para reflexões e pensamentos ✨'.tr(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 16),

                        // 🎨 Seletor de cores
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: diaryUserThemes.map((color) {
                            return GestureDetector(
                              onTap: () {
                                setState(() => _userThemeColor = color);
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.8),
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _entries.isEmpty
                        ? _buildEmptyState()
                        : _buildEntriesList(),
              ),
            ],
          ),

          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _handleNewEntry,
              backgroundColor: _userThemeColor,
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
  // -----------------------------
  //      ESTADOS DA TELA
  // -----------------------------

  Widget _buildLoadingState() => const Center(child: CircularProgressIndicator());

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              'Seu diário está vazio'.tr(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _userThemeColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Comece escrevendo sobre seu dia, seus sentimentos ou algo que queira guardar na memória.'
                  .tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _handleNewEntry,
              icon: const Icon(Icons.edit_rounded),
              label: Text('Escrever Primeira Entrada'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _userThemeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesList() {
    return RefreshIndicator(
      onRefresh: _loadEntries,
      color: _userThemeColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          return _buildEntryCard(_entries[index]);
        },
      ),
    );
  }

  // -----------------------------
  //      CARD DE ENTRADA
  // -----------------------------

  Widget _buildEntryCard(DiaryEntryModel entry) {
    return Card(
      color: Colors.white, // ❗ cartões sempre brancos
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // TAG DE DATA com paleta fixa
                _buildDateTag(entry),

                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') _editEntry(entry);
                    if (value == 'delete') _deleteEntry(entry);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 16),
                          const SizedBox(width: 8),
                          Text('Editar'.tr()),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Text('Excluir'.tr(),
                              style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // CONTEÚDO
            Text(
              entry.content,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  _formatTime(entry.entryDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // TAG COLORIDA DE DATA COM ÍCONE
  Widget _buildDateTag(DiaryEntryModel entry) {
    // 10 cores fixas para data
    final List<Color> palette = [
      const Color(0xFFE04CB7),
      const Color(0xFFA1A8F0),
      const Color(0xFFDBAF35),
      const Color(0xFF7654A3),
      const Color(0xFFC79FE2),
      const Color(0xFF6DD3CE),
      const Color(0xFFFAA275),
      const Color(0xFF9DB4C0),
      const Color(0xFFFFC9DE),
      const Color(0xFF88A0E5),
    ];

    final index = entry.id.hashCode.abs() % palette.length;
    final color = palette[index];
    final icon = entry.moodIcon ?? "😊";


    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.6), width: 1),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            _formatDate(entry.entryDate),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------
  //   MODAL: NOVA ENTRADA
  // -----------------------------

  void _showNewEntryDialog() {
    _entryController.clear();
    _selectedIcon = "😊";
    _selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _buildEntryDialog(),
    );
  }

  Widget _buildEntryDialog() {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_stories_rounded, color: _userThemeColor, size: 36),
          const SizedBox(height: 12),
          Text('Nova Entrada'.tr(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 22),

          // ÍCONES SELECIONÁVEIS 🌟
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: moodIcons.map((icon) {
              final isSelected = icon == _selectedIcon;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedIcon = icon);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _userThemeColor.withOpacity(0.25)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? _userThemeColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(icon, style: const TextStyle(fontSize: 26)),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          GestureDetector(
            onTap: _selectDateFromEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F6F3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, size: 16, color: _userThemeColor),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(_selectedDate),
                    style: TextStyle(
                      color: _userThemeColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: _entryController,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: 'Como foi seu dia?'.tr(),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar'.tr()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await _saveEntry();
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _userThemeColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Salvar'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  
// -----------------------------
//   SELETOR DE DATA (NOVO)
// -----------------------------
void _selectDateFromEdit() async {
  final date = await showDatePicker(
    context: context,
    initialDate: _selectedDate,
    firstDate: DateTime(2020),
    lastDate: DateTime.now(),
  );

  if (date != null) {
    setState(() => _selectedDate = date);
  }
}

  // -----------------------------
  //      SALVAR ENTRADA
  // -----------------------------

  Future<void> _saveEntry() async {
    final content = _entryController.text.trim();
    if (content.isEmpty) return;

    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) {
      showLoginPrompt(context);
      return;
    }

    try {
      await DiaryService.createEntry(
        userId,
        content,
        _selectedDate,
        moodIcon: _selectedIcon, // SALVA O ÍCONE!
      );

      await _loadEntries();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Entrada salva com sucesso! ✨'.tr()),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Erro ao salvar entrada: $e');
    }
  }

  // -----------------------------
  //   EDIÇÃO E EXCLUSÃO
  // -----------------------------

  void _editEntry(DiaryEntryModel entry) {
    _entryController.text = entry.content;
    _selectedDate = entry.entryDate;
    _selectedIcon = entry.moodIcon ?? "😊";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _buildEntryDialog(),
    );
  }

  void _deleteEntry(DiaryEntryModel entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir Entrada'.tr()),
        content: Text('Tem certeza que deseja excluir esta entrada?'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await DiaryService.deleteEntry(entry.id);
              await _loadEntries();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Entrada excluída com sucesso 🗑️'.tr()),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: Text('Excluir'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // -----------------------------
  //   FORMATADORES
  // -----------------------------

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
