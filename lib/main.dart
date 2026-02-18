import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';


import 'package:myyearmystory/theme.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/services/auth_listener.dart';
import 'package:myyearmystory/services/oauth_deeplink_handler.dart';

import 'package:myyearmystory/screens/splash/splash_transition.dart';
import 'package:myyearmystory/screens/auth/auth_page_view.dart';
import 'package:myyearmystory/screens/dashboard/dashboard_screen.dart';
import 'package:myyearmystory/screens/diary/diary_screen.dart';
import 'package:myyearmystory/screens/premium/premium_page.dart';
import 'package:myyearmystory/screens/auth/reset_password_screen.dart';

import 'package:myyearmystory/screens/menus/profile_screen.dart';
import 'package:myyearmystory/screens/menus/help_screen.dart';
import 'package:myyearmystory/screens/notifications/notifications_page.dart';

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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await EasyLocalization.ensureInitialized();
  await SupabaseConfig.initialize();

  OAuthDeepLinkHandler.initialize();
  AuthListener.initialize(navigatorKey);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('pt')],
      path: 'assets/translations',
      fallbackLocale: const Locale('pt'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      themeMode: ThemeMode.system,

      // 🌍 LOCALIZAÇÃO (fonte única da verdade)
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      home: const SplashTransitionScreen(),

      routes: {
  '/login': (_) => const AuthPageView(),

  // 👇 ESSA É A ROTA QUE ESTAVA FALTANDO
  '/login-callback': (_) => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),

  '/reset-password': (_) => const ResetPasswordScreen(),

  '/dashboard': (_) => DashboardScreen(
        month: DateTime.now().month,
        year: DateTime.now().year,
      ),

  '/profile': (_) => ProfileScreen(),
  '/help': (_) => HelpScreen(),
  '/premium': (_) => const PremiumPage(),
  '/daily_notifications': (_) => const NotificationsPage(),

  '/monthly_goals': (_) => _withArgs(
        (args) => MonthlyGoalsWidget(
          month: args['month'],
          year: args['year'],
        ),
      ),

  '/gratitude': (_) => _withArgs(
        (args) => GratitudeWidget(
          month: args['month'],
          year: args['year'],
        ),
      ),

  '/reflections': (_) => _withArgs(
        (args) => ReflectionsWidget(
          month: args['month'],
          year: args['year'],
        ),
      ),

  '/curiosities': (_) => _withArgs(
        (args) => CuriositiesWidget(
          month: args['month'],
          year: args['year'],
        ),
      ),

  '/zodiac': (_) => _withArgs(
        (args) => ZodiacWidget(
          month: args['month'],
          year: args['year'],
        ),
      ),

  '/skills_development': (_) => _withArgs(
        (args) => SkillsDevelopmentWidget(
          month: args['month'],
          year: args['year'],
        ),
      ),

  '/did_you_know': (_) => _withArgs(
        (args) => DidYouKnowWidget(
          month: args['month'],
          year: args['year'],
        ),
      ),

  '/interview': (_) => _withArgs(
        (args) => InterviewScreen(
          month: args['month'],
          year: args['year'],
        ),
      ),

  '/monthly_lists': (_) => _withArgs(
        (args) => MonthlyListsWidget(
          month: args['month'],
          year: args['year'],
        ),
      ),

  '/monthly_photo_gallery': (_) => _withArgs(
        (args) => MonthlyPhotoGallery(
          month: args['month'],
          year: args['year'],
        ),
      ),

  '/diary': (context) {
    final arg = ModalRoute.of(context)?.settings.arguments;
    final date = arg is DateTime ? arg : DateTime.now();
    return DiaryScreen(date: date);
  },
},

    );
  }
}

Widget _withArgs(
  Widget Function(Map<String, dynamic>) builder,
) {
  final args = navigatorKey.currentContext != null
      ? (ModalRoute.of(navigatorKey.currentContext!)?.settings.arguments
              as Map?) ??
          {
            'month': DateTime.now().month,
            'year': DateTime.now().year,
          }
      : {
          'month': DateTime.now().month,
          'year': DateTime.now().year,
        };

  return builder(args.cast<String, dynamic>());
}
