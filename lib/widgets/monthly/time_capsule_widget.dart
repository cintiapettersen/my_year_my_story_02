import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/services/calendar_event_service.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/widgets/shared/remote_data_wrapper.dart';
import 'package:myyearmystory/widgets/shared/app_pill_button.dart';
import 'package:myyearmystory/screens/popups/popup_login.dart';

class TimeCapsuleWidget extends StatefulWidget {
  final int month;
  final int year;

  const TimeCapsuleWidget({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<TimeCapsuleWidget> createState() => _TimeCapsuleWidgetState();
}

class _TimeCapsuleWidgetState extends State<TimeCapsuleWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const Color _timeCapsuleAccent = Color(0xFF679bd3);

  final _messageController = TextEditingController();

  bool _isLoading = true;
  bool _hasError = false;
  bool _isSaving = false;
  bool _isEditing = true;

  DateTime? _remindAt;
  String? _eventId;
  List<String> _eventIds = const [];

  String get _userKey =>
      SupabaseConfig.client.auth.currentUser?.id ?? 'guest';

  String get _prefsEventIdsKey =>
      'time_capsule_event_ids_${_userKey}_${widget.year}_${widget.month}';

  String get _prefsEventIdKey =>
      'time_capsule_event_${_userKey}_${widget.year}_${widget.month}';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      await _loadEventIds();
      await _loadExisting();
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadEventIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsEventIdsKey);

    final ids = <String>[];
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            final id = (item ?? '').toString().trim();
            if (id.isNotEmpty) ids.add(id);
          }
        }
      } catch (_) {
        // ignore
      }
    }

    // Backward compatibility: if we have a legacy single id stored, migrate it.
    final legacyId = prefs.getString(_prefsEventIdKey);
    final legacy = (legacyId ?? '').trim();
    if (legacy.isNotEmpty && !ids.contains(legacy)) {
      ids.add(legacy);
      try {
        await prefs.setString(_prefsEventIdsKey, jsonEncode(ids));
      } catch (_) {
        // ignore
      }
    }

    _eventIds = ids;
  }

  Future<void> _persistEventIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsEventIdsKey, jsonEncode(ids));
  }

  Future<void> _loadExisting() async {
    final user = SupabaseConfig.client.auth.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_prefsEventIdKey);

    if (id == null || id.trim().isEmpty) return;
    _eventId = id;

    if (user == null) return;

    await _loadById(id);
  }

  Future<void> _loadById(String id) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    final row = await SupabaseConfig.client
        .from('calendar_events')
        .select('id, year, month, day, description')
        .eq('id', id)
        .maybeSingle();

    if (!mounted || row == null) return;

    setState(() {
      _eventId = id;
      _remindAt = DateTime(row['year'], row['month'], row['day']);
      _messageController.text = (row['description'] ?? '').toString();
      _isEditing = false;
    });
  }

  Future<void> _pickDate() async {
    if (!_isEditing) return;
    final now = DateTime.now();
    final initial = _remindAt ?? now.add(const Duration(days: 7));
    final initialClamped = initial.isBefore(now) ? now : initial;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialClamped,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 10, 12, 31),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: _timeCapsuleAccent,
              onPrimary: Colors.white,
              surface: const Color(0xFFFFF7FA),
              onSurface: Colors.black87,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFFFFF7FA),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;
    setState(() => _remindAt = picked);
  }

  String _formatDate(DateTime date) {
    final locale = context.locale.languageCode;
    if (locale == 'en') {
      return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _save() async {
    if (!_isEditing) return;
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      showLoginPrompt(context);
      return;
    }

    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('time_capsule.write_first'.tr()),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_remindAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('time_capsule.pick_date_first'.tr()),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      final colorHex = _timeCapsuleAccent.value.toRadixString(16).padLeft(8, '0');

      if (_eventId == null) {
        final id = await CalendarEventService.createEvent(
          userId: user.id,
          year: _remindAt!.year,
          month: _remindAt!.month,
          day: _remindAt!.day,
          hour: 9,
          title: 'time_capsule.alert_title'.tr(),
          description: message,
          color: colorHex,
          remind: true,
          repeatType: 'none',
          daysBefore: 0,
        );
        if (id == null || id.trim().isEmpty) {
          throw Exception('Failed to create time capsule event');
        }
        _eventId = id;
        final updatedIds = [..._eventIds];
        if (!updatedIds.contains(id)) {
          updatedIds.add(id);
          _eventIds = updatedIds;
          await _persistEventIds(updatedIds);
        }
      } else {
        await CalendarEventService.updateEvent(
          eventId: _eventId!,
          title: 'time_capsule.alert_title'.tr(),
          description: message,
          color: colorHex,
          hour: 9,
          remind: true,
          repeatType: 'none',
          daysBefore: 0,
        );
      }

      final prefs = await SharedPreferences.getInstance();
      if (_eventId != null) {
        await prefs.setString(_prefsEventIdKey, _eventId!);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE25BA6),
          content: Text(
            'time_capsule.saved_success'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() => _isEditing = false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('time_capsule.save_error'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _edit() {
    if (_isSaving) return;
    setState(() => _isEditing = true);
  }

  Future<void> _startNew() async {
    if (_isSaving) return;
    if (!mounted) return;

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('time_capsule.new_confirm_title'.tr()),
          content: Text('time_capsule.new_confirm_desc'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('time_capsule.new_confirm_cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('time_capsule.new_confirm_ok'.tr()),
            ),
          ],
        );
      },
    );

    if (shouldCreate != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsEventIdKey);
    } catch (_) {
      // ignore
    }

    if (!mounted) return;
    setState(() {
      _eventId = null;
      _remindAt = null;
      _messageController.clear();
      _isEditing = true;
    });
  }

  Future<void> _openSavedCapsulesSheet() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      showLoginPrompt(context);
      return;
    }
    if (_eventIds.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        Future<List<Map<String, dynamic>>> loadItems() async {
          final items = <Map<String, dynamic>>[];
          for (final id in _eventIds) {
            final row = await SupabaseConfig.client
                .from('calendar_events')
                .select('id, year, month, day, description')
                .eq('id', id)
                .maybeSingle();
            if (row != null) {
              items.add(Map<String, dynamic>.from(row));
            }
          }
          items.sort((a, b) {
            final ad = DateTime(a['year'], a['month'], a['day']);
            final bd = DateTime(b['year'], b['month'], b['day']);
            return bd.compareTo(ad);
          });
          return items;
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: loadItems(),
          builder: (context, snap) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, bottomInset + 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'time_capsule.my_capsules'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!snap.hasData)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (snap.data!.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'time_capsule.no_saved'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: snap.data!.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = snap.data![index];
                          final id = (item['id'] ?? '').toString();
                          final date = DateTime(
                            item['year'] as int,
                            item['month'] as int,
                            item['day'] as int,
                          );
                          final preview =
                              (item['description'] ?? '').toString().trim();
                          final isActive = _eventId == id;

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () async {
                                Navigator.of(sheetContext).pop();
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setString(_prefsEventIdKey, id);
                                if (!mounted) return;
                                setState(() {
                                  _eventId = id;
                                  _remindAt = date;
                                  _messageController.text = preview;
                                  _isEditing = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7FA),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color:
                                        isActive
                                            ? _timeCapsuleAccent.withValues(
                                              alpha: 0.55,
                                            )
                                            : _timeCapsuleAccent.withValues(
                                              alpha: 0.18,
                                            ),
                                    width: isActive ? 1.8 : 1.2,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatDate(date),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      preview,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.black.withValues(
                                          alpha: 0.72,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  AppPillButton(
                    expand: true,
                    backgroundColor: _timeCapsuleAccent,
                    text: 'time_capsule.new_button'.tr(),
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      await _startNew();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return MonthPageTemplate(
      month: widget.month,
      year: widget.year,
      title: '',
      pageLabel: 'time_capsule.page_label'.tr(),
      labelColor: _timeCapsuleAccent,
      description: 'time_capsule.description'.tr(),
      child: RemoteDataWrapper(
        isLoading: _isLoading,
        hasError: _hasError,
        onRetry: _initialize,
        child: Column(
          children: [
            const SizedBox(height: 28),
            _TimeCapsuleCard(
              monthAccent: _timeCapsuleAccent,
              messageController: _messageController,
              isEditing: _isEditing,
              remindAt: _remindAt,
              formattedDate: _remindAt == null ? null : _formatDate(_remindAt!),
              onPickDate: _pickDate,
            ),
            SizedBox(height: _isEditing ? 24 : 14),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child:
                    _isEditing
                        ? Column(
                          children: [
                            AppPillButton(
                              expand: true,
                              backgroundColor: _timeCapsuleAccent,
                              text:
                                  _isSaving
                                      ? 'time_capsule.saving'.tr()
                                      : 'time_capsule.save_button'.tr(),
                              onPressed: _isSaving ? null : _save,
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (_eventIds.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _openSavedCapsulesSheet,
                                child: Text(
                                  'time_capsule.my_capsules'.tr(),
                                  style: TextStyle(
                                    color: _timeCapsuleAccent.withValues(
                                      alpha: 0.9,
                                    ),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        )
                        : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                'time_capsule.saved_state'.tr(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black.withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: AppPillButton(
                                    expand: true,
                                    backgroundColor: _timeCapsuleAccent,
                                    text: 'time_capsule.edit_button'.tr(),
                                    onPressed: _edit,
                                    elevation: 4,
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppPillButton(
                                    expand: true,
                                    backgroundColor: Colors.white,
                                    foregroundColor: _timeCapsuleAccent,
                                    side: BorderSide(
                                      color: _timeCapsuleAccent.withValues(
                                        alpha: 0.45,
                                      ),
                                      width: 1.4,
                                    ),
                                    elevation: 0,
                                    text: 'time_capsule.new_button'.tr(),
                                    onPressed: _startNew,
                                    textStyle: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed:
                                  _eventIds.isEmpty
                                      ? null
                                      : _openSavedCapsulesSheet,
                              child: Text(
                                'time_capsule.my_capsules'.tr(),
                                style: TextStyle(
                                  color: _timeCapsuleAccent.withValues(
                                    alpha: 0.9,
                                  ),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _TimeCapsuleCard extends StatelessWidget {
  final Color monthAccent;
  final TextEditingController messageController;
  final bool isEditing;
  final DateTime? remindAt;
  final String? formattedDate;
  final VoidCallback onPickDate;

  const _TimeCapsuleCard({
    required this.monthAccent,
    required this.messageController,
    required this.isEditing,
    required this.remindAt,
    required this.formattedDate,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final maxWidth = isTablet ? 520.0 : 420.0;
    final cardHeight = isTablet ? 520.0 : 480.0;

    return Padding(
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
                    monthAccent.withValues(alpha: 0.22),
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
                      'time_capsule.card_title'.tr(),
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
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7FA),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: monthAccent.withValues(alpha: 0.18),
                          ),
                        ),
                        child: TextField(
                          controller: messageController,
                          readOnly: !isEditing,
                          maxLines: null,
                          expands: true,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.robotoSerif(
                            fontSize: 15,
                            height: 1.55,
                            color: Colors.black.withValues(alpha: 0.82),
                          ),
                          decoration: InputDecoration(
                            hintText: 'time_capsule.hint'.tr(),
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8EDF2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: monthAccent.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_active_outlined,
                            color: monthAccent.withValues(alpha: 0.85),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              remindAt == null
                                  ? 'time_capsule.pick_date'.tr()
                                  : '${'time_capsule.remind_on'.tr()} $formattedDate',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black.withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: isEditing ? onPickDate : null,
                            child: Text(
                              'time_capsule.choose'.tr(),
                              style: TextStyle(
                                color: monthAccent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
