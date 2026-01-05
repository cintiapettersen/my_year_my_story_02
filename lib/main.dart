import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:myyearmystory/theme.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';

// Core screens
import 'package:myyearmystory/screens/splash/splash_transition.dart';
import 'package:myyearmystory/screens/auth/auth_page_view.dart';
import 'package:myyearmystory/screens/dashboard/dashboard_screen.dart';
import 'package:myyearmystory/screens/diary/diary_screen.dart';
import 'package:myyearmystory/screens/premium/premium_page.dart';

// Menu
import 'package:myyearmystory/screens/menus/profile_screen.dart';
import 'package:myyearmystory/screens/menus/help_screen.dart';
import 'package:myyearmystory/screens/notifications/notifications_page.dart';

// Monthly widgets
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

// Services
import 'package:myyearmystory/services/auth_listener.dart';
import 'package:myyearmystory/services/oauth_deeplink_handler.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await EasyLocalization.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await initializeDateFormatting('en_US', null);

  final systemLocale = ui.PlatformDispatcher.instance.locale;
  final countryCode = systemLocale.countryCode ?? 'BR';

  Intl.defaultLocale = countryCode == 'US' ? 'en_US' : 'pt_BR';

 await SupabaseConfig.initialize();

// 🔗 escuta deep links OAuth PRIMEIRO
OAuthDeepLinkHandler.initialize();

// 🔑 AuthListener depois
AuthListener.initialize(navigatorKey);

  final Locale initialLocale =
      (countryCode == 'BR' || countryCode == 'PT')
          ? const Locale('pt')
          : const Locale('en');

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('pt')],
      path: 'assets/translations',
      fallbackLocale: const Locale('pt'),
      startLocale: initialLocale,
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
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
     
      themeMode: ThemeMode.system,

      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // 🔑 SEMPRE começa no splash
      home: const SplashTransitionScreen(),


      routes: {
        '/splash': (_) => const SplashTransitionScreen(),
        '/login': (_) => const AuthPageView(),
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

// Helper único e consistente
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
