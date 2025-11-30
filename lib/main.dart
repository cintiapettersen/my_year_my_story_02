
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:myyearmystory/widgets/monthly/dailyluckpage.dart';
import 'package:myyearmystory/services/auth_listener.dart';
import 'package:myyearmystory/services/profile_service.dart';
import 'package:myyearmystory/screens/premium/premium_page.dart';


// 🌸 Estilo e Configuração
import 'package:myyearmystory/theme.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';

// 🌸 Telas principais
import 'package:myyearmystory/screens/auth/auth_page_view.dart';
import 'package:myyearmystory/screens/dashboard/dashboard_screen.dart';
import 'package:myyearmystory/screens/splash/splash_transition.dart';

// 🌸 Widgets mensais

import 'package:myyearmystory/widgets/monthly/reflections_widget.dart';
import 'package:myyearmystory/widgets/monthly/curiosities_widget.dart';
import 'package:myyearmystory/widgets/monthly/zodiac_widget.dart';
import 'package:myyearmystory/widgets/monthly/skills_development_widget.dart';
import 'package:myyearmystory/widgets/monthly/did_you_know_widget.dart';
import 'package:myyearmystory/widgets/monthly/interview_widget.dart';
import 'package:myyearmystory/widgets/monthly/monthly_lists_widget.dart';
import 'package:myyearmystory/widgets/monthly/photo_gallery_widget.dart';
import 'package:myyearmystory/widgets/monthly/monthly_goals_widget.dart';
import 'package:myyearmystory/widgets/monthly/gratitude_widget.dart';


// 🌸 Telas do menu lateral (hambúrguer)
import 'package:myyearmystory/screens/menus/profile_screen.dart';
import 'package:myyearmystory/screens/menus/help_screen.dart';

/// 🌎 Alertas de calendarios 

import 'package:myyearmystory/screens/notifications/notifications_page.dart';



/// 🌎 Chave global de navegação
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🌍 Inicializa localização e formatação
  await EasyLocalization.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await initializeDateFormatting('en_US', null);

  // 🕵️ Detecta o idioma e região do sistema
  final systemLocale = ui.PlatformDispatcher.instance.locale;
  final countryCode = systemLocale.countryCode ?? 'BR';
  final languageCode = systemLocale.languageCode;

  // 📅 Define formato de data padrão:
  // - Se for EUA → usa en_US
  // - Caso contrário → usa pt_BR
  if (countryCode == 'US') {
    Intl.defaultLocale = 'en_US';
  } else {
    Intl.defaultLocale = 'pt_BR';
  }



    // 🚀 Inicializa Supabase
  await SupabaseConfig.initialize();

  // 🔐 Inicia listener global de autenticação (o CORRETO)
  AuthListener.initialize(navigatorKey);

  

await profileService.load();

  // 🌎 Define locale inicial do app
  Locale initialLocale;
  if (countryCode == 'BR' || countryCode == 'PT') {
    initialLocale = const Locale('pt');
  } else {
    initialLocale = const Locale('en');
  }


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
      title: 'My Year, My Story',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,

      // 🌎 Configurações de localização
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // 🌸 Tela inicial → Splash (decide login ou dashboard)
      home: const SplashTransitionScreen(),

      // 🌸 Rotas nomeadas
     routes: {
  '/splash': (context) => const SplashTransitionScreen(),
  '/login': (context) => const AuthPageView(),

  '/dashboard': (context) => _withArgs(
        context,
        (args) => DashboardScreen(
          month: args['month'] ?? DateTime.now().month,
          year: args['year'] ?? DateTime.now().year,
        ),
      ),

  '/profile': (context) =>  ProfileScreen(),
  '/help': (context) =>  HelpScreen(),

  '/premium': (context) => _withArgs(
        context,
        (args) => const PremiumPage(),
      ),

  // ⭐ NOVA ROTA — NOTIFICAÇÕES
  '/daily_notifications': (context) => const NotificationsPage(),

  // ⭐ WIDGETS MENSAIS
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
},

    );
  }

  /// 🧭 Helper genérico para rotas com argumentos de mês/ano
  Widget _withArgs(
      BuildContext context,
      Widget Function(Map<String, dynamic>) builder,
      ) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ??
        {'month': DateTime.now().month, 'year': DateTime.now().year};
    return builder(args.cast<String, dynamic>());
  }
}

