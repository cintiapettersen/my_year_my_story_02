import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:myyearmystory/models/diary_entry.dart';
import 'package:myyearmystory/services/diary_service.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/widgets/shared/show_login_prompt.dart';
import 'package:myyearmystory/widgets/shared/main_scaffold.dart';
import 'package:myyearmystory/utils/access_control.dart';


class DiaryScreen extends StatefulWidget {
  final DateTime date;

  const DiaryScreen({super.key, required this.date});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final TextEditingController _entryController = TextEditingController();

  List<DiaryEntryModel> _entries = [];
 

 bool _isLoading = false;
 bool _isPremiumUser = false;
DiaryEntryModel? _editingEntry;

   


  late DateTime _selectedDate;
  String _selectedMoodIcon = "😊";

  final int _maxFreeEntriesPerMonth = 3;

  final List<String> moodIcons = ["😊", "😢", "🍀", "😐", "🤯"];

  final List<Color> diaryUserThemes = const [
    Color(0xFFE04CB7),
    Color(0xFFA1A8F0),
    Color(0xFFDBAF35),
    Color(0xFF7654A3),
    Color(0xFFC79FE2),
  ];

  Color _userThemeColor = const Color(0xFFE04CB7);

  @override
void initState() {
  super.initState();
  _selectedDate = widget.date;
  _checkPremiumStatus();
  _loadEntries();
}


  Future<void> _checkPremiumStatus() async {
    final premium = await AccessControl.isPremium();
    if (mounted) setState(() => _isPremiumUser = premium);
  }

  // ===============================
  // LOAD
  // ===============================

  Future<void> _loadEntries() async {
  try {
    setState(() => _isLoading = true);

    final entries = await DiaryService.getEntries();

    if (!mounted) return;
    setState(() {
      _entries = entries;
    });
  } catch (e) {
    debugPrint('Erro ao carregar diário: $e');

   

  } finally {
    if (!mounted) return;
    setState(() => _isLoading = false);
  }
}



  // ===============================
  // LIMIT
  // ===============================

  int _entriesThisMonth() {
    final now = DateTime.now();
    return _entries.where((e) =>
        e.entryDate.year == now.year &&
        e.entryDate.month == now.month).length;
  }

  bool _canSaveEntry() {
    if (_isPremiumUser) return true;
    return _entriesThisMonth() < _maxFreeEntriesPerMonth;
  }

  // ===============================
  // ADD ENTRY
  // ===============================

  Future<void> _handleNewEntry() async {
    final user = SupabaseConfig.client.auth.currentUser;

    if (user == null) {
      await _showGuestInfoDialog();
      return;
    }

    if (!_canSaveEntry()) {
      showPremiumPopup(context);
      return;
    }

    _openEntryModal();
  }

  

  // ===============================
  // UI
  // ===============================

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 2,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
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
              backgroundColor: _userThemeColor,
              onPressed: _handleNewEntry,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
          decoration: const BoxDecoration(
            color: Color(0xFFEFE7F5),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text(
                'diary.title'.tr().toUpperCase(),
                style: GoogleFonts.robotoMono(
                  fontSize: 20,
                  color: const Color.fromARGB(221, 143, 50, 98),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'diary.subtitle'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: diaryUserThemes.map((color) {
                  final isSelected = color == _userThemeColor;
                  return GestureDetector(
                    onTap: () => setState(() => _userThemeColor = color),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: isSelected ? 3 : 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: _userThemeColor,
              child: const Icon(Icons.favorite, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEntriesList() {
    return RefreshIndicator(
      onRefresh: _loadEntries,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _entries.length,
        itemBuilder: (_, i) => _buildEntryCard(_entries[i]),
      ),
    );
  }

  Widget _buildEntryCard(DiaryEntryModel entry) {
  return GestureDetector(
    onTap: () => _editEntry(entry), // 👈 AQUI está o segredo
    child: Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(entry.moodIcon ?? "😊", style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(entry.entryDate),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _userThemeColor,
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') _deleteEntry(entry);
                    if (value == 'edit') _editEntry(entry);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('diary.edit'.tr()),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'diary.delete'.tr(),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
  entry.content,
  maxLines: entry.content.length > 80 ? 3 : null,
  overflow: TextOverflow.ellipsis,
  style: const TextStyle(height: 1.5),
),

            const SizedBox(height: 12),
            Text(
              _formatTime(entry.entryDate),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildEntryDialog() {
    return StatefulBuilder(
      builder: (context, modalSetState) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              children: [
                Text(
                  'diary.new_entry'.tr(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: moodIcons.map((icon) {
                    final selected = icon == _selectedMoodIcon;
                    return GestureDetector(
                      onTap: () {
                        modalSetState(() {
                          _selectedMoodIcon = icon;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: selected
                              ? _userThemeColor.withOpacity(0.25)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? _userThemeColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          icon,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: TextField(
                      controller: _entryController,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'diary.hint_text'.tr(),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),

                
                const SizedBox(height: 20),


if (SupabaseConfig.client.auth.currentUser == null)
  Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEEF4),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFF2C6D6)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline,
          color: Color(0xFFB03062),
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'diary.guest_save_warning'.tr(),
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: Color(0xFF6D2C4A),
            ),
          ),
        ),
      ],
    ),
  ),




                ElevatedButton(
  onPressed: () async {
    final user = SupabaseConfig.client.auth.currentUser;

    if (user == null) {
      // não fecha o modal
      return;
    }

    await _saveEntry();
    if (!mounted) return;
    Navigator.of(context).pop();
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: _userThemeColor,
    foregroundColor: Colors.white,
  ),
  child: Text('diary.save'.tr()),
),

                 
              
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveEntry() async {
  if (_entryController.text.trim().isEmpty) return;

  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) {
    showLoginPrompt(context);
    return;
  }

  try {
    if (_editingEntry != null) {
      await DiaryService.updateEntry(
     _editingEntry!.id,
     _entryController.text.trim(),
     _selectedDate, // 👈 ESTE era o argumento faltando
  moodIcon: _selectedMoodIcon,
);


    } else {
      await DiaryService.createEntry(
        _entryController.text.trim(),
        _selectedDate,
        moodIcon: _selectedMoodIcon,
      );
    }

    _editingEntry = null;
    await _loadEntries();
  } catch (e) {
    debugPrint('Erro ao salvar diário: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color.fromARGB(255, 142, 136, 232),
        content: Text('offline.save_warning'.tr()),
      ),
    );
  }
}


// ===============================
// EDIT ENTRY
// ===============================
void _editEntry(DiaryEntryModel entry) {
  setState(() {
    _editingEntry = entry;
    _entryController.text = entry.content;
    _selectedMoodIcon = entry.moodIcon ?? "😊";
  });

  _openEntryModal(isEditing: true);
}

// ===============================
// OPEN ENTRY MODAL
// ===============================
void _openEntryModal({bool isEditing = false}) {
  if (!isEditing) {
    _entryController.clear();
    _selectedMoodIcon = "😊";
    _editingEntry = null;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _buildEntryDialog(),
  );
}

// ===============================
// DELETE ENTRY
// ===============================
void _deleteEntry(DiaryEntryModel entry) async {
  try {
    await DiaryService.deleteEntry(entry.id);
    await _loadEntries();
  } catch (e) {
    debugPrint('Erro ao deletar diário: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color.fromARGB(255, 130, 121, 182),
        content: Text('offline.delete_warning'.tr()),
      ),
    );
  }
}

// ===============================
// FORMATTERS
// ===============================
String _formatDate(DateTime date) =>
    '${date.day}/${date.month}/${date.year}';

String _formatTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

// ===============================
// EMPTY STATE
// ===============================
Widget _buildEmptyState() {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        'diary.no_entries_day'.tr(),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

  Future<void> _showGuestInfoDialog() async {
  if (!context.mounted) return;

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Center(
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                contentPadding:
                    const EdgeInsets.fromLTRB(24, 32, 24, 20),
                backgroundColor: const Color(0xFFFFF1F6),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.edit_note,
                      size: 42,
                      color: Color(0xFFB03062),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'diary.guest_info_title'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB03062),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'diary.guest_info_message'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 26),

                    /// BOTÃO PRINCIPAL — LOGIN
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          showLoginPrompt(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCD4B78),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'diary.guest_login'.tr(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    /// AÇÃO SECUNDÁRIA — CONTINUAR
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _openEntryModal();
                      },
                      child: Text(
                        'diary.guest_continue'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB03062),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// BOTÃO FECHAR
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ],
        ),
      );
    },
  );
}

}
