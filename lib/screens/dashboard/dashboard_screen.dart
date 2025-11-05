import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;

// Telas principais
import 'package:my_year_my_story/screens/diary/diary_screen.dart';
import 'package:my_year_my_story/screens/mood/mood_screen.dart';
import 'package:my_year_my_story/widgets/monthly/monthly_goals_widget.dart';
import 'package:my_year_my_story/widgets/monthly/gratitude_widget.dart';
import 'package:my_year_my_story/screens/quiz/interactive_quiz_screen.dart';
import 'package:my_year_my_story/screens/monthly/current_month_screen.dart';
import '../../widgets/monthly/curiosities_widget.dart';

// Menu inferior
import 'package:my_year_my_story/widgets/shared/app_bottom_menu.dart';
// Menu superior
import '../../widgets/shared/custom_drawer.dart';
// Transição personalizada
import 'package:my_year_my_story/screens/splash/fade_page_transition.dart';

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
  String? dailyQuote;

  late int selectedMonth;
  late int selectedYear;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    selectedMonth = widget.month;
    selectedYear = widget.year;

    _syncUserLanguage();
    _loadDashboardData();
  }

  // 🔄 Sincroniza o idioma do app com o Supabase
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
        dailyQuote = 'Cada dia é uma nova página na sua história ✨';
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
        humorMaisComum =
            moods.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      }

      final startOfMonth = DateTime(selectedYear, selectedMonth, 1);
      final endOfMonth = DateTime(selectedYear, selectedMonth + 1, 0);
      final diaryResponse = await supabase
          .from('diary_entries')
          .select()
          .eq('user_id', user.id)
          .gte('entry_date', startOfMonth.toIso8601String())
          .lte('entry_date', endOfMonth.toIso8601String());

      diarioCount = diaryResponse.length;
      await _loadDailyQuote();
    } catch (e) {
      debugPrint('Erro ao carregar dashboard: $e');
    }

    setState(() => isLoading = false);
  }

  Future<void> _loadDailyQuote() async {
    try {
      final response = await supabase.from('daily_quotes').select('text').limit(1);
      if (response.isNotEmpty) {
        dailyQuote = (response..shuffle()).first['text'];
      }
    } catch (e) {
      debugPrint('Erro ao carregar frase do dia: $e');
    }
  }

  // 🔠 Mês abreviado traduzido
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

  // 🔠 Mês completo traduzido
  String getNomeMesCompleto(int mes) {
    final meses = [
      'dashboard.month.january'.tr(),
      'dashboard.month.february'.tr(),
      'dashboard.month.march'.tr(),
      'dashboard.month.april'.tr(),
      'dashboard.month.may'.tr(),
      'dashboard.month.june'.tr(),
      'dashboard.month.july'.tr(),
      'dashboard.month.august'.tr(),
      'dashboard.month.september'.tr(),
      'dashboard.month.october'.tr(),
      'dashboard.month.november'.tr(),
      'dashboard.month.december'.tr(),
    ];
    return meses[mes - 1];
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final userName = user?.userMetadata?['name'] ?? 'Guest';
    final now = DateTime.now();
    final diaSemana = DateFormat.EEEE(context.locale.languageCode).format(now);
    final dataCompleta =
        '$diaSemana, ${now.day} de ${getNomeMesCompleto(now.month)} de ${now.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      drawer: const CustomDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFFe2377d),
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
                Text(
                  tr('dashboard.hello_user', args: [userName]),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF679bd3),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dataCompleta,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 32),

                // 📅 Seleção de mês
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
                              month: index + 1,
                              year: selectedYear,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: ativo ? const Color(0xFFdbaf35) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
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

                Text(
                  'dashboard.track_your_activities'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF665C8E),
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
                    _buildCard(
                      title: tr('dashboard.goals'),
                      icon: PhosphorIconsRegular.target,
                      color: const Color(0xFF679BD3),
                      route: '/monthly_goals',
                    ),
                    _buildCard(
                      title: tr('dashboard.mood'),
                      icon: PhosphorIconsRegular.smiley,
                      color: const Color(0xFFF6B8C6),
                      route: '/mood_summary',
                    ),
                    _buildCard(
                      title: tr('dashboard.diary'),
                      icon: PhosphorIconsRegular.notebook,
                      color: const Color(0xFFe2377d),
                      route: '/diary_entries',
                    ),
                    _buildCard(
                      title: tr('dashboard.monthly_quiz'),
                      icon: PhosphorIconsRegular.star,
                      color: const Color(0xFFDBAF35),
                      route: '/interactive_quiz',
                    ),
                    _buildCard(
                      title: tr('dashboard.gratitude'),
                      icon: PhosphorIconsRegular.heart,
                      color: const Color(0xFFCF8EE8),
                      route: '/gratitude',
                    ),
                    _buildCard(
                      title: tr('dashboard.about_me'),
                      icon: PhosphorIconsRegular.flower,
                      color: const Color(0xFFddbfef),
                      route: '/curiosities',
                    ),
                  ],
                ),

                const SizedBox(height: 48),
                if (dailyQuote != null)
                  Text(
                    '"$dailyQuote"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF665C8E),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  )
                else
                  Text(
                    'dashboard.daily_inspiration'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black45,
                      fontSize: 13,
                    ),
                  ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomMenu(currentIndex: 0),
    );
  }

  // 🔎 Pesquisa de data — bloqueando anos anteriores ao atual
  Widget _buildDateSearch(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final currentYear = DateTime.now().year;
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(currentYear), // bloqueia anos anteriores
          lastDate: DateTime(currentYear + 2),
          locale: context.locale,
          helpText: tr('dashboard.select_date'),
        );

        if (picked != null) {
          Navigator.of(context).push(
            fadePageTransition(
              CurrentMonthScreen(month: picked.month, year: picked.year),
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

  // 💠 Cards
  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color color,
    required String route,
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
            target = const DiaryScreen();
            break;
          case '/interactive_quiz':
            target = InteractiveQuizScreen(
                month: selectedMonth, year: selectedYear);
            break;
          case '/gratitude':
            target = GratitudeWidget(month: selectedMonth, year: selectedYear);
            break;
          case '/curiosities':
            target = CuriositiesWidget(month: selectedMonth, year: selectedYear);
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
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.black54),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
