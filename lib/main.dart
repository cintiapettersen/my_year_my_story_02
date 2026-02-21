import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:myyearmystory/theme.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/services/app_session.dart';
import 'package:myyearmystory/services/auth_listener.dart';
import 'package:myyearmystory/services/profile_service.dart';
import 'package:myyearmystory/services/app_navigator.dart';

import 'package:myyearmystory/screens/splash/splash_transition.dart';
import 'package:myyearmystory/screens/auth/auth_page_view.dart';
import 'package:myyearmystory/screens/auth/complete_profile_screen.dart';
import 'package:myyearmystory/screens/dashboard/dashboard_screen.dart';
import 'package:myyearmystory/screens/diary/diary_screen.dart';
import 'package:myyearmystory/screens/monthly/current_month_screen.dart';
import 'package:myyearmystory/screens/mood/mood_screen.dart';
import 'package:myyearmystory/screens/quiz/standalone.dart';
import 'package:myyearmystory/screens/premium/premium_page.dart';
import 'package:myyearmystory/screens/auth/reset_password_screen.dart';

import 'package:myyearmystory/screens/menus/profile_screen.dart';
import 'package:myyearmystory/screens/menus/help_screen.dart';
import 'package:myyearmystory/screens/menus/language_screen.dart';
import 'package:myyearmystory/screens/menus/about_modal.dart';
import 'package:myyearmystory/screens/messages/central_messages_page.dart';
import 'package:myyearmystory/screens/notifications/notifications_page.dart';
import 'package:myyearmystory/widgets/monthly/calender/calendar_page.dart';

import 'package:myyearmystory/widgets/monthly/monthly_goals_widget.dart';
import 'package:myyearmystory/widgets/monthly/gratitude_widget.dart';
import 'package:myyearmystory/widgets/monthly/reflections_widget.dart';
import 'package:myyearmystory/widgets/monthly/curiosities_widget.dart';
import 'package:myyearmystory/widgets/monthly/zodiac_widget.dart';
import 'package:myyearmystory/widgets/monthly/skills_development_widget.dart';
import 'package:myyearmystory/widgets/monthly/did_you_know_widget.dart';
import 'package:myyearmystory/widgets/monthly/interview_widget.dart';
import 'package:myyearmystory/widgets/monthly/monthly_lists_widget.dart';
import 'package:myyearmystory/widgets/monthly/photo_gallery_widget.dart';

import 'package:provider/provider.dart';
import 'services/purchase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await EasyLocalization.ensureInitialized();
  await SupabaseConfig.initialize();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('pt')],
      path: 'assets/translations',
      fallbackLocale: const Locale('pt'),
      child: MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => PurchaseService())],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {


  late final GoRouter _router = GoRouter(
    initialLocation: '/splash',


    
    refreshListenable: GoRouterRefreshStream(
      // atualiza o router quando o estado de auth mudar
      AuthListener.stream.map((event) => event.session),
    ),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashTransitionScreen(),
      ),
      GoRoute(path: '/login', builder: (_, __) => const AuthPageView()),
      GoRoute(
        path: '/login-callback',
        builder: (_, __) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, __) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (_, __) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder:
            (_, __) => DashboardScreen(
              month: DateTime.now().month,
              year: DateTime.now().year,
            ),
      ),
      GoRoute(path: '/profile', builder: (_, __) => ProfileScreen()),
      GoRoute(path: '/help', builder: (_, __) => HelpScreen()),
      GoRoute(path: '/language', builder: (_, __) => const LanguageScreen()),
      GoRoute(path: '/about', builder: (_, __) => const AboutAppScreen()),
      GoRoute(path: '/premium', builder: (_, __) => const PremiumPage()),
      GoRoute(
        path: '/daily_notifications',
        builder: (_, __) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/current_month',
        builder: (_, state) {
          final args = (state.extra as Map?) ?? {};
          return CurrentMonthScreen(
            month: args['month'] ?? DateTime.now().month,
            year: args['year'] ?? DateTime.now().year,
          );
        },
      ),
      GoRoute(
        path: '/central_messages',
        builder: (_, __) => const CentralMessagesPage(),
      ),
      GoRoute(
        path: '/calendar_page',
        builder: (_, state) {
          final args = (state.extra as Map?) ?? {};
          return CalendarPage(
            month: args['month'] ?? DateTime.now().month,
            year: args['year'] ?? DateTime.now().year,
          );
        },
      ),
      GoRoute(
        path: '/mood',
        builder: (_, state) {
          final args = (state.extra as Map?) ?? {};
          return MoodScreen(
            month: args['month'] ?? DateTime.now().month,
            year: args['year'] ?? DateTime.now().year,
          );
        },
      ),
      GoRoute(
        path: '/interactive_quiz',
        builder: (_, state) {
          final args = (state.extra as Map?) ?? {};
          return InteractiveQuizStandalone(
            month: args['month'] ?? DateTime.now().month,
            year: args['year'] ?? DateTime.now().year,
          );
        },
      ),
      GoRoute(
        path: '/monthly_goals',
        builder:
            (_, state) => _monthlyWithArgs(
              state,
              (args) =>
                  MonthlyGoalsWidget(month: args['month'], year: args['year']),
            ),
      ),
      GoRoute(
        path: '/gratitude',
        builder:
            (_, state) => _monthlyWithArgs(
              state,
              (args) =>
                  GratitudeWidget(month: args['month'], year: args['year']),
            ),
      ),
      GoRoute(
        path: '/reflections',
        builder:
            (_, state) => _monthlyWithArgs(
              state,
              (args) =>
                  ReflectionsWidget(month: args['month'], year: args['year']),
            ),
      ),
      GoRoute(
        path: '/curiosities',
        builder:
            (_, state) => _monthlyWithArgs(
              state,
              (args) =>
                  CuriositiesWidget(month: args['month'], year: args['year']),
            ),
      ),
      GoRoute(
        path: '/zodiac',
        builder:
            (_, state) => _monthlyWithArgs(
              state,
              (args) => ZodiacWidget(month: args['month'], year: args['year']),
            ),
      ),
      GoRoute(
        path: '/skills_development',
        builder:
            (_, state) => _monthlyWithArgs(
              state,
              (args) => SkillsDevelopmentWidget(
                month: args['month'],
                year: args['year'],
              ),
            ),
      ),
      GoRoute(
        path: '/did_you_know',
        builder:
            (_, state) => _monthlyWithArgs(
              state,
              (args) =>
                  DidYouKnowWidget(month: args['month'], year: args['year']),
            ),
      ),
      GoRoute(
        path: '/interview',
        builder:
            (_, state) => _monthlyWithArgs(
              state,
              (args) =>
                  InterviewScreen(month: args['month'], year: args['year']),
            ),
      ),
      GoRoute(
        path: '/monthly_lists',
        builder:
            (_, state) => _monthlyWithArgs(
              state,
              (args) =>
                  MonthlyListsWidget(month: args['month'], year: args['year']),
            ),
      ),
      GoRoute(
        path: '/monthly_photo_gallery',
        builder:
            (_, state) => _monthlyWithArgs(
              state,
              (args) =>
                  MonthlyPhotoGallery(month: args['month'], year: args['year']),
            ),
      ),
      GoRoute(
        path: '/diary',
        builder: (_, state) {
          final date =
              state.extra is DateTime
                  ? state.extra as DateTime
                  : DateTime.now();
          return DiaryScreen(date: date);
        },
      ),
    ],
    redirect: (_, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final loc = state.matchedLocation;

      // 👇 TRATAR RAIZ
  if (loc == '/') {
    return '/splash';
  }

      final isAuthRoute = loc.startsWith('/login');
      final isSplash = loc == '/splash';
      final isReset = loc == '/reset-password';

      if (session == null) {
        // sem sessão: deixa reset passar, demais vão para login
        if (isReset || isAuthRoute) return null;
        return '/login';
      }

      // sessão existe: evita voltar para login/splash
      if (isSplash || isAuthRoute) return '/dashboard';
      return null;
    },
  );

  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = AuthListener.stream.listen(_handleAuthChange);
    AppNavigator.setRouter(_router);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      themeMode: ThemeMode.system,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      routerConfig: _router,
    );
  }

  void _handleAuthChange(AuthState data) async {
    final event = data.event;
    final session = data.session;

    switch (event) {
      case AuthChangeEvent.signedIn:
        if (session == null) return;
        AppSession.flow = AppAuthFlow.authenticating;
        await profileService.ensureProfile();
        await profileService.load();
        AppSession.flow = AppAuthFlow.authenticated;
        final destination =
            profileService.isProfileComplete
                ? '/dashboard'
                : '/complete-profile';
        _router.go(destination);
        break;
      case AuthChangeEvent.signedOut:
        AppSession.flow = AppAuthFlow.splash;
        _router.go('/login');
        break;
      case AuthChangeEvent.passwordRecovery:
        if (session == null) return;
        AppSession.flow = AppAuthFlow.resettingPassword;
        _router.go('/reset-password');
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

/// Ajuda o GoRouter a re-renderizar ao receber eventos do stream.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

Widget _monthlyWithArgs(
  GoRouterState state,
  Widget Function(Map<String, dynamic>) builder,
) {
  final args =
      (state.extra as Map?) ??
      {'month': DateTime.now().month, 'year': DateTime.now().year};
  return builder(args.cast<String, dynamic>());
}
