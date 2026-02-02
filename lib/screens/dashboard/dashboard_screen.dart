import 'dart:convert';
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
import 'package:myyearmystory/widgets/monthly/calender/calendar_page.dart';


import 'package:myyearmystory/widgets/shared/app_bottom_menu.dart';
import 'package:myyearmystory/screens/menus/app_drawer.dart';


import 'package:myyearmystory/screens/splash/fade_page_transition.dart';
import 'package:myyearmystory/screens/notifications/daily_popup.dart';
import 'package:myyearmystory/services/daily_quote_service.dart';
import 'package:myyearmystory/utils/month_colors.dart';
import 'package:myyearmystory/screens/quiz/standalone.dart';

import 'package:myyearmystory/services/app_session.dart';
import 'package:myyearmystory/utils/app_theme.dart';
import 'package:myyearmystory/widgets/monthly/curiosity_fallback.dart';


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
  // ==============================
  // DEPENDÊNCIAS / SERVIÇOS
  // ==============================
  final supabase = Supabase.instance.client;
  final quoteService = DailyQuoteService();

  // ==============================
  // ESTADO / DADOS
  // ==============================
  String userName = "";
  String? dailyInspiration;

  String? curiosityQuestion;
  String? curiosityAnswer;
  String? curiosityDate;

  int metasConcluidas = 0;
  int gratidaoCount = 0;
  int diarioCount = 0;

  late int selectedMonth;
  late int selectedYear;

  bool isLoading = true;
  Locale? _lastLocale; // (warning apenas, não quebra)

  // ==============================
  // TEMA
  // ==============================
  

  final List<Color> themeOptions = const [
    Color(0xFFe04cb7),
    Color.fromARGB(255, 234, 185, 215),
    Color.fromARGB(255, 232, 103, 157),
    Color(0xFF74A192),
    Color(0xFFa0378c),
    Color(0xFFBEB6F2),
  ];

  // ==============================
  // INIT
  // ==============================
  @override
void initState() {
  super.initState();

  selectedMonth = widget.month;
  selectedYear = widget.year;

  _loadUserName();
  _syncUserLanguage();
  WidgetsBinding.instance.addPostFrameCallback((_) {
  _loadDashboardData();
});

 //coloco o blooco aqui?

  WidgetsBinding.instance.addPostFrameCallback((_) {
    loadDailyQuote();
  });

  Future.delayed(const Duration(seconds: 2), () {
    if (mounted) checkAndShowDailyAlert();
  });
}

@override
void didChangeDependencies() {
  super.didChangeDependencies();

  final locale = context.locale;

  if (_lastLocale != locale) {
    _lastLocale = locale;
    loadDailyQuote();
  }
}


 // ==============================
  //              BUILD
  // ==============================
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

     appBar: PreferredSize(
  preferredSize: const Size.fromHeight(kToolbarHeight),
  child: ValueListenableBuilder<Color>(
    valueListenable: appThemeColor,
    builder: (_, color, __) {
      return AppBar(
        backgroundColor: color,
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
      );
    },
  ),
),
     bottomNavigationBar: ValueListenableBuilder<Color>(
  valueListenable: appThemeColor,
  builder: (_, color, __) {
    return AppBottomMenu(
      currentIndex: 0,
      themeColor: color,
    );
  },
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
                  dataFormatada,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 32),

                // 🎨 CORES DO TEMA
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
                            appThemeColor.value = color;
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
  color: appThemeColor.value == color
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                              ? getMonthColor(index + 1)
                              : const Color.fromARGB(255, 255, 253, 254),
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
                              color: isActive ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // 🔎 BUSCAR DATA
                _buildDateSearch(context),

                const SizedBox(height: 36),

                // 🌸 ETIQUETA SEU MÊS
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

                // ⭐ CARDS
                _buildCards(context),

                const SizedBox(height: 48),

                // 🍀 CURIOSIDADE SOBRE VOCÊ
                _buildCuriosityBlock(),

                const SizedBox(height: 30),

                // 🌟 FRASE DO DIA
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
    );
  }


  // ==============================
  // ATUALIZAÇÃO DE WIDGET
  // ==============================
  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadUserName();
  }

  // ==============================
  // FORMATAÇÃO DO MÊS (ex: Mar 2024)
  // ==============================
  String _formatarMesAno(String mes, String ano) {
    final m = int.tryParse(mes) ?? 1;

    final nomesMes = [
      "",
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];

    return "${nomesMes[m]} $ano";
  }
  // ================= ALERTA DIÁRIO =================
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

      final eventDate = DateTime(event['year'], event['month'], event['day']);
      final triggerDate = eventDate.subtract(Duration(days: daysBefore));

      if (type == "none" &&
          now.year == triggerDate.year &&
          now.month == triggerDate.month &&
          now.day == triggerDate.day) {
        shouldShow = true;
      }

      if (type == "daily") shouldShow = true;

      if (type == "weekly") {
        final repeatDays = List<String>.from(event['repeat_days'] ?? []);
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

 
  // ============================
//       NOME DO USUÁRIO
// ============================
Future<void> _loadUserName() async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  // 🔸 Se não estiver logada -> Guest
  if (user == null) {
    if (!mounted) return;
    setState(() {
      userName = tr("dashboard.guest_user");
    });
    return;
  }

  try {
    final profile = await supabase
        .from("profiles")
        .select("full_name")
        .eq("id", user.id)
        .single();

    if (!mounted) return;

    final fullName = profile["full_name"];

    final firstName =
        (fullName != null && fullName.toString().trim().isNotEmpty)
            ? fullName.split(" ").first
            : tr("dashboard.guest_user");

    setState(() {
      userName = firstName;
    });
  } catch (e) {
    if (!mounted) return;
    setState(() {
      userName = tr("dashboard.guest_user");
    });
  }
}




  // ==============================
  //     FRASE DO DIA
  // ==============================
  Future<void> loadDailyQuote() async {
  // 🟡 Convidado: não tenta buscar no serviço
  if (AppSession.isGuest) {
    setState(() {
      dailyInspiration = tr("dashboard.daily_inspiration_guest");
    });
    return;
  }

  try {
    final lang = context.locale.languageCode;
    final quote = await quoteService.getRandomQuote(lang);

    if (!mounted) return;

    final text = quote?["text"]?.toString().trim();

    setState(() {
      dailyInspiration =
          (text != null && text.isNotEmpty)
              ? text
              : tr("dashboard.daily_inspiration");
    });
  } catch (_) {
    if (!mounted) return;

    setState(() {
      dailyInspiration = tr("dashboard.daily_inspiration");
    });
  }
}


  // ==============================
  //     SINCRONIZAR IDIOMA
  // ==============================
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



// ==============================
//  Função de normalização da curiosidade
// ==============================


  Map<String, dynamic>? _normalizeCuriosity(dynamic raw) {
  if (raw == null) return null;

  // Caso 1: já veio como Map
  if (raw is Map) {
    return Map<String, dynamic>.from(raw);
  }

  // Caso 2: veio como String (json serializado)
  if (raw is String) {


    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return null;
    }
  }

  // Qualquer outro formato inesperado
  return null;
}

  // ==============================
  //     CARREGAR DADOS DO DASHBOARD
  // ==============================

  Future<void> _loadDashboardData() async {
  if (!mounted) return;

  final lang = Localizations.localeOf(context).languageCode;

  setState(() => isLoading = true);

  final user = supabase.auth.currentUser;
  if (user == null) {
    if (!mounted) return;
    setState(() => isLoading = false);
    return;
  }

  try {
    // ==============================
    // METAS
    // ==============================
    final metas = await supabase
        .from("metas")
        .select()
        .eq("user_id", user.id)
        .eq("mes", selectedMonth)
        .eq("ano", selectedYear)
        .eq("concluida", true);

    metasConcluidas = metas.length;

    // ==============================
    // ENTRIES DO MÊS (resposta do usuário)
    // ==============================
    final entryRow = await supabase
        .from("entries")
        .select("curiosities, month, year")
        .eq("user_id", user.id)
        .eq("month", selectedMonth)
        .eq("year", selectedYear)
        .maybeSingle();

    // ==============================
    // CURIOSITIES_ENTRIES (perguntas do mês)
    // ==============================
    final curiositiesSource = await supabase
        .from("curiosities_entries")
        .select("questions, questions_en")
        .eq("month", selectedMonth)
        .eq("year", selectedYear)
        .maybeSingle();

    if (!mounted) return;

   // ==============================
// CURIOSIDADES (PERGUNTA + RESPOSTA)
// ==============================

// perguntas do mês vindas do banco
final List questionsFromDb =
    lang == 'en'
        ? (curiositiesSource?['questions_en'] ?? [])
        : (curiositiesSource?['questions'] ?? []);

// fallback por mês
final List<String> fallbackQuestions =
    lang == 'en'
        ? (curiosityFallbackQuestionsEn[selectedMonth] ?? [])
        : (curiosityFallbackQuestionsPt[selectedMonth] ?? []);

// lista final de perguntas
final List<String> questionsList =
    questionsFromDb.isNotEmpty
        ? List<String>.from(questionsFromDb)
        : fallbackQuestions;


// respostas do usuário (jsonb em entries.curiosities)
final curiosityJson = entryRow?['curiosities'];

String? answer;
int? answeredIndex;

Map<String, dynamic>? selected;

if (curiosityJson is List && curiosityJson.isNotEmpty) {
  for (final item in curiosityJson) {
    if (item is Map && item['index'] == 0) {
      selected = Map<String, dynamic>.from(item);
      break;
    }
  }
}

if (selected != null) {
  answer = selected['answer']?.toString().trim();
  answeredIndex = selected['index'];
}


if (!mounted) return;


debugPrint('ANSWER RAW: $answer');
debugPrint('INDEX RAW: $answeredIndex');
debugPrint('QUESTIONS LIST SIZE: ${questionsList.length}');
debugPrint('QUESTIONS LIST: $questionsList');


setState(() {
  // 🟣 PERGUNTA
  if (answeredIndex != null &&
      answeredIndex >= 0 &&
      answeredIndex < questionsList.length) {
    curiosityQuestion = questionsList[answeredIndex];
  } else {
    curiosityQuestion = null;
  }

  // 🟣 RESPOSTA
  if (answer != null && answer.isNotEmpty) {
    curiosityAnswer = answer;

    curiosityDate = tr(
      "dashboard.answered_in",
      namedArgs: {
        "date": _formatarMesAno(
          entryRow!['month'].toString(),
          entryRow['year'].toString(),
        ),
      },
    );
  } else {
    curiosityAnswer = null;
    curiosityDate = null;
  }
});


  } catch (e) {
    // se quiser, depois colocamos log aqui
    // Error loading dashboard data
  }

  if (!mounted) return;
  setState(() => isLoading = false);
}

 
  // =====================================================
  // 🔸 BLOCO DE CURIOSIDADE
  // =====================================================
 Widget _buildCuriosityBlock() {
  final screenWidth = MediaQuery.of(context).size.width;
  final isTablet = screenWidth > 600;
  final double cardWidth = isTablet ? screenWidth * 0.85 : 300;

  return Align(
    alignment: Alignment.center,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: cardWidth),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: const Color(0xFFF3D6E5),
            borderRadius: BorderRadius.circular(40),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.favorite,
                size: 20,
                color: Color.fromARGB(221, 217, 60, 126),
              ),

              const SizedBox(height: 8),

              // 🟣 TÍTULO FIXO DO CARD
              Text(
                tr("dashboard.curiosity_title"),
                style: GoogleFonts.courierPrime(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),
              const Divider(color: Colors.black26, thickness: 1),
              const SizedBox(height: 8),

              // ❓ PERGUNTA (se existir)
              if (curiosityQuestion != null) ...[
                Text(
                  curiosityQuestion!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.courierPrime(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // 📝 RESPOSTA ou CTA
              if (curiosityAnswer != null && curiosityAnswer!.isNotEmpty) ...[
                Text(
                  curiosityAnswer!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.courierPrime(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 8),

                if (curiosityDate != null)
                  Text(
                    curiosityDate!,
                    style: GoogleFonts.courierPrime(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
              ] else ...[
                Text(
                  tr("dashboard.curiosity_cta"),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.courierPrime(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

 // ==============================
  //      LABEL DO CALENDÁRIO
  // ==============================
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
 
// =====================================================
  // 🔸 FUNÇÃO DE CRIAÇÃO DE CARD
  // =====================================================
Widget _buildCard({
  required BuildContext context,
  required String title,
  required IconData icon,
  required Color color,
  Color? iconColor,
  Color? textColor,
  required String route,
}) {
  // 🔹 Responsividade
  final double iconSize =
      (MediaQuery.of(context).size.width * 0.06).clamp(28, 42);

  final double textSize =
      (MediaQuery.of(context).size.width * 0.028).clamp(14, 16);

  return GestureDetector(
    onTap: () {
      Widget target;

      switch (route) {
        case '/monthly_goals':
          target = MonthlyGoalsWidget(
            month: selectedMonth,
            year: selectedYear,
          );
          break;

        case '/mood_summary':
          target = MoodScreen(
            month: selectedMonth,
            year: selectedYear,
          );
          break;

        case '/diary_entries':
          target = DiaryScreen(date: DateTime.now());
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
          Icon(
            icon,
            size: iconSize,
            color: iconColor ?? Colors.white,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.w600,
              color: textColor ?? Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}



  // =====================================================
  // 🔸 CARDS DO DASHBOARD
  // =====================================================
  Widget _buildCards(BuildContext context) {
  return GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 3,
    crossAxisSpacing: 12,
    mainAxisSpacing: 14,
    children: [
      _buildCard(
        context: context,
        title: tr('dashboard.goals'),
        icon: PhosphorIconsRegular.target,
        color: const Color(0xFFe04cb7),
        route: '/monthly_goals',
      ),
      _buildCard(
        context: context,
        title: tr('dashboard.mood'),
        icon: PhosphorIconsRegular.smiley,
        color: const Color(0xFFfbcce9),
        iconColor: const Color(0xFF943482),
        textColor: const Color(0xFF943482),
        route: '/mood_summary',
      ),
      _buildCard(
        context: context,
        title: tr('dashboard.diary'),
        icon: PhosphorIconsRegular.notebook,
        color: const Color(0xFFa0378c),
        route: '/diary_entries',
      ),
      _buildCard(
        context: context,
        title: tr('dashboard.did_you_know'),
        icon: PhosphorIconsRegular.lightbulb,
        color: const Color(0xFFdbaf35),
        route: '/did_you_know',
      ),
      _buildCard(
        context: context,
        title: tr('dashboard.dailyluckpage'),
        icon: PhosphorIconsRegular.clover,
        color: const Color(0xFF74a192),
        route: '/daily_luck',
      ),
      _buildCard(
        context: context,
        title: tr('dashboard.calendar_page'),
        icon: PhosphorIconsRegular.calendarDots,
        color: const Color(0xFFbeb6f2),
        route: '/calendar_page',
      ),
      _buildCard(
        context: context,
        title: tr('dashboard.monthly_quiz'),
        icon: PhosphorIconsRegular.star,
        color: const Color(0xFFdd97b7),
        route: '/interactive_quiz',
      ),
      _buildCard(
        context: context,
        title: tr('dashboard.gratitude'),
        icon: PhosphorIconsRegular.heart,
        color: const Color(0xFFe2377d),
        route: '/gratitude',
      ),
      _buildCard(
        context: context,
        title: tr('dashboard.about_me'),
        icon: PhosphorIconsRegular.userCircle,
        color: const Color(0xFFcf8ee8),
        route: '/curiosities',
      ),
    ],
  );
}



  // =====================================================
  // 🔎 BUSCA DE DATAS
  // =====================================================
  Widget _buildDateSearch(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            int selectedYear = DateTime.now().year.clamp(2025, 2100);

            return StatefulBuilder(
              builder: (context, setStateSB) {
                return Dialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ícone topo
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Color(0xFFE04CB7),
                            size: 22,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          tr('dashboard.select_date'),
                          style: GoogleFonts.courierPrime(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ano com setas
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: selectedYear > 2025
                                  ? () => setStateSB(() => selectedYear--)
                                  : null,
                              icon: Icon(
                                Icons.chevron_left,
                                color: selectedYear > 2025
                                    ? Colors.black87
                                    : Colors.black26,
                              ),
                            ),
                            Text(
                              "$selectedYear",
                              style: GoogleFonts.courierPrime(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              onPressed: () => setStateSB(() => selectedYear++),
                              icon: const Icon(Icons.chevron_right,
                                  color: Colors.black87),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // GRID DE MESES PARA NAVEGAR
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 12,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.6,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                          ),
                          itemBuilder: (_, index) {
                            final shortNames = [
                              "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                              "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
                            ];

                            return GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
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
                                  color: const Color(0xFFF8DFF0),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFE04CB7),
                                    width: 1.3,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    shortNames[index],
                                    style: GoogleFonts.courierPrime(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFB73C78),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            tr("general.cancel"),
                            style: GoogleFonts.courierPrime(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
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
              tr('dashboard.search_previous_dates'),
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

  // =====================================================
  // 🔸 NOMES DOS MESES
  // =====================================================
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
