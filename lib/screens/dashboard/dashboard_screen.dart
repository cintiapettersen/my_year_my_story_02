import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// Telas principais
import 'package:my_year_my_story/screens/diary/diary_screen.dart';
import 'package:my_year_my_story/screens/mood/mood_screen.dart';
import 'package:my_year_my_story/widgets/monthly/monthly_goals_widget.dart';
import 'package:my_year_my_story/widgets/monthly/gratitude_widget.dart';
import 'package:my_year_my_story/screens/quiz/interactive_quiz_screen.dart';
import 'package:my_year_my_story/screens/monthly/current_month_screen.dart';
import 'package:my_year_my_story/widgets/monthly/curiosities_widget.dart';

// 🌸 Menu inferior
import 'package:my_year_my_story/widgets/shared/app_bottom_menu.dart';

// ✨ Transição personalizada
import 'package:my_year_my_story/screens/splash/fade_page_transition.dart';

class DashboardScreen extends StatefulWidget {
  final int month;
  final int year;

  const DashboardScreen({
    Key? key,
    required this.month,
    required this.year,
  }) : super(key: key);

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
  String? dailyQuote; // 🌷 Nova frase do dia

  late int selectedMonth;
  late int selectedYear;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    selectedMonth = widget.month;
    selectedYear = widget.year;
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);
    final user = supabase.auth.currentUser;

    try {
      if (user == null) {
        debugPrint('Modo convidado detectado — pulando chamadas Supabase');
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

  String getNomeMes(int mes) {
    const meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return meses[mes - 1];
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final userName = user?.userMetadata?['name'] ?? 'Convidado';
    final now = DateTime.now();
    final diaSemana = DateFormat.EEEE('pt_BR').format(now);
    final dataCompleta =
        '$diaSemana, ${now.day} de ${getNomeMes(now.month)} de ${now.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      drawer: _buildDrawer(userName),
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

      // 🌸 BODY
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView( // ✅ resolve overflow e permite rolagem
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 36), // 🔧 respiro maior no topo
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Olá, $userName!',
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
                const SizedBox(height: 32), // 🔧 respiro antes do calendário

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
                            getNomeMes(index + 1).substring(0, 3),
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

                const SizedBox(height: 40), // 🔧 respiro antes da pesquisa

                // 🔍 Pesquisa
                _buildDateSearch(context),

                const SizedBox(height: 36), // 🔧 respiro antes do título de atividades

                const Text(
                  'Acompanhe suas atividades 💫',
                  style: TextStyle(
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
                      title: 'Metas',
                      icon: PhosphorIconsRegular.target,
                      color: const Color(0xFFF679BD3),
                      route: '/monthly_goals',
                    ),
                    _buildCard(
                      title: 'Humor',
                      icon: PhosphorIconsRegular.smiley,
                      color: const Color(0xFFF6B8C6),
                      route: '/mood_summary',
                    ),
                    _buildCard(
                      title: 'Diário',
                      icon: PhosphorIconsRegular.notebook,
                      color: const Color(0xFFe2377d),
                      route: '/diary_entries',
                    ),
                    _buildCard(
                      title: 'Quiz do Mês',
                      icon: PhosphorIconsRegular.star,
                      color: const Color(0xFFDBAF35),
                      route: '/interactive_quiz',
                    ),
                    _buildCard(
                      title: 'Gratidão',
                      icon: PhosphorIconsRegular.heart,
                      color: const Color(0xFFCF8EE8),
                      route: '/gratitude',
                    ),
                    _buildCard(
                      title: 'Sobre Mim',
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
                  const Text(
                    '🌙 Buscando uma inspiração para hoje...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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

  // 🔎 Pesquisa de data
  Widget _buildDateSearch(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2026),
          locale: const Locale('pt', 'BR'),
          helpText: 'Selecione uma data',
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
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, color: Colors.black54, size: 20),
            SizedBox(width: 8),
            Text(
              'Pesquisar datas anteriores',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 💠 Cards do dashboard
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
            target = DiaryScreen(month: selectedMonth, year: selectedYear);
            break;
          case '/interactive_quiz':
            target =
                InteractiveQuizScreen(month: selectedMonth, year: selectedYear);
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

  // 🌷 Drawer
  Drawer _buildDrawer(String userName) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFddbfef)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Text(
                  'Olá, $userName!',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const Text(
                  'My Year, My Story',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: () async {
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
    );
  }
}
