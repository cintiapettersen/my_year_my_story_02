import 'package:flutter/material.dart';
import 'package:myyearmystory/models/diary_entry.dart';
import 'package:myyearmystory/services/diary_service.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/widgets/shared/show_login_prompt.dart';
import 'package:myyearmystory/widgets/shared/main_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';




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

    // 🔒 Convidado → mostrar popup de login
    if (user == null) {
      showLoginPrompt(context);
      return;
    }

    // 💎 Usuário free → limitar 3 entradas
    if (!_isPremiumUser && _entries.length >= _maxFreeEntries) {
      showPremiumPopup(context);
      return;
    }

    _showNewEntryDialog();
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 3, // índice do menu inferior (ajuste se for outro)
      body: Stack(
        children: [
          Container(color: const Color(0xFFFAE5ED),),

          Column(
            children: [
              // 🌸 Cabeçalho no estilo mensal
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.08),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.01),
                      offset: const Offset(0, 2),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/imagens/logo_512px.png',
                      height: 56,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                     Text(
                      'Diário Pessoal',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD1186C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Seu espaço livre para reflexões e pensamentos ✨',
                      style: TextStyle(
                        fontSize: 15,
                        color: const Color(0xFF1B1F25),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_entries.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${_entries.length} ${_entries.length == 1 ? 'entrada' : 'entradas'} registradas',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),


              // 🌿 Conteúdo principal
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _entries.isEmpty
                    ? _buildEmptyState()
                    : _buildEntriesList(),
              ),
            ],
          ),

          // 🪄 Botão flutuante
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _handleNewEntry,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add_rounded, color: const Color(
                  0xFFEFE2E8), size: 28),
            ),
          ),
        ],
      ),
    );
  }

  // 🌀 Estado de carregamento
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  // 📖 Estado vazio
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const SizedBox(height: 20),
            const Text(
              'Seu diário está vazio',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1C6097),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Comece escrevendo sobre seu dia, seus sentimentos ou algo que queira guardar na memória.',
              style: TextStyle(
                fontSize: 15,
                color: const Color(0xFF1C1719),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _handleNewEntry,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Escrever Primeira Entrada'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📜 Lista de entradas
  Widget _buildEntriesList() {
    return RefreshIndicator(
      onRefresh: _loadEntries,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          return _buildEntryCard(_entries[index]);
        },
      ),
    );
  }

  Widget _buildEntryCard(DiaryEntryModel entry) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(entry.entryDate),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') _editEntry(entry);
                    if (value == 'delete') _deleteEntry(entry);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Text('Excluir',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              entry.content,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 14, color: Colors.grey[500]),
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

  // ✏️ Novo registro
  void _showNewEntryDialog() {
    _entryController.clear();
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
          Icon(Icons.auto_stories_rounded,
              color: Theme.of(context).primaryColor, size: 36),
          const SizedBox(height: 12),
          const Text(
            'Nova Entrada',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F6F3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(_selectedDate),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
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
              hintText: 'Como foi seu dia?',
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
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
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Salvar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _saveEntry() async {
    final content = _entryController.text.trim();
    if (content.isEmpty) return;

    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) {
      showLoginPrompt(context);
      return;
    }

    try {
      await DiaryService.createEntry(userId, content, _selectedDate);
      await _loadEntries();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Entrada salva com sucesso! ✨'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Erro ao salvar entrada: $e');
    }
  }

  void _editEntry(DiaryEntryModel entry) {
    _entryController.text = entry.content;
    _selectedDate = entry.entryDate;

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
        title: const Text('Excluir Entrada'),
        content: const Text('Tem certeza que deseja excluir esta entrada?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await DiaryService.deleteEntry(entry.id);
              await _loadEntries();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Entrada excluída com sucesso 🗑️'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child:
            const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

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
