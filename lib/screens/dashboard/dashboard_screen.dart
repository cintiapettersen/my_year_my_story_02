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

  String userName = "";
  String? dailyInspiration;

  int metasConcluidas = 0;
  int gratidaoCount = 0;
  int diarioCount = 0;

  String? humorMaisComum;
  String? quizResultado;
  String? curiosidadeAleatoria;

  final quoteService = DailyQuoteService();

  late int selectedMonth;
  late int selectedYear;
  bool isLoading = true;

  // 🎨 TEMA DINÂMICO
  Color currentThemeColor = const Color(0xFFE04CB7);

  final List<Color> themeOptions = const [
    Color(0xFFe04cb7),
    Color(0xFFfbcce9),
    Color(0xFFe2377d),
    Color(0xFFa0378c),
    Color(0xFFBEB6F2),
  ];

  @override
void initState() {
  super.initState();

  selectedMonth = widget.month;
  selectedYear = widget.year;

  _loadUserName();
  _syncUserLanguage();
  _loadDashboardData();

  // 👉 Adia para depois que o contexto estiver pronto
  WidgetsBinding.instance.addPostFrameCallback((_) {
    loadDailyQuote();
  });

  Future.delayed(const Duration(seconds: 2), () {
    if (mounted) checkAndShowDailyAlert();
  });
}

  // ================================
  // PUXAR NOME DO SUPABASE
  // ================================
  Future<void> _loadUserName() async {
  final user = supabase.auth.currentUser;
  if (user == null) return;

  try {
    final profile = await supabase
        .from("profiles")
        .select("full_name")
        .eq("id", user.id)
        .single();

    setState(() {
      final fullName = profile["full_name"];
      final firstName = fullName != null && fullName.isNotEmpty
          ? fullName.split(" ").first
          : tr("dashboard.guest_user");

      userName = firstName;
    });
  } catch (e) {
    setState(() {
      userName = tr("dashboard.guest_user");
    });
  }
}


  
  // =========================================
// 🌙 FRASE DO DIA — VERSÃO CORRIGIDA COMPLETA
// =========================================
Future<void> loadDailyQuote() async {
  print("🔥 loadDailyQuote() INICIADA");

  try {
    final lang = context.locale.languageCode;
    print("🔥 Idioma detectado: $lang");

    final quote = await quoteService.getRandomQuote(lang);
    print("🔥 Retorno do quoteService: $quote");

    setState(() {
      final txt = quote?["text"]?.toString().trim();
      print("🔥 Texto extraído: $txt");

      dailyInspiration = (txt != null && txt.isNotEmpty)
          ? txt
          : tr("dashboard.daily_inspiration");

      print("🔥 dailyInspiration DEFINIDA COMO: $dailyInspiration");
    });

  } catch (e) {
    print("❌ ERRO NO loadDailyQuote(): $e");
    setState(() {
      dailyInspiration = tr("dashboard.daily_inspiration");
    });
  }
}
// =========================================
// 🔹 Calendar Subtitle Label
// =========================================
Widget _calendarLabel() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F3F3),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      tr("dashboard.navigate_months"),
      style: GoogleFonts.courierPrime(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
        letterSpacing: 0.5,
      ),
    ),
  );
}


  // ================================
  // ALERTA DO CALENDÁRIO
  // ================================
  Future<void> checkAndShowDailyAlert() async {
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

      final eventDate =
          DateTime(event['year'], event['month'], event['day']);

      final triggerDate =
          eventDate.subtract(Duration(days: daysBefore));

      if (type == "none" &&
          now.year == triggerDate.year &&
          now.month == triggerDate.month &&
          now.day == triggerDate.day) {
        shouldShow = true;
      }

      if (type == "daily") shouldShow = true;

      if (type == "weekly") {
        final repeatDays =
            List<String>.from(event['repeat_days'] ?? []);
        if (repeatDays.contains(weekday)) shouldShow = true;
      }

      if (type == "monthly" && now.day == event['day']) shouldShow = true;

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

  // ================================
  // IDIOMA → SUPABASE
  // ================================
  Future<void> _syncUserLanguage() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final lang = ui.PlatformDispatcher.instance.locale.languageCode;

    try {
      await supabase
          .from("profiles")
          .update({"language": lang})
          .eq("id", user.id);
    } catch (_) {}
  }

  // ================================
 // ================================
//  CARREGAR DADOS
// ================================
Future<void> _loadDashboardData() async {
  if (!mounted) return;

  setState(() => isLoading = true);

  final user = supabase.auth.currentUser;
  if (user == null) return;

  try {
    // METAS CONCLUÍDAS
    final metas = await supabase
        .from("metas")
        .select()
        .eq("user_id", user.id)
        .eq("mes", selectedMonth)
        .eq("ano", selectedYear)
        .eq("concluida", true);

    metasConcluidas = metas.length;

    // ENTRIES DO MÊS
    final entries = await supabase
        .from("entries")
        .select()
        .eq("user_id", user.id)
        .eq("month", selectedMonth)
        .eq("year", selectedYear)
        .maybeSingle();

    if (entries != null) {
      gratidaoCount =
          (entries["gratitude_entries"] as List?)?.length ?? 0;

      // =======================
      // 💡 CURIOSIDADE DO MÊS
      // =======================
      final curiosities = entries["curiosities"];
      final answers = entries["curiosities_answers"];

      if (curiosities != null &&
          curiosities is List &&
          answers != null &&
          answers is List &&
          curiosities.isNotEmpty &&
          answers.isNotEmpty &&
          curiosities.length == answers.length) {

        final List<Map<String, String>> combined = [];

        for (int i = 0; i < answers.length; i++) {
          combined.add({
            "answer": answers[i],
            "month": entries["month"].toString(),
            "year": entries["year"].toString(),
          });
        }

        combined.shuffle();
        final selected = combined.first;

        curiosidadeAleatoria =
            "${selected['answer']}\n(${_formatarMesAno(
              selected['month']!,
              selected['year']!,
            )})";

      } else {
        curiosidadeAleatoria = null;
      }
    }

    setState(() => isLoading = false);
  } catch (_) {
    setState(() => isLoading = false);
  }
}

/// =======================================
/// 📌 Função auxiliar para exibir "Mar 2024"
/// =======================================
String _formatarMesAno(String mes, String ano) {
  final m = int.tryParse(mes) ?? 1;
  final nomesMes = [
    "",
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  ];

  return "${nomesMes[m]} $ano";
}

  // =========================================
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diaSemana =
        DateFormat.EEEE(context.locale.languageCode).format(now);

    final dataFormatada =
        "$diaSemana, ${now.day} ${getNomeMesCompleto(now.month)} ${now.year}";

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      drawer: const AppDrawer(),

      appBar: AppBar(
        backgroundColor: currentThemeColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "My Year, My Story",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
                // 🌸 SAUDAÇÃO
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                  dataFormatada,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 32),

                // 🎨 SELETOR DE CORES VOLTOU!
                Column(
                  children: [
                    Text(
                      tr('dashboard.choose_your_color_today'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color.fromARGB(221, 0, 0, 0),
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
      ? const Color.fromARGB(255, 231, 225, 230)
      : Colors.transparent,
  width: 2,
),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),

                // 🌈 CALENDÁRIO
                _calendarLabel(),
                const SizedBox(height: 20),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 12,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemBuilder: (context, index) {
                    final isActive = index + 1 == selectedMonth;

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
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? getMonthColor(index + 1)//.withOpacity(0.65)
                              : const Color.fromARGB(255, 255, 253, 254),//troca o fundo dos meses no calendario
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isActive
                                ? getMonthColor(index + 1)
                                : const Color.fromARGB(255, 119, 118, 118),
                            width: isActive ? 2.2 : 1.4,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            getNomeMesAbreviado(index + 1),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color:
                                  isActive ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // 🌸 ETIQUETA "Seu mês"
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tr('dashboard.your_month_space'),
                    style: GoogleFonts.courierPrime(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // CARDS
                _buildCards(context),

                const SizedBox(height: 48),

                

                // 🍀 CURIOSIDADE SOBRE VOCÊ
                _buildCuriosityBlock(),

                const SizedBox(height: 30),



// 🌟 FRASE·DO·DIa
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: Text(
    (dailyInspiration == null || dailyInspiration!.trim().isEmpty)
        ? tr('dashboard.daily_inspiration')
        : dailyInspiration!,
    textAlign: TextAlign.center,
    style: const TextStyle(
      fontStyle: FontStyle.italic,
      color: Color(0xFF665C8E),
      fontSize: 14,
      height: 1.4,
    ),
  ),
),
const SizedBox(height: 20),

              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: AppBottomMenu(
        currentIndex: 0,
        themeColor: currentThemeColor,
      ),
    );
  }



  // =========================================
  // BLOCOS / COMPONENTES
  // =========================================

  Widget _buildCuriosityBlock() {
  return Align(
    alignment: Alignment.center,
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 300, // largura do card
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CuriositiesWidget(
                month: selectedMonth,
                year: selectedYear,
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 245, 211, 252),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                tr("dashboard.curiosity_title"),
                style: const TextStyle(
                  color: Color.fromARGB(255, 154, 102, 177),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                curiosidadeAleatoria ?? tr("dashboard.no_curiosity"),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.35),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}


  Widget _buildCards(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 14,
      children: [
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
    );
  }

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
            target = MonthlyGoalsWidget(
                month: selectedMonth, year: selectedYear);
            break;
          case '/mood_summary':
            target =
                MoodScreen(month: selectedMonth, year: selectedYear);
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
            target = GratitudeWidget(
              month: selectedMonth,
              year: selectedYear,
            );
            break;
          case '/curiosities':
            target = CuriositiesWidget(
              month: selectedMonth,
              year: selectedYear,
            );
            break;
          case '/did_you_know':
            target = DidYouKnowWidget(
              month: selectedMonth,
              year: selectedYear,
            );
            break;
          case '/daily_luck':
            target = const DailyLuckPage();
            break;
          case '/calendar_page':
            target = CalendarPage(
              month: selectedMonth,
              year: selectedYear,
            );
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

  // =========================
  // Nomes dos meses
  // =========================
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
}
