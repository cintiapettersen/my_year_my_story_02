import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:easy_localization/easy_localization.dart';

// 🌸 Estilo e Configuração
import 'package:my_year_my_story/theme.dart';
import 'package:my_year_my_story/supabase/supabase_config.dart';

// 🌸 Telas principais
import 'package:my_year_my_story/screens/splash/splash_transition.dart';
import 'package:my_year_my_story/screens/auth/login_screen.dart';
import 'package:my_year_my_story/screens/dashboard/dashboard_screen.dart';
import 'package:my_year_my_story/screens/diary/diary_screen.dart';
import 'package:my_year_my_story/screens/annual/annual_photo_album_screen.dart';
import 'package:my_year_my_story/screens/mood/mood_screen.dart';

// 🌸 Widgets mensais
import 'package:my_year_my_story/widgets/monthly/monthly_goals_widget.dart';
import 'package:my_year_my_story/widgets/monthly/gratitude_widget.dart';
import 'package:my_year_my_story/widgets/monthly/reflections_widget.dart';
import 'package:my_year_my_story/widgets/monthly/interactive_quiz_widget.dart';
import 'package:my_year_my_story/widgets/monthly/curiosities_widget.dart';
import 'package:my_year_my_story/widgets/monthly/zodiac_widget.dart';
import 'package:my_year_my_story/widgets/monthly/skills_development_widget.dart';
import 'package:my_year_my_story/widgets/monthly/did_you_know_widget.dart';
import 'package:my_year_my_story/widgets/monthly/interview_widget.dart';
import 'package:my_year_my_story/widgets/monthly/monthly_lists_widget.dart';
import 'package:my_year_my_story/widgets/monthly/monthly_photo_gallery.dart';
import 'package:my_year_my_story/screens/quiz/interactive_quiz_screen.dart';

// ✨ Transição personalizada
import 'package:my_year_my_story/screens/splash/fade_page_transition.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EasyLocalization.ensureInitialized(); // ✅ Inicializa traduções
  await initializeDateFormatting('pt_BR', null);
  await initializeDateFormatting('en_US', null);
  await SupabaseConfig.initialize();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('pt')],
      path: 'assets/translations',
      fallbackLocale: const Locale('pt'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    final client = Supabase.instance.client;
    final now = DateTime.now();

    // 🔒 Login não é mais obrigatório — o splash cuida da decisão inicial.
    client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final user = data.session?.user;
      print('📢 Auth event detectado: $event');
      if (user != null) print('👤 Usuário: ${user.email}');

      final context = _navigatorKey.currentContext;
      if (context == null) return;

      if (event == AuthChangeEvent.signedIn) {
        print('✅ Usuário autenticado com sucesso!');
        Navigator.of(context).pushAndRemoveUntil(
          fadePageTransition(
            DashboardScreen(month: now.month, year: now.year),
          ),
              (route) => false,
        );
      } else if (event == AuthChangeEvent.signedOut) {
        print('🚪 Usuário saiu da sessão.');
        Navigator.of(context).pushAndRemoveUntil(
          fadePageTransition(const LoginScreen()),
              (route) => false,
        );
      } else if (event == AuthChangeEvent.signedIn && user == null) {
        print('⚠️ Evento signedIn sem usuário detectado!');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'My Year, My Story',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,

      // ✅ EasyLocalization integrado
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // 🌸 Agora o app inicia pelo splash animado
      home: const SplashTransitionScreen(),

      routes: {
        '/splash': (context) => const SplashTransitionScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) =>
            DashboardScreen(month: now.month, year: now.year),
        '/diary_entries': (context) =>
            DiaryScreen(month: now.month, year: now.year),
        '/annual_photos': (context) =>
            AnnualPhotoAlbumScreen(month: now.month, year: now.year),
        '/mood_summary': (context) =>
            MoodScreen(month: now.month, year: now.year),

        // 🌙 Widgets mensais com passagem de argumentos
        '/monthly_goals': (context) => _withArgs(context, (args) =>
            MonthlyGoalsWidget(month: args['month'], year: args['year'])),
        '/gratitude': (context) => _withArgs(context, (args) =>
            GratitudeWidget(month: args['month'], year: args['year'])),
        '/reflections': (context) => _withArgs(context, (args) =>
            ReflectionsWidget(month: args['month'], year: args['year'])),
        '/interactive_quiz': (context) => _withArgs(context, (args) =>
            InteractiveQuizScreen(
              month: args['month'],
              year: args['year'],
            )),
        '/curiosities': (context) => _withArgs(context, (args) =>
            CuriositiesWidget(month: args['month'], year: args['year'])),
        '/zodiac': (context) => _withArgs(context, (args) =>
            ZodiacWidget(month: args['month'], year: args['year'])),
        '/skills_development': (context) => _withArgs(context, (args) =>
            SkillsDevelopmentWidget(month: args['month'], year: args['year'])),
        '/did_you_know': (context) => _withArgs(context, (args) =>
            DidYouKnowWidget(month: args['month'], year: args['year'])),
        '/interview': (context) => _withArgs(context, (args) =>
            InterviewWidget(month: args['month'], year: args['year'])),
        '/monthly_lists': (context) => _withArgs(context, (args) =>
            MonthlyListsWidget(month: args['month'], year: args['year'])),
        '/monthly_photo_gallery': (context) => _withArgs(context, (args) =>
            MonthlyPhotoGallery(month: args['month'], year: args['year'])),
      },
    );
  }

  /// ✅ Helper genérico pra rotas com args de mês/ano
  Widget _withArgs(
      BuildContext context, Widget Function(Map<String, dynamic>) builder) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ??
        {'month': DateTime.now().month, 'year': DateTime.now().year};
    return builder(args.cast<String, dynamic>());
  }
}
