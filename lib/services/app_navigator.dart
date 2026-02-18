import 'package:go_router/go_router.dart';

/// Armazena uma referência global ao GoRouter para casos em que
/// não há BuildContext disponível (ex.: serviços).
class AppNavigator {
  static GoRouter? router;

  static void setRouter(GoRouter r) {
    router = r;
  }

  static void go(String location, {Object? extra}) {
    router?.go(location, extra: extra);
  }

  static Future<T?>? push<T>(String location, {Object? extra}) =>
      router?.push<T>(location, extra: extra);
}
