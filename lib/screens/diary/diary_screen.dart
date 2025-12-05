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
import 'package:myyearmystory/utils/access_control.dart';



class DiaryScreen extends StatefulWidget {
  final DateTime date;

  const DiaryScreen({
    super.key,
    required this.date,
  });

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final TextEditingController _entryController = TextEditingController();
  List<DiaryEntryModel> _entries = [];
  bool _isLoading = false;
  bool _isPremiumUser = false;

  late DateTime _selectedDate;
  String _selectedIcon = "😊";

  final int _maxFreeEntries = 3;

  final List<String> moodIcons = ["😊", "😢", "🍀", "😐", "🤯"];
  final List<Color> diaryUserThemes = [
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
  _selectedDate = widget.date;  // ❤️ agora carrega o dia enviado pelo calendário
  _checkPremiumStatus();
  _loadEntries();
}
  Future<void> _checkPremiumStatus() async {
    final premium = await AccessControl.isPremium();
    setState(() => _isPremiumUser = premium);
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

      final dateArg = ModalRoute.of(context)?.settings.arguments;

      List<DiaryEntryModel> filtered = entries;

      // ⭐ Se veio uma data do calendário, filtra aqui
      if (dateArg is DateTime) {
        filtered = entries.where((e) =>
          e.entryDate.year == dateArg.year &&
          e.entryDate.month == dateArg.month &&
          e.entryDate.day == dateArg.day
        ).toList();
      }

      setState(() {
        _entries = filtered;
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

    // Free user limit
    if (!_isPremiumUser && _entries.length >= _maxFreeEntries) {
      showPremiumPopup(context);
      return;
    }

    _showNewEntryDialog();
  }

  @override
  Widget build(BuildContext context) {





    return MainScaffold(
      currentIndex: 2,
      body: Stack(
        children: [
          Container(color: _userThemeColor.withOpacity(0.10)),

          Column(
            children: [
              // 🌸 Título padronizado (SEM LOGO)
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
                    Text(
                      'diary.title'.tr().toUpperCase(),
                      style: GoogleFonts.robotoMono(
                        fontSize: 20,
                        color: Color.fromARGB(221, 143, 50, 98),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'diary.subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),

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

            Expanded(
  child: _isLoading
      ? _buildLoadingState()
      : _entries.isEmpty
          ? _buildDayEmptyState() // ← vazio de um dia filtrado
          : _buildEntriesList(),
),



    // nada de fechar Column aqui!
  ],
),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _handleNewEntry,
              backgroundColor: _userThemeColor,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() => const Center(child: CircularProgressIndicator());

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'diary.empty_title'.tr(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _userThemeColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'diary.empty_description'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _handleNewEntry,
              icon: const Icon(Icons.edit_rounded),
              label: Text('diary.first_entry_button'.tr()),
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


Widget _buildDayEmptyState() {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
       "diary.no_entries_day".tr(),
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black54,
        ),
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
        itemBuilder: (context, index) => _buildEntryCard(_entries[index]),
      ),
    );
  }

  Widget _buildEntryCard(DiaryEntryModel entry) {
    return Card(
      color: Colors.white,
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
                          Text('diary.edit'.tr()),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Text('diary.delete'.tr(),
                              style: const TextStyle(color: Colors.red)),
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

  Widget _buildDateTag(DiaryEntryModel entry) {
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
  //   MODAL NOVA ENTRADA (SEM ÍCONE)
  // -----------------------------

  void _showNewEntryDialog() {
    _entryController.clear();
    _selectedIcon = "😊";
    _selectedDate = widget.date;


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
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight * 0.6,
                maxHeight: constraints.maxHeight * 0.95,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ÍCONE REMOVIDO
                    const SizedBox(height: 12),

                    Text(
                      'diary.new_entry'.tr(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 22),

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
                                color: isSelected
                                    ? _userThemeColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Text(icon,
                                style: const TextStyle(fontSize: 26)),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: _selectDateFromEdit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F6F3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today,
                                size: 16, color: _userThemeColor),
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

                    Flexible(
                      child: TextField(
                        controller: _entryController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
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

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('diary.cancel'.tr()),
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
                            child: Text('diary.save'.tr()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

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
        moodIcon: _selectedIcon,
      );

      await _loadEntries();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFA1A8F0),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text(
            'diary.saved_success'.tr(),
            style: const TextStyle(
              color: Color(0xFF4A2C5C),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint("${'diary.error_saving_entry'.tr()}: $e");

    }
  }

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

  void _deleteEntry(DiaryEntryModel entry) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('diary.delete_title'.tr()),
        content: Text('diary.delete_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('diary.cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await DiaryService.deleteEntry(entry.id);
              await _loadEntries();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.orange,
                  content: Text('diary.deleted_success'.tr()),
                ),
              );
            },
            child: Text('diary.delete'.tr(),
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
  'month.jan'.tr(), 'month.feb'.tr(), 'month.mar'.tr(), 'month.apr'.tr(),
  'month.may'.tr(), 'month.jun'.tr(), 'month.jul'.tr(), 'month.aug'.tr(),
  'month.sep'.tr(), 'month.oct'.tr(), 'month.nov'.tr(), 'month.dec'.tr(),
];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
