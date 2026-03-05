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

enum _DiaryAiMode { reflection, writing }


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
    final words = text
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

    final entries = await DiaryService.getEntries();

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
                'diary.title'.tr().toLowerCase(),
                 style: GoogleFonts.monteCarlo (
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
        _entryModalSetState = modalSetState;
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

              /// 🔹 CONTEÚDO ROLÁVEL
              Expanded(
                child: SingleChildScrollView(
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
                                  color: selected
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
		                                color: const Color(0xFFFF2D8D)
		                                    .withOpacity(0.28),
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
                      if (_aiResponse != null && !_isLoadingAi && _isReflectionVisible)
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _aiResponse!,
                                    style: const TextStyle(height: 1.45),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    children: _suggestedWords
	                                        .map(
	                                          (word) => ActionChip(
	                                            label: Text(word),
	                                            backgroundColor:
	                                                _userThemeColor.withOpacity(0.12),
	                                            labelStyle: TextStyle(
	                                              fontWeight: FontWeight.w700,
	                                              color: _userThemeColor,
	                                            ),
	                                            onPressed: () =>
	                                                _insertSuggestedWord(word),
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
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              /// 🔹 BOTÃO FIXO NA BASE
              ElevatedButton(
                onPressed: _isSavingEntry
                    ? null
                    : () async {
                        if (_isSavingEntry) return;
                        setState(() => _isSavingEntry = true);
                        try {
                          final user =
                              SupabaseConfig.client.auth.currentUser;
                          if (user == null) {
                            showLoginPrompt(context);
                            return;
                          }

                          await _saveEntry();
                          if (!context.mounted) return;

                          await Navigator.of(context).maybePop();
                        } finally {
                          if (mounted) setState(() => _isSavingEntry = false);
                        }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('diary.ai_min_characters'.tr()),
        ),
      );
      return;
    }

    final hasReflectionForCurrentText =
        _reflectionSourceText != null && _reflectionSourceText == text && _aiResponse != null;

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
	    final prompt = _buildPrompt(
	      text,
	      languageCode: detectedLanguageCode,
	    );

    final response =
        await DiaryService.generateDiaryWithAI(prompt);

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

 String _buildPrompt(
   String text, {
   required String languageCode,
 }) {
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

    final extracted = wordsSection
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

  Future.microtask(() {
    if (!mounted) return;
    showLoginPrompt(context);
  });
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
