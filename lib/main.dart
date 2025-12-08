// ---------------------------------------------------------
// 🌟 System & Core Imports
// ---------------------------------------------------------
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---------------------------------------------------------
// 🌍 External Packages
// ---------------------------------------------------------
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// ---------------------------------------------------------
// 🎨 Theme & Config
// ---------------------------------------------------------
import 'package:myyearmystory/theme.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';

// ---------------------------------------------------------
// 📱 Core Screens
// ---------------------------------------------------------
import 'package:myyearmystory/screens/auth/auth_page_view.dart';
import 'package:myyearmystory/screens/dashboard/dashboard_screen.dart';
import 'package:myyearmystory/screens/splash/splash_transition.dart';
import 'package:myyearmystory/screens/diary/diary_screen.dart';
import 'package:myyearmystory/screens/premium/premium_page.dart';

// ---------------------------------------------------------
// 🧭 Menu Screens
// ---------------------------------------------------------
import 'package:myyearmystory/screens/menus/profile_screen.dart';
import 'package:myyearmystory/screens/menus/help_screen.dart';
import 'package:myyearmystory/screens/notifications/notifications_page.dart';

// ---------------------------------------------------------
// 🗂️ Monthly Widgets
// ---------------------------------------------------------
import 'package:myyearmystory/widgets/monthly/curiosities_widget.dart';
import 'package:myyearmystory/widgets/monthly/reflections_widget.dart';
import 'package:myyearmystory/widgets/monthly/zodiac_widget.dart';
import 'package:myyearmystory/widgets/monthly/did_you_know_widget.dart';
import 'package:myyearmystory/widgets/monthly/interview_widget.dart';
import 'package:myyearmystory/widgets/monthly/skills_development_widget.dart';
import 'package:myyearmystory/widgets/monthly/monthly_lists_widget.dart';
import 'package:myyearmystory/widgets/monthly/photo_gallery_widget.dart';
import 'package:myyearmystory/widgets/monthly/monthly_goals_widget.dart';
import 'package:myyearmystory/widgets/monthly/gratitude_widget.dart';

// ---------------------------------------------------------
// 🔐 Auth & Services
// ---------------------------------------------------------
import 'package:myyearmystory/services/auth_listener.dart';
import 'package:myyearmystory/services/profile_service.dart';
import 'package:myyearmystory/services/auth_service.dart'; // <-- IMPORTANTE!!

// ---------------------------------------------------------
// 🧭 Global Navigation Key
// ---------------------------------------------------------
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ---------------------------------------------------------
// 🚀 MAIN FUNCTION
// ---------------------------------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔒 Force portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 🌍 Localization initialization
  await EasyLocalization.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await initializeDateFormatting('en_US', null);

  // 🌎 Detect system locale
  final systemLocale = ui.PlatformDispatcher.instance.locale;
  final countryCode = systemLocale.countryCode ?? 'BR';

  // 📅 Default locale fallback
  Intl.defaultLocale = (countryCode == 'US') ? 'en_US' : 'pt_BR';

  // 🔗 Initialize backend (Supabase)
  await SupabaseConfig.initialize();

  // 🔥 Restore saved session (biometry depends on this!)
  final sessionRestored = await AuthService.restoreSession();
  print("RESTORED SESSION? → $sessionRestored");

  // 🔐 Global auth listener
  AuthListener.initialize(navigatorKey);

  // 👤 Load user profile in background
  await profileService.load();

  // 🌍 Pick initial app locale
  final Locale initialLocale =
      (countryCode == 'BR' || countryCode == 'PT') ? const Locale('pt') : const Locale('en');

  // 🚀 Run application
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('pt'),
      ],
      path: 'assets/translations',
      assetLoader: const RootBundleAssetLoader(),
      fallbackLocale: const Locale('pt'),
      startLocale: initialLocale,
      saveLocale: true,
      child: MyApp(sessionRestored: sessionRestored),
    ),
  );
}

// ---------------------------------------------------------
// 🌟 APPLICATION ROOT
// ---------------------------------------------------------
class MyApp extends StatelessWidget {
  final bool sessionRestored;

  const MyApp({super.key, required this.sessionRestored});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'My Year, My Story',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,

      // 🌍 Localization setup
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // ⭐ DECIDE WHICH SCREEN TO OPEN ⭐
      home: sessionRestored
          ? DashboardScreen(
              month: DateTime.now().month,
              year: DateTime.now().year,
            )
          : const SplashTransitionScreen(),

      // ---------------------------------------------------------
      // 🧭 Named Routes
      // ---------------------------------------------------------
      routes: {
        '/splash': (context) => const SplashTransitionScreen(),
        '/login': (context) => const AuthPageView(),

        '/dashboard': (context) => DashboardScreen(
              month: DateTime.now().month,
              year: DateTime.now().year,
            ),

        '/profile': (context) => ProfileScreen(),
        '/help': (context) => HelpScreen(),
        '/premium': (context) => const PremiumPage(),
        '/daily_notifications': (context) => const NotificationsPage(),

        '/monthly_goals': (context) => _withArgs(
              context,
              (args) => MonthlyGoalsWidget(
                month: args['month'],
                year: args['year'],
              ),
            ),

        '/gratitude': (context) => _withArgs(
              context,
              (args) => GratitudeWidget(
                month: args['month'],
                year: args['year'],
              ),
            ),

        '/reflections': (context) => _withArgs(
              context,
              (args) => ReflectionsWidget(
                month: args['month'],
                year: args['year'],
              ),
            ),

        '/curiosities': (context) => _withArgs(
              context,
              (args) => CuriositiesWidget(
                month: args['month'],
                year: args['year'],
              ),
            ),

        '/zodiac': (context) => _withArgs(
              context,
              (args) => ZodiacWidget(
                month: args['month'],
                year: args['year'],
              ),
            ),

        '/skills_development': (context) => _withArgs(
              context,
              (args) => SkillsDevelopmentWidget(
                month: args['month'],
                year: args['year'],
              ),
            ),

        '/did_you_know': (context) => _withArgs(
              context,
              (args) => DidYouKnowWidget(
                month: args['month'],
                year: args['year'],
              ),
            ),

        '/interview': (context) => _withArgs(
              context,
              (args) => InterviewScreen(
                month: args['month'],
                year: args['year'],
              ),
            ),

        '/monthly_lists': (context) => _withArgs(
              context,
              (args) => MonthlyListsWidget(
                month: args['month'],
                year: args['year'],
              ),
            ),

        '/monthly_photo_gallery': (context) => _withArgs(
              context,
              (args) => MonthlyPhotoGallery(
                month: args['month'],
                year: args['year'],
              ),
            ),

        '/diary': (context) {
          final arg = ModalRoute.of(context)?.settings.arguments;
          final date = (arg is DateTime) ? arg : DateTime.now();
          return DiaryScreen(date: date);
        },
      },
    );
  }

  // ---------------------------------------------------------
  // 🧩 Route Helper (month/year)
  // ---------------------------------------------------------
  Widget _withArgs(
    BuildContext context,
    Widget Function(Map<String, dynamic>) builder,
  ) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ??
        {
          'month': DateTime.now().month,
          'year': DateTime.now().year,
        };

    return builder(args.cast<String, dynamic>());
  }
}
