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
    setState(() => _isLoading = true);

    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _entries = [];
        _isLoading = false;
      });
      return;
    }

    final entries = await DiaryService.getEntries();
    setState(() {
      _entries = entries;
      _isLoading = false;
    });
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                ElevatedButton(
                  onPressed: () async {
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

  if (_editingEntry != null) {
  await DiaryService.updateEntry(
  _editingEntry!.id,
  _entryController.text.trim(),
  _editingEntry!.entryDate,
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
  await DiaryService.deleteEntry(entry.id);
  _loadEntries();
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
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (modalContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFCE9EF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'diary.guest_info_title'.tr(),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'diary.guest_info_message'.tr(),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(modalContext);
                      showLoginPrompt(context);
                    },
                    child: Text('diary.guest_login'.tr()),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pop(modalContext);
                    _openEntryModal();
                  },
                  child: Text('diary.guest_continue'.tr()),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
