import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';


import 'package:myyearmystory/widgets/monthly/monthly_goals_widget.dart';
import 'package:myyearmystory/widgets/monthly/gratitude_widget.dart';
import 'package:myyearmystory/widgets/monthly/interactive_quiz_widget.dart';
import 'package:myyearmystory/screens/diary/diary_screen.dart';
import 'package:myyearmystory/screens/mood/mood_screen.dart';
import 'package:myyearmystory/widgets/monthly/curiosities_widget.dart';

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
    if (user == null) return;

    try {
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
    } catch (e) {
      debugPrint('Erro ao carregar dashboard: $e');
    }

    setState(() => isLoading = false);
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
    final userName = user?.userMetadata?['name'] ?? 'Cíntia';
    final now = DateTime.now();
    final diaSemana = DateFormat.EEEE('pt_BR').format(now);
    final dataCompleta =
        '$diaSemana, ${now.day} de ${getNomeMes(now.month)} de ${now.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      drawer: _buildDrawer(userName),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE6E2FA),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'My Year, My Story',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Olá, $userName!',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  dataCompleta,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 12,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.3,
                  ),
                  itemBuilder: (context, index) {
                    final ativo = index + 1 == selectedMonth;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DashboardScreen(
                              month: index + 1,
                              year: selectedYear,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: ativo
                              ? const Color(0xFFC03B66)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
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

                const SizedBox(height: 28),
                const Text(
                  'Acompanhe suas atividades deste mês 💫',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC03B66),
                  ),
                ),
                const SizedBox(height: 18),

                isLoading
                    ? const CircularProgressIndicator()
                    : GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 12,
                  children: [
                    _buildCard(
                      title: 'Metas',
                      value: metasConcluidas > 0
                          ? metasConcluidas.toString()
                          : '—',
                      icon: Icons.flag,
                      color: const Color(0xFFFDE9EF),
                      route: '/monthly_goals',
                    ),
                    _buildCard(
                      title: 'Humor',
                      value: humorMaisComum ?? '—',
                      icon: Icons.emoji_emotions,
                      color: const Color(0xFFF6B8C6),
                      route: '/mood_summary',
                    ),
                    _buildCard(
                      title: 'Diário',
                      value: diarioCount > 0
                          ? diarioCount.toString()
                          : '—',
                      icon: Icons.book,
                      color: const Color(0xFFE6E2FA),
                      route: '/diary_entries',
                    ),
                    _buildCard(
                      title: 'Mente Brilhante!',
                      value: quizResultado ?? '—',
                      icon: Icons.local_florist,
                      color: const Color(0xFFFFD6A5),
                      route: '/interactive_quiz',
                    ),
                    _buildCard(
                      title: 'Gratidão',
                      value: gratidaoCount > 0
                          ? gratidaoCount.toString()
                          : '—',
                      icon: Icons.favorite,
                      color: const Color(0xFFD1B8DD),
                      route: '/gratitude',
                    ),
                    _buildCard(
                      title: 'Curiosidades',
                      value: curiosidadeAleatoria ??
                          'Descubra algo novo!',
                      icon: Icons.lightbulb_outline,
                      color: const Color(0xFFBEE3DB),
                      route: '/curiosities',
                      smallText: true,
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                Text(
                  metasConcluidas == 0 &&
                      gratidaoCount == 0 &&
                      diarioCount == 0
                      ? 'Você ainda pode conquistar suas metas deste mês!'
                      : 'A beleza está em continuar, mesmo devagar.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.black87,
                      fontSize: 14),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String route,
    bool smallText = false,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          route,
          arguments: {'month': selectedMonth, 'year': selectedYear},
        );
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
            )
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 26, color: Colors.black54),
              const SizedBox(height: 6),
              Text(
                value,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: smallText ? 12 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Drawer _buildDrawer(String userName) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFE6E2FA)),
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
                      color: Colors.black87,
                      fontSize: 16),
                ),
                const Text('My Year, My Story',
                    style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Perfil'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configurações'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Sobre o App'),
            onTap: () {},
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
