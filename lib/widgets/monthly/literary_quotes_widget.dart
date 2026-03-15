import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/services/literary_quotes_service.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/screens/popups/popup_login.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/widgets/shared/app_pill_button.dart';

class LiteraryQuotesWidget extends StatefulWidget {
  final int month;
  final int year;

  const LiteraryQuotesWidget({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<LiteraryQuotesWidget> createState() => _LiteraryQuotesWidgetState();
}

class _LiteraryQuotesWidgetState extends State<LiteraryQuotesWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const Color _accent = Color(0xFF9A5DBA);
  static const int _premiumMaxPerDay = 3;
  static const int _devMaxPerDay = 99;

  bool _isLoading = true;
  bool _hasError = false;
  bool _hasRevealed = false;
  bool _initialized = false;

  LiteraryQuote? _quote;
  final GlobalKey _cardKey = GlobalKey();

  bool _isPremiumUser = false;
  int _dailyIndex = 0;

  bool get _isGuest => SupabaseConfig.client.auth.currentUser == null;

  String get _userKey => SupabaseConfig.client.auth.currentUser?.id ?? 'guest';

  String get _langKey => context.locale.languageCode.toLowerCase();

  String get _indexPrefsKey {
    final now = DateTime.now();
    return 'literary_quote_index_${_userKey}_${now.year}_${now.month}_${now.day}_$_langKey';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _initialize();
  }

  Future<void> _initialize() async {
    if (!mounted) return;
    final lang = context.locale.languageCode;
    var indexForFallback = _dailyIndex;
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final premium =
          LiteraryQuotesService.devPass ? true : await _safeCheckPremiumStatus();
      final storedIndex = await _safeLoadStoredIndex();
      final maxIndex = LiteraryQuotesService.devPass
          ? (_devMaxPerDay - 1)
          : (premium ? (_premiumMaxPerDay - 1) : 0);
      final index = storedIndex.clamp(0, maxIndex);
      indexForFallback = index;

      if (!mounted) return;
      setState(() {
        _isPremiumUser = premium;
        _dailyIndex = index;
      });

      final userKey = _userKey;
      final quote = await LiteraryQuotesService.getDailyQuote(
        userKey: userKey,
        lang: lang,
        variant: index,
      );

      if (!mounted) return;
      setState(() {
        _quote = quote;
        _hasRevealed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _quote = LiteraryQuotesService.fallbackQuote(
          lang: lang,
          variant: indexForFallback,
        );
        _hasRevealed = false;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _safeCheckPremiumStatus() async {
    if (_isGuest) return false;
    try {
      return await AccessControl.isPremium();
    } catch (_) {
      return false;
    }
  }

  Future<int> _safeLoadStoredIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_indexPrefsKey) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _setDailyIndex(int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_indexPrefsKey, value);
    } catch (_) {
      // ignore
    }
    if (!mounted) return;
    setState(() => _dailyIndex = value);
  }

  Future<void> _loadNextExcerpt() async {
    if (_isGuest && !LiteraryQuotesService.devPass) {
      showLoginPrompt(context);
      return;
    }

    if (!_isPremiumUser && !LiteraryQuotesService.devPass) {
      showPremiumPopup(context);
      return;
    }

    final maxIndex = (LiteraryQuotesService.devPass ? _devMaxPerDay : _premiumMaxPerDay) - 1;
    if (_dailyIndex >= maxIndex) {
      return;
    }

    final next = _dailyIndex + 1;
    await _setDailyIndex(next);
    await _initialize();
  }

  Future<void> _shareCardAsImage() async {
    if (_cardKey.currentContext == null) return;
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      await Share.shareXFiles(
        [
          XFile.fromData(
            pngBytes,
            mimeType: 'image/png',
            name: 'literary_excerpt.png',
          ),
        ],
        text: 'literary_quotes.share_caption'.tr(),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('literary_quotes.share_error'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleWrite() {
    context.go('/diary', extra: DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final showOffline = _hasError && _quote == null && !_isLoading;
    final showFallbackNote = !showOffline && !_isLoading && _quote?.source == 'fallback';
    final showPublicDomainNote =
        !showOffline && !_isLoading && _quote?.source == 'public_domain';
    final canUseActions = _quote != null && _hasRevealed;
    final maxIndex =
        (LiteraryQuotesService.devPass ? _devMaxPerDay : _premiumMaxPerDay) - 1;
    final canGenerateMore = (_isPremiumUser || LiteraryQuotesService.devPass) &&
        _dailyIndex < maxIndex;

    return MonthPageTemplate(
      month: widget.month,
      year: widget.year,
      title: '',
      pageLabel: 'literary_quotes.page_label'.tr(),
      labelColor: _accent,
      description: 'literary_quotes.subtitle'.tr(),
      child: Column(
        children: [
          const SizedBox(height: 28),
          RepaintBoundary(
            key: _cardKey,
            child: _LiteraryQuoteCard(
              accent: _accent,
              quote: _quote,
              isLoading: _isLoading,
              hasRevealed: _hasRevealed,
            ),
          ),
          if (_quote == null && !_isLoading && !showOffline)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'literary_quotes.empty'.tr(),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 14),

          // Ações (inspirado em Chapters)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: AppPillButton(
                    text: showOffline
                        ? 'common.try_again'.tr()
                        : (!_hasRevealed
                            ? 'literary_quotes.reveal'.tr()
                            : (_isPremiumUser
                                ? (canGenerateMore
                                    ? 'literary_quotes.new'.tr()
                                    : 'literary_quotes.come_back'.tr())
                                : 'literary_quotes.new_premium'.tr())),
                    onPressed: showOffline
                        ? _initialize
                        : (_quote == null && !_isLoading)
                            ? null
                            : () async {
                                if (!_hasRevealed) {
                                  setState(() => _hasRevealed = true);
                                  return;
                                }
                                if (_isPremiumUser) {
                                  if (!canGenerateMore) return;
                                  await _loadNextExcerpt();
                                  return;
                                }

                                if (LiteraryQuotesService.devPass) {
                                  if (!canGenerateMore) return;
                                  await _loadNextExcerpt();
                                  return;
                                }

                                if (_isGuest) {
                                  showLoginPrompt(context);
                                  return;
                                }

                                showPremiumPopup(context);
                              },
                    backgroundColor: showOffline
                        ? _accent.withValues(alpha: 0.18)
                        : _accent,
                    foregroundColor: showOffline ? _accent : Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    side: BorderSide(
                      color: showOffline
                          ? _accent.withValues(alpha: 0.20)
                          : Colors.transparent,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _MiniIconAction(
                  icon: Icons.photo_camera_outlined,
                  accent: _accent,
                  onPressed: canUseActions ? _shareCardAsImage : null,
                  tooltip: 'literary_quotes.share'.tr(),
                ),
                const SizedBox(width: 10),
                _MiniIconAction(
                  icon: Icons.edit_outlined,
                  accent: _accent,
                  onPressed: _hasRevealed ? _handleWrite : null,
                  tooltip: 'literary_quotes.write'.tr(),
                ),
              ],
            ),
          ),
          if (showOffline)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'common.offline_message'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.45),
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ),
          if (showFallbackNote)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'literary_quotes.fallback_note'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.45),
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ),
          if (showPublicDomainNote)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'literary_quotes.public_domain_note'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.45),
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _MiniIconAction extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final VoidCallback? onPressed;
  final String? tooltip;

  const _MiniIconAction({
    required this.icon,
    required this.accent,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: accent.withValues(alpha: enabled ? 0.18 : 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: enabled ? 0.06 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 22,
          color: enabled
              ? accent.withValues(alpha: 0.85)
              : Colors.black.withValues(alpha: 0.25),
        ),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}

class _LiteraryQuoteCard extends StatelessWidget {
  final Color accent;
  final LiteraryQuote? quote;
  final bool isLoading;
  final bool hasRevealed;

  const _LiteraryQuoteCard({
    super.key,
    required this.accent,
    required this.quote,
    required this.isLoading,
    required this.hasRevealed,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final maxWidth = isTablet ? 520.0 : 420.0;
    final cardHeight = isTablet ? 520.0 : 480.0;

    final q = quote;
    final showContent = q != null && hasRevealed;

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
                    accent.withValues(alpha: 0.20),
                    const Color(0xFFF8EDF2).withValues(alpha: 0.55),
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
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 30, 22, 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        '❝',
                        style: TextStyle(
                          fontSize: 44,
                          height: 1.0,
                          color: accent.withValues(alpha: 0.35),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: showContent
                              ? Text(
                                  q.quote,
                                  key: const ValueKey('quote'),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.robotoSerif(
                                    fontSize: 15,
                                    height: 2.05,
                                    letterSpacing: 0.35,
                                    color: Colors.black.withValues(alpha: 0.82),
                                    fontWeight: FontWeight.w400,
                                  ),
                                )
                              : Column(
                                  key: const ValueKey('placeholder'),
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      isLoading
                                          ? 'literary_quotes.loading'.tr()
                                          : 'literary_quotes.placeholder'.tr(),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.robotoSerif(
                                        fontSize: 14,
                                        height: 1.8,
                                        letterSpacing: 0.45,
                                        color: Colors.black.withValues(alpha: 0.40),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (showContent) ...[
                      Text(
                        '— ${q.author}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.robotoSerif(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.15,
                          color: accent.withValues(alpha: 0.95),
                        ),
                      ),
                      if ((q.work ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          q.work!.trim(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.robotoSerif(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.10,
                            color: Colors.black.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ],
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
