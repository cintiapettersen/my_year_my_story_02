import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/services/did_you_know_service.dart';
import 'package:myyearmystory/utils/month_colors.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:myyearmystory/screens/popups/popup_login.dart';
import 'package:myyearmystory/widgets/shared/remote_data_wrapper.dart';
import 'package:myyearmystory/widgets/shared/app_pill_button.dart';


class DidYouKnowWidget extends StatefulWidget {
  final int month;
  final int year;

  const DidYouKnowWidget({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<DidYouKnowWidget> createState() => _DidYouKnowWidgetState();
}

class _DidYouKnowWidgetState extends State<DidYouKnowWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool get isGuest {
    return Supabase.instance.client.auth.currentUser == null;
  }

  final DidYouKnowService _service = DidYouKnowService();

  bool _isLoading = true;
  bool _hasError = false;

  bool isPremiumUser = false;
  bool _isRefreshing = false;

  List<Map<String, dynamic>> curiosities = [];
  int refreshCount = 0;


  final int maxRefresh = 3;

  final List<Color> categoryColors = const [
    Color(0xFF7FA9D1),
    Color(0xFFD7C3EE),
    Color(0xFFD84A75),
    Color(0xFFE78AC6),
    Color(0xFFCBA5E3),
    Color(0xFFD8CA7D),
  ];

 @override
void initState() {
  super.initState();
  _initializePage();
}

  String get _userKey =>
      Supabase.instance.client.auth.currentUser?.id ?? 'guest';

  int get _dayKey => DateTime.now().day;

  int get _cooldownBucket {
    final windowMs = const Duration(hours: 12).inMilliseconds;
    return DateTime.now().millisecondsSinceEpoch ~/ windowMs;
  }

  String get _refreshPrefsKey {
    return "refresh_did_you_know_${_userKey}_b$_cooldownBucket";
  }

  String get _seenPrefsKey {
    return "did_you_know_seen_${_userKey}_b$_cooldownBucket";
  }

Future<void> _initializePage() async {
  try {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    await _checkPremiumStatus();
    await _loadRefreshCount();
    await _loadCuriosities();
  } catch (e) {
   
    if (mounted) {
      setState(() => _hasError = true);
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}



  // 🔐 Premium
  Future<void> _checkPremiumStatus() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() => isPremiumUser = false);
      return;
    }

    final isPrem = await AccessControl.isPremium();
    if (!mounted) return;

    setState(() => isPremiumUser = isPrem);
  }

  // 🔢 Limite por usuário / guest
  Future<void> _loadRefreshCount() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      refreshCount = prefs.getInt(_refreshPrefsKey) ?? 0;
    });
  }

  // 📦 Dados
  Future<void> _loadCuriosities() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final storedSeenIds =
        prefs.getStringList(_seenPrefsKey) ?? const <String>[];

    // Busca geral para reconstruir "vistos" por id e garantir consistência
    final all = await _service.fetchAllCuriosities();
    if (!mounted) return;

    if (all.isEmpty) {
      setState(() => curiosities = []);
      return;
    }

    final byId = <String, Map<String, dynamic>>{};
    for (final item in all) {
      final id = item['id']?.toString();
      if (id != null && id.isNotEmpty) {
        byId[id] = item;
      }
    }

    final seen = <Map<String, dynamic>>[];
    for (final id in storedSeenIds) {
      final item = byId[id];
      if (item != null) seen.add(item);
    }

    // Primeira curiosidade do dia (persistida)
    if (seen.isEmpty) {
      final dailyCandidates = await _service.fetchDailyCuriosities();
      if (!mounted) return;

      if (dailyCandidates.isNotEmpty) {
        final daily = dailyCandidates.first;
        final dailyId = daily['id']?.toString();
        if (dailyId != null && dailyId.isNotEmpty) {
          await prefs.setStringList(_seenPrefsKey, [dailyId]);
          final resolved = byId[dailyId] ?? daily;
          seen.add(resolved);
        }
      }
    }

    if (!mounted) return;
    setState(() => curiosities = seen);
  } catch (e) {
    

    if (!mounted) return;

    setState(() {
      _hasError = true;   
    });
  }
}

  

  // 🔄 Refresh
  Future<void> _handleRefresh() async {
  await Future.delayed(const Duration(milliseconds: 120));
  if (!mounted) return;

  // 🔐 FREE / GUEST → bloqueia sempre
  if (isGuest) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    showLoginPrompt(context);
  });
  return;
}

if (!isPremiumUser) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    showPremiumPopup(context);
  });
  return;
}

  // 💎 PREMIUM → limite diário
  if (refreshCount >= maxRefresh) {
    return;
  }

  try {
    final prefs = await SharedPreferences.getInstance();

    final seenIds = (prefs.getStringList(_seenPrefsKey) ?? const <String>[])
        .toList(growable: true);
    final seenSet = seenIds.toSet();

    // tenta achar uma curiosidade nova dentro do conjunto "balanceado"
    final dailyCandidates = await _service.fetchDailyCuriosities();
    Map<String, dynamic>? newItem;
    for (final item in dailyCandidates) {
      final id = item['id']?.toString();
      if (id == null || id.isEmpty) continue;
      if (!seenSet.contains(id)) {
        newItem = item;
        seenIds.add(id);
        break;
      }
    }

    // fallback: busca no geral para achar qualquer id ainda não visto
    if (newItem == null) {
      final all = await _service.fetchAllCuriosities();
      for (final item in all) {
        final id = item['id']?.toString();
        if (id == null || id.isEmpty) continue;
        if (!seenSet.contains(id)) {
          newItem = item;
          seenIds.add(id);
          break;
        }
      }
    }

    if (newItem == null) return;

    await prefs.setStringList(_seenPrefsKey, seenIds);

    final newCount = refreshCount + 1;
    await prefs.setInt(_refreshPrefsKey, newCount);

    if (!mounted) return;
    setState(() {
      refreshCount = newCount;
      curiosities = [...curiosities, newItem!];
    });
  } catch (_) {
    if (!mounted) return;
    setState(() => _hasError = true);
  }
}


@override
Widget build(BuildContext context) {
  super.build(context);
  final currentButtonColor = getMonthColor(widget.month);

  return MonthPageTemplate(
    month: widget.month,
    year: widget.year,
    title: "",
    pageLabel: "did_you_know.title".tr(),
    labelColor: const Color(0xFFdbaf35),
    description: "did_you_know.desc.fixed".tr(),
    child: RemoteDataWrapper(
      isLoading: _isLoading,
      hasError: _hasError,
      onRetry: _initializePage,
      child: curiosities.isEmpty
          ? Center(
              child: Text(
                "did_you_know.empty".tr(),
                textAlign: TextAlign.center,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DidYouKnowCard(
                  monthAccent: currentButtonColor,
                  item: curiosities.last,
                  categoryColors: categoryColors,
                ),

                const SizedBox(height: 28),

                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: AppPillButton(
                      expand: true,
                      backgroundColor: currentButtonColor,
                      text: (isPremiumUser && refreshCount >= maxRefresh)
                          ? "did_you_know.button.come_back_tomorrow".tr()
                          : "did_you_know.button.discover_more".tr(),
                      onPressed: _isRefreshing
                          ? null
                          : () async {
                              setState(() => _isRefreshing = true);
                              try {
                                await _handleRefresh();
                              } finally {
                                if (mounted) {
                                  setState(() => _isRefreshing = false);
                                }
                              }
                            },
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
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

class _DidYouKnowCard extends StatelessWidget {
  final Color monthAccent;
  final Map<String, dynamic> item;
  final List<Color> categoryColors;

  const _DidYouKnowCard({
    required this.monthAccent,
    required this.item,
    required this.categoryColors,
  });

  String _normalizeKey(String raw) {
    return raw
        .toLowerCase()
        .trim()
        .replaceAll(' ', '_')
        .replaceAll('ç', 'c')
        .replaceAll('ã', 'a')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final isTablet = MediaQuery.sizeOf(context).width > 600;

    final rawCategory = item['category']?.toString() ?? 'general';
    final normalizedKey = _normalizeKey(rawCategory);
    final categoryTr = "did_you_know.categories.$normalizedKey".tr();

    final contentPt = item['content'];
    final contentEn = item['text_en'];
    final curiosityText = locale == 'pt'
        ? (contentPt ?? '')
        : (contentEn ?? contentPt ?? '');

    final idHash = (item['id']?.toString() ?? rawCategory).hashCode;
    final accent = categoryColors[idHash.abs() % categoryColors.length];

    final maxWidth = isTablet ? 520.0 : 420.0;
    final cardHeight = isTablet ? 470.0 : 420.0;
    final titleSize = isTablet ? 14.0 : 13.0;
    final textSize = isTablet ? 15.0 : 14.0;

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
                    accent.withValues(alpha: 0.22),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    padding: const EdgeInsets.fromLTRB(22, 56, 22, 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          curiosityText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.robotoSerif(
                            fontSize: textSize,
                            height: 1.6,
                            color: Colors.black.withValues(alpha: 0.82),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        categoryTr,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: titleSize,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
