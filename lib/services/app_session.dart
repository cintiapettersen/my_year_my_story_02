enum AppAuthFlow {
  splash,
  authenticating,
  authenticated,
  guest,
  loggingOut, // 👈 IMPORTANTE
}

class AppSession {
  static AppAuthFlow flow = AppAuthFlow.splash;

  static bool get isGuest => flow == AppAuthFlow.guest;
  static bool get isAuthenticated => flow == AppAuthFlow.authenticated;
  static bool get isAuthenticating => flow == AppAuthFlow.authenticating;
  static bool get isSplash => flow == AppAuthFlow.splash;

  // ✅ AGORA SIM
  static bool get isLoggingOut => flow == AppAuthFlow.loggingOut;

  static void reset() {
    flow = AppAuthFlow.splash;
  }
}