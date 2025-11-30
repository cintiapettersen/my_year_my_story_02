import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;

import 'package:myyearmystory/screens/diary/diary_screen.dart';
import 'package:myyearmystory/screens/mood/mood_screen.dart';
import 'package:myyearmystory/widgets/monthly/monthly_goals_widget.dart';
import 'package:myyearmystory/widgets/monthly/gratitude_widget.dart';

import 'package:myyearmystory/screens/monthly/current_month_screen.dart';
import '../../widgets/monthly/curiosities_widget.dart';
import 'package:myyearmystory/widgets/monthly/did_you_know_widget.dart';
import 'package:myyearmystory/widgets/monthly/dailyluckpage.dart';
import 'package:myyearmystory/widgets/monthly/calendar_page.dart';

import 'package:myyearmystory/widgets/shared/app_bottom_menu.dart';
import 'package:myyearmystory/screens/menus/app_drawer.dart';


import 'package:myyearmystory/screens/splash/fade_page_transition.dart';
import 'package:myyearmystory/screens/notifications/daily_popup.dart';
import 'package:myyearmystory/services/daily_quote_service.dart';
import 'package:myyearmystory/utils/month_colors.dart';
import 'package:myyearmystory/screens/quiz/standalone.dart';





class DashboardScreen extends StatefulWidget {
  final int month;
  final int year;

  const DashboardScreen({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final supabase = Supabase.instance.client;

  int metasConcluidas = 0;
  int gratidaoCount = 0;
  int diarioCount = 0;
  String? humorMaisComum;
  String? quizResultado;
  String? curiosidadeAleatoria;

  Map<String, dynamic>? dailyQuote;
  final quoteService = DailyQuoteService();

  late int selectedMonth;
  late int selectedYear;
  bool isLoading = true;

  // 🎨 Tema dinâmico selecionado
  Color currentThemeColor = const Color(0xFFE04CB7);

  // 🎨 Paleta de 5 cores (tons do app — opção 3)
  final List<Color> themeOptions = const [
    Color(0xFFe04cb7), // Janeiro
    Color(0xFF976FD0), // Abril
    Color(0xFFe2377d), // Novembro
    Color(0xFF627fdd), // Dezembro
    Color(0xFFBEB6F2), // Junho
  ];

  @override
  void initState() {
    super.initState();
    selectedMonth = widget.month;
    selectedYear = widget.year;

    _syncUserLanguage();
    _loadDashboardData();
    loadDailyQuote();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _checkAndShowDailyAlert();
      }
    });
  }

  Future<void> loadDailyQuote() async {
    try {
      final quote = await quoteService.getRandomQuote();
      setState(() {
        dailyQuote = quote;
      });
    } catch (e) {
      debugPrint('Erro ao carregar frase do dia: $e');
    }
  }

  Future<void> _checkAndShowDailyAlert() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final weekday = DateFormat('EEE').format(now);

    final events = await supabase
        .from('calendar_events')
        .select()
        .eq('user_id', user.id)
        .eq('remind', true);

    if (events.isEmpty) return;

    for (final event in events) {
      final type = event['repeat_type'];
      final daysBefore = event['days_before'] ?? 0;
      final seenToday = event['seen_today'] ?? false;

      if (seenToday) continue;

      bool shouldShow = false;

      final eventDate = DateTime(
        event['year'],
        event['month'],
        event['day'],
      );

      final triggerDate =
          eventDate.subtract(Duration(days: daysBefore));

      if (type == "none") {
        if (now.year == triggerDate.year &&
            now.month == triggerDate.month &&
            now.day == triggerDate.day) {
          shouldShow = true;
        }
      }

      if (type == "daily") shouldShow = true;

      if (type == "weekly") {
        final repeatDays =
            List<String>.from(event['repeat_days'] ?? []);
        if (repeatDays.contains(weekday)) {
          shouldShow = true;
        }
      }

      if (type == "monthly" && now.day == event['day']) {
        shouldShow = true;
      }

      if (type == "yearly" &&
          now.day == event['day'] &&
          now.month == event['month']) {
        shouldShow = true;
      }

      if (shouldShow) {
        DailyPopup.show(context, event);
        break;
      }
    }
  }

  Future<void> _syncUserLanguage() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final currentLang = ui.PlatformDispatcher.instance.locale.languageCode;

    try {
      final profile = await supabase
          .from('profiles')
          .select('language')
          .eq('id', user.id)
          .maybeSingle();

      final dbLang = profile?['language'];

      if (dbLang != currentLang) {
        await supabase
            .from('profiles')
            .update({'language': currentLang})
            .eq('id', user.id);
      }
    } catch (e) {
      debugPrint('Erro ao sincronizar idioma no Dashboard: $e');
    }
  }
  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    final user = supabase.auth.currentUser;

    try {
      if (user == null) {
        metasConcluidas = 0;
        gratidaoCount = 0;
        diarioCount = 0;
        humorMaisComum = '🙂';
        quizResultado = null;
        curiosidadeAleatoria = null;
        if (!mounted) return;
        setState(() => isLoading = false);
        return;
      }

      final metasResponse = await supabase
          .from('metas')
          .select()
          .eq('user_id', user.id)
          .eq('mes', selectedMonth)
          .eq('ano', selectedYear)
          .eq('concluida', true);

      metasConcluidas = metasResponse.length;

      final entriesResponse = await supabase
          .from('entries')
          .select('gratitude_entries, curiosities, quiz_data')
          .eq('user_id', user.id)
          .eq('month', selectedMonth)
          .eq('year', selectedYear)
          .maybeSingle();

      if (entriesResponse != null) {
        gratidaoCount =
            (entriesResponse['gratitude_entries'] as List?)?.length ?? 0;

        final curiosities = entriesResponse['curiosities'];
        if (curiosities != null && curiosities is List && curiosities.isNotEmpty) {
          curiosidadeAleatoria = (curiosities..shuffle()).first;
        }

        quizResultado = entriesResponse['quiz_data']?['result'];
      }

      final moodResponse = await supabase
          .from('mood_entries')
          .select('mood, entry_date')
          .eq('user_id', user.id);

      if (moodResponse.isNotEmpty) {
        final moods = <String, int>{};
        for (final m in moodResponse) {
          final mood = m['mood'] ?? '';
          moods[mood] = (moods[mood] ?? 0) + 1;
        }
        humorMaisComum = moods.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      }

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint('Erro ao carregar dashboard: $e');
      setState(() => isLoading = false);
    }
  }

  // 🔠 Mês abreviado
  String getNomeMesAbreviado(int mes) {
    final mesesAbrev = [
      'dashboard.month_short.jan'.tr(),
      'dashboard.month_short.feb'.tr(),
      'dashboard.month_short.mar'.tr(),
      'dashboard.month_short.apr'.tr(),
      'dashboard.month_short.may'.tr(),
      'dashboard.month_short.jun'.tr(),
      'dashboard.month_short.jul'.tr(),
      'dashboard.month_short.aug'.tr(),
      'dashboard.month_short.sep'.tr(),
      'dashboard.month_short.oct'.tr(),
      'dashboard.month_short.nov'.tr(),
      'dashboard.month_short.dec'.tr(),
    ];
    return mesesAbrev[mes - 1];
  }

  // 🔠 Mês completo
  String getNomeMesCompleto(int mes) {
    final meses = [
      'month.january'.tr(),
      'month.february'.tr(),
      'month.march'.tr(),
      'month.april'.tr(),
      'month.may'.tr(),
      'month.june'.tr(),
      'month.july'.tr(),
      'month.august'.tr(),
      'month.september'.tr(),
      'month.october'.tr(),
      'month.november'.tr(),
      'month.december'.tr(),
    ];
    return meses[mes - 1];
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final userName = user?.userMetadata?['name'] ?? tr('dashboard.guest_user');

    final now = DateTime.now();
    final diaSemana = DateFormat.EEEE(context.locale.languageCode).format(now);
    final dataCompleta =
        '$diaSemana, ${now.day} de ${getNomeMesCompleto(now.month)} de ${now.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),

      // 🟣 Drawer com cor dinâmica
      drawer: const AppDrawer(),
      // 🟣 AppBar com cor dinâmica
      appBar: AppBar(
        backgroundColor: currentThemeColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'My Year, My Story',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),

      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                
                // 👋 Saudação
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5E1F7),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Text(
                    tr('dashboard.hello_user', namedArgs: {'user': userName}),
                    style: GoogleFonts.courierPrime(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                      letterSpacing: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 8),

              
                Text(
                  dataCompleta,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 32),

               // 🎨 Seletor de cores
                Column(
                  children: [
                    Text(
                    tr('dashboard.choose_your_color_today'),
                      style: TextStyle(
                        fontSize: 13,
                        color: Color.fromARGB(231, 0, 0, 0),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: themeOptions.map((color) {
                        return GestureDetector(
                          onTap: () {
                            setState(() => currentThemeColor = color);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: currentThemeColor == color
                                    ? const Color.fromARGB(255, 221, 219, 221)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),



                // 📅 Meses
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 12,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.3,
                  ),
                  itemBuilder: (context, index) {
                    final ativo = index + 1 == selectedMonth;

                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          fadePageTransition(
                            CurrentMonthScreen(
                                month: index + 1, year: selectedYear),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: ativo ? getMonthColor(index + 1) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            getNomeMesAbreviado(index + 1),
                            style: TextStyle(
                              color: ativo ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                _buildDateSearch(context),
                const SizedBox(height: 36),

                // 🏷️ Etiqueta "Seu espaço do mês"
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEDAF0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tr('dashboard.your_month_space'),
                    style: GoogleFonts.courierPrime(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                isLoading
                    ? const CircularProgressIndicator()
                    : GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 14,
                       
                        children: [
                            
  // CARDS
  _buildCard(
    title: tr('dashboard.goals'),
    icon: PhosphorIconsRegular.target,
    color: const Color(0xFFe04cb7),
    route: '/monthly_goals',
  ),
  _buildCard(
    title: tr('dashboard.mood'),
    icon: PhosphorIconsRegular.smiley,
    color: const Color(0xFFfbcce9),
    iconColor: const Color(0xFF943482),
    textColor: const Color(0xFF943482),
    route: '/mood_summary',
  ),
  _buildCard(
    title: tr('dashboard.diary'),
    icon: PhosphorIconsRegular.notebook,
    color: const Color(0xFFa0378c),
    route: '/diary_entries',
  ),

  // 2ª linha (agora com itens da última fileira!)
  _buildCard(
    title: tr('dashboard.did_you_know.'),
    icon: PhosphorIconsRegular.lightbulb,
    color: const Color(0xFFdbaf35),
    route: '/did_you_know',
  ),
  _buildCard(
    title: tr('dashboard.dailyluckpage'),
    icon: PhosphorIconsRegular.clover,
    color: const Color(0xFF74a192),
    route: '/daily_luck',
  ),
  _buildCard(
    title: tr('dashboard.calendar_page'),
    icon: PhosphorIconsRegular.calendarDots,
    color: const Color(0xFF627fdd),
    route: '/calendar_page',
  ),

  // 3ª linha (agora com os da antiga fileira do meio!)
  _buildCard(
  title: tr('dashboard.monthly_quiz'),
  icon: PhosphorIconsRegular.star,
  color: const Color(0xFFdd97b7),
  route: '/interactive_quiz',
),
  _buildCard(
    title: tr('dashboard.gratitude'),
    icon: PhosphorIconsRegular.heart,
    color: const Color(0xFFe2377d),
    route: '/gratitude',
  ),
  _buildCard(
    title: tr('dashboard.about_me'),
    icon: PhosphorIconsRegular.userCircle,
    color: const Color(0xFFcf8ee8),
    route: '/curiosities',
  ),
],

                      ),

                const SizedBox(height: 48),

                // 🍀 FRASE DO DIA
                if (dailyQuote != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      '"${dailyQuote!['text']}"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF665C8E),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'dashboard.daily_inspiration'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),

      // 🔻 Menu inferior
      bottomNavigationBar: AppBottomMenu(
  currentIndex: 0,
  themeColor: currentThemeColor, // 🌈 novo
  ),
    );
  }

  // 🔎 Busca de datas
  Widget _buildDateSearch(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final currentYear = DateTime.now().year;

        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(currentYear),
          lastDate: DateTime(currentYear + 2),
          locale: context.locale,
          helpText: tr('dashboard.select_date'),
        );

        if (picked != null) {
          Navigator.of(context).push(
            fadePageTransition(
              CurrentMonthScreen(
                month: picked.month,
                year: picked.year,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black26),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, color: Colors.black54, size: 20),
            const SizedBox(width: 8),
            Text(
              'dashboard.search_previous_dates'.tr(),
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 💠 Cards personalizados
  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color color,
    required String route,
    Color iconColor = Colors.white,
    Color textColor = Colors.white,
  }) {
    return GestureDetector(
         onTap: () {
        Widget target;

        switch (route) {
          case '/monthly_goals':
            target = MonthlyGoalsWidget(month: selectedMonth, year: selectedYear);
            break;
          case '/mood_summary':
            target = MoodScreen(month: selectedMonth, year: selectedYear);
            break;
          case '/diary_entries':
            target = DiaryScreen();
            break;
          case '/interactive_quiz':
            target = InteractiveQuizStandalone(
            month: selectedMonth,
            year: selectedYear,
            );
            break;
          case '/gratitude':
            target = GratitudeWidget(month: selectedMonth, year: selectedYear);
            break;
          case '/curiosities':
            target = CuriositiesWidget(month: selectedMonth, year: selectedYear);
            break;
          case '/did_you_know':
            target = DidYouKnowWidget(month: selectedMonth, year: selectedYear);
            break;
          case '/daily_luck':
            target = const DailyLuckPage();
            break;
          case '/calendar_page':
            target = CalendarPage(month: selectedMonth, year: selectedYear);
            break;
          default:
            return;
        }

        Navigator.of(context).push(fadePageTransition(target));
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: iconColor),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
