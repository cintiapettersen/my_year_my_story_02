import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:myyearmystory/widgets/shared/app_pill_button.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/widgets/shared/remote_data_wrapper.dart';

class BetweenLinesNote {
  final String id;
  final String text;
  final DateTime createdAt;

  const BetweenLinesNote({
    required this.id,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  static BetweenLinesNote? fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString().trim();
    final text = (json['text'] ?? '').toString().trim();
    final createdAtRaw = (json['createdAt'] ?? '').toString().trim();
    final createdAt = DateTime.tryParse(createdAtRaw);
    if (id.isEmpty || text.isEmpty || createdAt == null) return null;
    return BetweenLinesNote(id: id, text: text, createdAt: createdAt);
  }
}

class BetweenLinesWidget extends StatefulWidget {
  final int month;
  final int year;

  const BetweenLinesWidget({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<BetweenLinesWidget> createState() => _BetweenLinesWidgetState();
}

class _BetweenLinesWidgetState extends State<BetweenLinesWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const Color _accent = Color(0xFFE25BA6);

  final _controller = TextEditingController();

  bool _isLoading = true;
  bool _hasError = false;
  bool _isSaving = false;

  List<BetweenLinesNote> _notes = const [];

  String get _userKey =>
      Supabase.instance.client.auth.currentUser?.id ?? 'guest';

  String get _prefsKey => 'between_lines_${_userKey}_${widget.year}_${widget.month}';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      await _loadNotes();
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.trim().isEmpty) {
      _notes = const [];
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _notes = const [];
        return;
      }
      final parsed = <BetweenLinesNote>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final note = BetweenLinesNote.fromJson(
          Map<String, dynamic>.from(item),
        );
        if (note != null) parsed.add(note);
      }
      parsed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _notes = parsed;
    } catch (_) {
      _notes = const [];
    }
  }

  Future<void> _persistNotes(List<BetweenLinesNote> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final value = jsonEncode(notes.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, value);
  }

  Future<void> _saveNewNote() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final note = BetweenLinesNote(
        id: now.millisecondsSinceEpoch.toString(),
        text: text,
        createdAt: now,
      );
      final updated = [note, ..._notes];
      await _persistNotes(updated);
      if (!mounted) return;
      setState(() {
        _notes = updated;
        _controller.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE25BA6),
          content: Text(
            'between_lines.saved'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('between_lines.save_error'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatDate(DateTime date) {
    final locale = context.locale.languageCode;
    if (locale == 'en') {
      return DateFormat('MMM d, y', 'en_US').format(date);
    }
    return DateFormat('d MMM y', 'pt_BR').format(date);
  }

  void _openNotesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        var query = '';
        List<BetweenLinesNote> filtered = _notes;

        void applyFilter(StateSetter setStateSB, String value) {
          query = value.trim().toLowerCase();
          setStateSB(() {
            if (query.isEmpty) {
              filtered = _notes;
            } else {
              filtered =
                  _notes
                      .where((n) => n.text.toLowerCase().contains(query))
                      .toList(growable: false);
            }
          });
        }

        return StatefulBuilder(
          builder: (context, setStateSB) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, bottomInset + 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'between_lines.my_notes'.tr(),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) => applyFilter(setStateSB, v),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'between_lines.search_hint'.tr(),
                      filled: true,
                      fillColor: const Color(0xFFFFF7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 26),
                      child: Column(
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            size: 42,
                            color: Colors.black.withValues(alpha: 0.28),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            query.isEmpty
                                ? 'between_lines.empty'.tr()
                                : 'between_lines.no_results'.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.55),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final note = filtered[index];
                          final preview = note.text.replaceAll('\n', ' ').trim();
                          return ListTile(
                            title: Text(
                              preview,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(_formatDate(note.createdAt)),
                            onTap: () async {
                              Navigator.of(sheetContext).pop();
                              // Wait the sheet to close before opening another one.
                              await Future.delayed(const Duration(milliseconds: 200));
                              if (!mounted) return;
                              await _openNoteEditor(note);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openNoteEditor(BetweenLinesNote note) async {
    final editor = TextEditingController(text: note.text);
    try {
      final result = await showModalBottomSheet<_BetweenLinesEditResult>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, bottomInset + 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _formatDate(note.createdAt),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: editor,
                  minLines: 6,
                  maxLines: 12,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFFFF7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppPillButton(
                        expand: true,
                        backgroundColor: _accent,
                        text: 'between_lines.update'.tr(),
                        onPressed: () {
                          final updatedText = editor.text.trim();
                          if (updatedText.isEmpty) return;
                          Navigator.of(sheetContext).pop(
                            _BetweenLinesEditResult.updated(updatedText),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop(
                          const _BetweenLinesEditResult.deleted(),
                        );
                      },
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.redAccent,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

      if (result == null || !mounted) return;

      if (result.delete) {
        final updated = _notes.where((n) => n.id != note.id).toList();
        await _persistNotes(updated);
        if (!mounted) return;
        setState(() => _notes = updated);
        return;
      }

      final updatedText = result.text?.trim();
      if (updatedText == null || updatedText.isEmpty) return;

      final updated =
          _notes
              .map(
                (n) =>
                    n.id == note.id
                        ? BetweenLinesNote(
                          id: n.id,
                          text: updatedText,
                          createdAt: n.createdAt,
                        )
                        : n,
              )
              .toList(growable: false);
      await _persistNotes(updated);
      if (!mounted) return;
      setState(() => _notes = updated);
    } finally {
      editor.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final maxWidth = isTablet ? 520.0 : 420.0;
    final cardHeight = isTablet ? 520.0 : 480.0;

    return MonthPageTemplate(
      month: widget.month,
      year: widget.year,
      title: '',
      pageLabel: 'between_lines.page_label'.tr(),
      labelColor: _accent,
      description: 'between_lines.description'.tr(),
      child: RemoteDataWrapper(
        isLoading: _isLoading,
        hasError: _hasError,
        onRetry: _initialize,
        child: Column(
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: SizedBox(
                    height: cardHeight,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _accent.withValues(alpha: 0.22),
                            const Color(0xFFD7C3EE).withValues(alpha: 0.22),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 26,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'between_lines.card_title'.tr(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.robotoMono(
                                fontSize: 12,
                                letterSpacing: 1.5,
                                color: Colors.black.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7FA),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: _accent.withValues(alpha: 0.18),
                                  ),
                                ),
                                child: TextField(
                                  controller: _controller,
                                  maxLines: null,
                                  expands: true,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.robotoSerif(
                                    fontSize: 15,
                                    height: 1.55,
                                    color: Colors.black.withValues(alpha: 0.82),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'between_lines.hint'.tr(),
                                    hintStyle: TextStyle(
                                      color: Colors.black.withValues(alpha: 0.35),
                                      height: 1.4,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: AppPillButton(
                                    expand: true,
                                    backgroundColor: _accent,
                                    text: _isSaving
                                        ? 'between_lines.saving'.tr()
                                        : 'between_lines.save'.tr(),
                                    onPressed: _isSaving ? null : _saveNewNote,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  onPressed:
                                      _notes.isEmpty ? null : _openNotesSheet,
                                  icon: const Icon(Icons.search),
                                  color:
                                      _notes.isEmpty
                                          ? Colors.black.withValues(alpha: 0.25)
                                          : _accent,
                                  tooltip: 'between_lines.my_notes'.tr(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
          ],
        ),
      ),
    );
  }
}

class _BetweenLinesEditResult {
  final bool delete;
  final String? text;

  const _BetweenLinesEditResult._({required this.delete, required this.text});

  const _BetweenLinesEditResult.deleted() : this._(delete: true, text: null);

  factory _BetweenLinesEditResult.updated(String text) =>
      _BetweenLinesEditResult._(delete: false, text: text);
}
