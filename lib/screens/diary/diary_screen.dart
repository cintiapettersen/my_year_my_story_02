import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myyearmystory/models/diary_entry.dart';
import 'package:myyearmystory/services/diary_service.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/widgets/shared/show_login_prompt.dart';
import 'package:myyearmystory/widgets/shared/main_scaffold.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:myyearmystory/widgets/shared/app_pill_button.dart';

enum _DiaryAiMode { reflection, writing }

enum _DiaryDateFilterType { month, day, range }

class DiaryScreen extends StatefulWidget {
  final DateTime date;

  const DiaryScreen({super.key, required this.date});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final TextEditingController _entryController = TextEditingController();

  List<DiaryEntryModel> _entries = [];

  _DiaryDateFilterType? _dateFilterType;
  DateTime? _dateFilterStart;
  DateTime? _dateFilterEndExclusive;

  bool _isLoading = false;
  bool _isSavingEntry = false;
  bool _isPremiumUser = false;
  DiaryEntryModel? _editingEntry;

  String? _aiResponse;
  List<String> _suggestedWords = [];
  bool _isLoadingAi = false;
  StateSetter? _entryModalSetState;
  String? _reflectionSourceText;
  bool _isReflectionVisible = false;

  Timer? _draftAutosaveTimer;
  String? _detectedTextLanguageCode;

  @override
  void dispose() {
    _draftAutosaveTimer?.cancel();
    _entryController.dispose();
    super.dispose();
  }

  void _updateEntryModal(VoidCallback fn) {
    final setter = _entryModalSetState;

    if (setter != null && mounted) {
      try {
        setter(fn);
        return;
      } catch (_) {
        _entryModalSetState = null;
      }
    }

    if (mounted) {
      setState(fn);
    }
  }

  String? _detectLanguageCode(String text) {
    // Very small heuristic: compares common stop-words.
    // Returns 'pt', 'en', or null (unknown/low confidence).
    final words =
        text
            .toLowerCase()
            .replaceAll(RegExp(r"[^a-zA-ZÀ-ÿ'\s]"), ' ')
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .toList();

    if (words.length < 10) return null;

    const pt = {
      'que',
      'nao',
      'não',
      'para',
      'uma',
      'um',
      'você',
      'voce',
      'eu',
      'me',
      'minha',
      'meu',
      'isso',
      'com',
      'por',
      'porque',
      'mas',
      'foi',
      'estou',
      'tá',
      'ta',
    };
    const en = {
      'the',
      'and',
      'to',
      'i',
      'you',
      'my',
      'me',
      'is',
      'are',
      'was',
      'were',
      'because',
      'but',
      'this',
      'that',
      'for',
      'with',
      'in',
      'on',
    };

    var ptScore = 0;
    var enScore = 0;
    for (final w in words.take(80)) {
      if (pt.contains(w)) ptScore++;
      if (en.contains(w)) enScore++;
    }

    if (ptScore >= 6 && (ptScore - enScore) >= 3) return 'pt';
    if (enScore >= 6 && (enScore - ptScore) >= 3) return 'en';
    return null;
  }

  static const Duration _draftAutosaveDelay = Duration(seconds: 12);
  static const String _prefsKeyDiaryDraft = 'diary_draft';

  String _yyyyMmDdKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _draftKey() {
    final user = SupabaseConfig.client.auth.currentUser;
    final userPart = user?.id ?? 'guest';
    final datePart = _yyyyMmDdKey(_selectedDate);
    final editPart = _editingEntry?.id;
    return editPart == null
        ? '${_prefsKeyDiaryDraft}_${userPart}_$datePart'
        : '${_prefsKeyDiaryDraft}_${userPart}_edit_$editPart';
  }

  void _scheduleDraftAutosave() {
    _draftAutosaveTimer?.cancel();
    _draftAutosaveTimer = Timer(_draftAutosaveDelay, () async {
      await _saveDraftNow();
    });
  }

  void _handleEntryTextChanged(String value) {
    _updateDetectedLanguageHint();
    _scheduleDraftAutosave();

    final trimmed = value.trim();
    final hadReflection = _reflectionSourceText != null && _aiResponse != null;
    final reflectionStillMatches =
        _reflectionSourceText != null && trimmed == _reflectionSourceText;

    // If the user changes the text after generating, allow a new generation.
    if (hadReflection && !reflectionStillMatches) {
      _updateEntryModal(() {
        _aiResponse = null;
        _suggestedWords = [];
        _reflectionSourceText = null;
        _isReflectionVisible = false;
      });
    }
  }

  void _updateDetectedLanguageHint() {
    final detected = _detectLanguageCode(_entryController.text);
    _updateEntryModal(() {
      _detectedTextLanguageCode = detected;
    });
  }

  Future<void> _saveDraftNow() async {
    final draft = _entryController.text;
    if (draft.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey(), draft);
  }

  Future<void> _restoreDraftIfAny({required bool isEditing}) async {
    if (isEditing) return;
    if (_entryController.text.trim().isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_draftKey());
    if (saved == null || saved.trim().isEmpty) return;

    _entryController
      ..text = saved
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: saved.length),
      );
    _updateDetectedLanguageHint();
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey());
  }

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

      final start = _dateFilterStart;
      final endExclusive = _dateFilterEndExclusive;
      final entries =
          start != null && endExclusive != null
              ? await DiaryService.getEntriesByDateRange(start, endExclusive)
              : await DiaryService.getEntries();

      if (!mounted) return;
      setState(() {
        _entries = entries;
      });
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
    return _entries
        .where(
          (e) => e.entryDate.year == now.year && e.entryDate.month == now.month,
        )
        .length;
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
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _entries.isEmpty
                        ? _buildEmptyState(isFiltered: _hasActiveDateFilter)
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
                'diary.title'.tr().toLowerCase(),
                style: GoogleFonts.monteCarlo(
                  fontSize: 35,
                  fontWeight: FontWeight.w600,
                  color: const Color.fromARGB(221, 0, 0, 0),
                  letterSpacing: 1.5,
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
                children:
                    diaryUserThemes.map((color) {
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
              const SizedBox(height: 18),
              _buildDateFilterControl(),
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

  bool get _hasActiveDateFilter =>
      _dateFilterStart != null && _dateFilterEndExclusive != null;

  Widget _buildDateFilterControl() {
    return Material(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: _showDateFilterSheet,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _userThemeColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 19,
                color: _userThemeColor,
              ),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  _dateFilterLabel(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_hasActiveDateFilter)
                InkWell(
                  onTap: _clearDateFilter,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                )
              else
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: Colors.black.withValues(alpha: 0.55),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateFilterLabel() {
    final start = _dateFilterStart;
    final endExclusive = _dateFilterEndExclusive;
    if (start == null || endExclusive == null) {
      return 'diary.date_filter_all'.tr();
    }

    final locale = context.locale.toString();
    switch (_dateFilterType) {
      case _DiaryDateFilterType.month:
        return DateFormat.yMMMM(locale).format(start);
      case _DiaryDateFilterType.day:
        return DateFormat.yMMMd(locale).format(start);
      case _DiaryDateFilterType.range:
        final endInclusive = DateTime(
          endExclusive.year,
          endExclusive.month,
          endExclusive.day - 1,
        );
        return 'diary.date_filter_range_label'.tr(
          args: [
            DateFormat.yMMMd(locale).format(start),
            DateFormat.yMMMd(locale).format(endInclusive),
          ],
        );
      case null:
        return 'diary.date_filter_all'.tr();
    }
  }

  Future<void> _showDateFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'diary.date_filter_title'.tr(),
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _buildDateFilterOption(
                  context: sheetContext,
                  icon: Icons.calendar_view_month_outlined,
                  title: 'diary.date_filter_month'.tr(),
                  onTap: _selectMonthFilter,
                ),
                _buildDateFilterOption(
                  context: sheetContext,
                  icon: Icons.today_outlined,
                  title: 'diary.date_filter_day'.tr(),
                  onTap: _selectDayFilter,
                ),
                _buildDateFilterOption(
                  context: sheetContext,
                  icon: Icons.date_range_outlined,
                  title: 'diary.date_filter_range'.tr(),
                  onTap: _selectRangeFilter,
                ),
                _buildDateFilterOption(
                  context: sheetContext,
                  icon: Icons.filter_alt_off_outlined,
                  title: 'diary.date_filter_clear'.tr(),
                  onTap: _clearDateFilter,
                  enabled: _hasActiveDateFilter,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateFilterOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return ListTile(
      enabled: enabled,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _userThemeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: _userThemeColor, size: 21),
      ),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
  }

  Future<void> _selectMonthFilter() async {
    final initial = _dateFilterStart ?? DateTime.now();
    var selectedMonth = initial.month;
    var selectedYear = initial.year;
    final currentYear = DateTime.now().year;

    final selection = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final locale = context.locale.toString();
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text('diary.date_filter_month_title'.tr()),
              content: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedMonth,
                      decoration: InputDecoration(
                        labelText: 'diary.date_filter_month_label'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (var month = 1; month <= 12; month++)
                          DropdownMenuItem(
                            value: month,
                            child: Text(
                              DateFormat.MMMM(
                                locale,
                              ).format(DateTime(2024, month)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedMonth = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedYear,
                      decoration: InputDecoration(
                        labelText: 'diary.date_filter_year_label'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (var year = currentYear + 5; year >= 2000; year--)
                          DropdownMenuItem(value: year, child: Text('$year')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedYear = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('diary.date_filter_cancel'.tr()),
                ),
                FilledButton(
                  onPressed:
                      () => Navigator.of(
                        dialogContext,
                      ).pop(DateTime(selectedYear, selectedMonth)),
                  child: Text('diary.date_filter_apply'.tr()),
                ),
              ],
            );
          },
        );
      },
    );

    if (selection == null || !mounted) return;
    final endExclusive = DateTime(selection.year, selection.month + 1);
    _applyDateFilter(
      type: _DiaryDateFilterType.month,
      start: selection,
      endExclusive: endExclusive,
    );
  }

  Future<void> _selectDayFilter() async {
    final now = DateTime.now();
    final initial = _dateFilterStart ?? now;
    final selection = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5, 12, 31),
      helpText: 'diary.date_filter_day_title'.tr(),
      cancelText: 'diary.date_filter_cancel'.tr(),
      confirmText: 'diary.date_filter_apply'.tr(),
    );

    if (selection == null || !mounted) return;
    final start = DateTime(selection.year, selection.month, selection.day);
    _applyDateFilter(
      type: _DiaryDateFilterType.day,
      start: start,
      endExclusive: DateTime(start.year, start.month, start.day + 1),
    );
  }

  Future<void> _selectRangeFilter() async {
    final now = DateTime.now();
    final initialStart = _dateFilterStart ?? now;
    final currentEndExclusive = _dateFilterEndExclusive;
    final initialEnd =
        currentEndExclusive == null
            ? initialStart
            : DateTime(
              currentEndExclusive.year,
              currentEndExclusive.month,
              currentEndExclusive.day - 1,
            );
    final selection = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5, 12, 31),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      helpText: 'diary.date_filter_range_title'.tr(),
      cancelText: 'diary.date_filter_cancel'.tr(),
      confirmText: 'diary.date_filter_apply'.tr(),
      saveText: 'diary.date_filter_apply'.tr(),
    );

    if (selection == null || !mounted) return;
    final start = DateTime(
      selection.start.year,
      selection.start.month,
      selection.start.day,
    );
    final inclusiveEnd = DateTime(
      selection.end.year,
      selection.end.month,
      selection.end.day,
    );
    _applyDateFilter(
      type: _DiaryDateFilterType.range,
      start: start,
      endExclusive: DateTime(
        inclusiveEnd.year,
        inclusiveEnd.month,
        inclusiveEnd.day + 1,
      ),
    );
  }

  void _applyDateFilter({
    required _DiaryDateFilterType type,
    required DateTime start,
    required DateTime endExclusive,
  }) {
    setState(() {
      _dateFilterType = type;
      _dateFilterStart = start;
      _dateFilterEndExclusive = endExclusive;
    });
    _loadEntries();
  }

  void _clearDateFilter() {
    if (!_hasActiveDateFilter) return;
    setState(() {
      _dateFilterType = null;
      _dateFilterStart = null;
      _dateFilterEndExclusive = null;
    });
    _loadEntries();
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
                      Text(
                        entry.moodIcon ?? "😊",
                        style: const TextStyle(fontSize: 18),
                      ),
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
                    itemBuilder:
                        (_) => [
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
        _entryModalSetState = modalSetState;
        return SafeArea(
          child: Padding(
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
                  /// 🔹 CONTEÚDO ROLÁVEL
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          /// Título
                          Text(
                            'diary.new_entry'.tr(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 24),

                          /// Emojis
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children:
                                moodIcons.map((icon) {
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
                                        color:
                                            selected
                                                ? _userThemeColor.withOpacity(
                                                  0.25,
                                                )
                                                : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color:
                                              selected
                                                  ? _userThemeColor
                                                  : Colors.transparent,
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

                          /// TextField
                          TextField(
                            controller: _entryController,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            textCapitalization: TextCapitalization.sentences,
                            enableSuggestions: true,
                            autocorrect: true,
                            smartQuotesType: SmartQuotesType.enabled,
                            smartDashesType: SmartDashesType.enabled,
                            maxLines: null,
                            onChanged: _handleEntryTextChanged,
                            decoration: InputDecoration(
                              hintText: 'diary.hint_text'.tr(),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),

                          if (_detectedTextLanguageCode != null &&
                              _detectedTextLanguageCode !=
                                  context.locale.languageCode)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'diary.language_hint'.tr(
                                  args: [
                                    (_detectedTextLanguageCode == 'en'
                                            ? 'diary.language_english'
                                            : 'diary.language_portuguese')
                                        .tr(),
                                  ],
                                ),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.2,
                                  color: Colors.black.withOpacity(0.55),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                          const SizedBox(height: 12),

                          /// Botão refletir
                          SizedBox(
                            width: double.infinity,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFFF2D8D),
                                    const Color(0xFFFF2D8D).withOpacity(0.85),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFF2D8D,
                                    ).withOpacity(0.28),
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _onReflectionButtonPressed,
                                icon: Icon(
                                  (_reflectionSourceText ==
                                              _entryController.text.trim() &&
                                          _aiResponse != null)
                                      ? (_isReflectionVisible
                                          ? Icons.expand_less
                                          : Icons.expand_more)
                                      : Icons.favorite_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  (_reflectionSourceText ==
                                              _entryController.text.trim() &&
                                          _aiResponse != null)
                                      ? 'diary.ai_action_button_read_reflection'
                                          .tr()
                                      : 'diary.ai_action_button'.tr(),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'diary.ai_helper_private'.tr(),
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.25,
                              color: Colors.black.withOpacity(0.55),
                            ),
                          ),

                          const SizedBox(height: 12),

                          /// Loading
                          if (_isLoadingAi)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: CircularProgressIndicator(),
                              ),
                            ),

                          /// Resposta da IA
                          if (_aiResponse != null &&
                              !_isLoadingAi &&
                              _isReflectionVisible)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Card(
                                elevation: 0,
                                color: Colors.grey[50],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: _userThemeColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _aiResponse!,
                                        style: const TextStyle(height: 1.45),
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        children:
                                            _suggestedWords
                                                .map(
                                                  (word) => ActionChip(
                                                    label: Text(word),
                                                    backgroundColor:
                                                        _userThemeColor
                                                            .withOpacity(0.12),
                                                    labelStyle: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: _userThemeColor,
                                                    ),
                                                    onPressed:
                                                        () =>
                                                            _insertSuggestedWord(
                                                              word,
                                                            ),
                                                  ),
                                                )
                                                .toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: 20),

                          /// Aviso visitante
                          if (SupabaseConfig.client.auth.currentUser == null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEEF4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFF2C6D6),
                                ),
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

                          const SizedBox(height: 16),

                          AppPillButton(
                            expand: true,
                            backgroundColor: _userThemeColor,
                            text: 'diary.save'.tr(),
                            onPressed:
                                _isSavingEntry
                                    ? null
                                    : () async {
                                      if (_isSavingEntry) return;
                                      setState(() => _isSavingEntry = true);
                                      try {
                                        final user =
                                            SupabaseConfig
                                                .client
                                                .auth
                                                .currentUser;
                                        if (user == null) {
                                          showLoginPrompt(context);
                                          return;
                                        }

                                        await _saveEntry();
                                        if (!context.mounted) return;

                                        await Navigator.of(context).maybePop();
                                      } finally {
                                        if (mounted) {
                                          setState(
                                            () => _isSavingEntry = false,
                                          );
                                        }
                                      }
                                    },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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

      await _clearDraft();
      _editingEntry = null;
      await _loadEntries();
    } catch (e) {
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

  Future<void> _onReflectionButtonPressed() async {
    final text = _entryController.text.trim();
    if (text.length < 100) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('diary.ai_min_characters'.tr())));
      return;
    }

    final hasReflectionForCurrentText =
        _reflectionSourceText != null &&
        _reflectionSourceText == text &&
        _aiResponse != null;

    if (hasReflectionForCurrentText) {
      _updateEntryModal(() {
        _isReflectionVisible = !_isReflectionVisible;
      });
      return;
    }

    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      showLoginPrompt(context);
      return;
    }

    await _callDiaryAi(text);
  }

  // DIARIO INTELIGENTE

  Future<void> _callDiaryAi(String text) async {
    if (text.trim().isEmpty) return;

    _updateEntryModal(() {
      _isLoadingAi = true;
      _aiResponse = null;
      _suggestedWords = [];
    });

    try {
      final detectedLanguageCode =
          _detectLanguageCode(text) ?? context.locale.languageCode;
      final prompt = _buildPrompt(text, languageCode: detectedLanguageCode);

      final response = await DiaryService.generateDiaryWithAI(prompt);

      if (!mounted) return;

      _updateEntryModal(() {
        _aiResponse = response;
        _reflectionSourceText = text.trim();
        _isReflectionVisible = true;
        _isLoadingAi = false;
      });
    } catch (e) {
      if (!mounted) return;

      _updateEntryModal(() {
        _aiResponse =
            "Não foi possível gerar a reflexão agora. Tente novamente em instantes.";
        _reflectionSourceText = null;
        _isReflectionVisible = false;
        _isLoadingAi = false;
      });
    }
  }

  String _buildPrompt(String text, {required String languageCode}) {
    final normalized = languageCode.trim().toLowerCase();
    if (normalized.startsWith('en')) {
      return '''Read the journal entry below.

Rules:
- Reply in the same language as the text (English).
- Use light and accessible language for teenagers.
- Keep it under 110 words.
- Do not give clinical advice or diagnoses.
- Do not use emojis.
- Focus more on the inner experience than on the narrative.
- Avoid dramatic or intense language.
- End with ONE simple question that encourages continued writing.
- Prioritize a calm, supportive, and gentle tone.
- Aim to leave a sense of relief or emotional settling.
- Avoid intensifying emotions.

Structure:

1) Gently validate.
2) Suggest a light idea to continue writing.
3) Finish with a short, reflective question that encourages self-awareness (avoid questions about what happened).

Text:
"""
$text
"""''';
    }

    return '''Leia o texto do diário abaixo.

	Regras:
	- Responda no mesmo idioma do texto (português).
	- Use linguagem leve e acessível para adolescentes.
	- Responda em até 110 palavras.
	- Não faça diagnóstico ou aconselhamento clínico.
	- Não use emojis.
	- Foque mais na experiência interna do que na narrativa.
  - Evite linguagem dramática ou intensa.
	- Termine com UMA pergunta simples que incentive a continuar escrevendo.
	- Priorize um tom calmo, acolhedor e leve.
	- Busque deixar uma sensação de alívio/assentamento emocional.
	- Evite intensificar emoções.

	Estrutura:
	
	1) Valide de forma gentil.
	2) Sugira uma ideia leve para continuar escrevendo.
	3) Finalize com uma pergunta curta e reflexiva que estimule autoconhecimento.(evite perguntas sobre o que aconteceu).


	Texto:
	"""
	$text
	"""''';
  }

  void _handleAiResponse(String raw) {
    final parts = raw.split('PALAVRAS:');
    final body = parts.first.trim();
    final wordsSection = parts.length > 1 ? parts[1] : '';

    final extracted =
        wordsSection
            .split(RegExp(r'[\n\r]+'))
            .map((w) => w.trim())
            .where((w) => w.isNotEmpty)
            .toList();

    _updateEntryModal(() {
      _aiResponse = body;
      _suggestedWords = extracted.take(3).toList();
    });
  }

  void _insertSuggestedWord(String word) {
    final current = _entryController.text;
    final spacer = current.endsWith(' ') || current.isEmpty ? '' : ' ';
    final updated = '$current$spacer$word';
    _entryController
      ..text = updated
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: updated.length),
      );
    _updateDetectedLanguageHint();
    _scheduleDraftAutosave();
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
    _aiResponse = null;
    _suggestedWords = [];
    _isLoadingAi = false;
    _reflectionSourceText = null;
    _isReflectionVisible = false;
    _entryModalSetState = null;
    _draftAutosaveTimer?.cancel();
    _draftAutosaveTimer = null;
    _detectedTextLanguageCode = _detectLanguageCode(_entryController.text);

    final future = showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _buildEntryDialog(),
    );
    future.whenComplete(() {
      _entryModalSetState = null;
      _draftAutosaveTimer?.cancel();
      _draftAutosaveTimer = null;
    });

    unawaited(_restoreDraftIfAny(isEditing: isEditing));
  }

  // ===============================
  // DELETE ENTRY
  // ===============================
  void _deleteEntry(DiaryEntryModel entry) async {
    try {
      await DiaryService.deleteEntry(entry.id);
      await _loadEntries();
    } catch (e) {
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
  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String _formatTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  // ===============================
  // EMPTY STATE
  // ===============================
  Widget _buildEmptyState({required bool isFiltered}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFiltered
                  ? Icons.event_busy_outlined
                  : Icons.auto_stories_outlined,
              size: 42,
              color: _userThemeColor.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 14),
            Text(
              isFiltered
                  ? 'diary.date_filter_empty_title'.tr()
                  : 'diary.empty_title'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              isFiltered
                  ? 'diary.date_filter_empty_description'.tr()
                  : 'diary.empty_description'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.4,
                color: Colors.black.withValues(alpha: 0.62),
              ),
            ),
            if (isFiltered) ...[
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: _clearDateFilter,
                icon: const Icon(Icons.close, size: 18),
                label: Text('diary.date_filter_clear'.tr()),
              ),
            ],
          ],
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
                  contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
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

                            Future.microtask(() {
                              if (!mounted) return;
                              showLoginPrompt(context);
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFCD4B78),
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
                          Future.microtask(() {
                            _openEntryModal();
                          });
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
