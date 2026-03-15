class ReviewService {
  static const bool _devPass =
      bool.fromEnvironment('DEV_PASS', defaultValue: false);

  static const Duration _minSessionBeforePrompt = Duration(minutes: 2);
  static const Duration _engagedSession = Duration(minutes: 8);
  static const int _consecutiveDaysThreshold = 3;

  static bool canShowReview({
    required String reviewStatus,
    DateTime? lastPrompt,
    required Duration sessionTime,
    required int daysSinceFirstOpen,
    required int consecutiveOpenDays,
  }) {
    // Nunca mais se já avaliou
    if (reviewStatus == 'reviewed') return false;

    if (_devPass) {
      // Dev pass: permite testar sem depender de engajamento real.
      // Ainda evita spammar de minuto em minuto.
      // E evita aparecer instantaneamente ao abrir o app.
      if (sessionTime < const Duration(seconds: 30)) return false;
      if (lastPrompt != null) {
        final diff = DateTime.now().difference(lastPrompt);
        if (diff.inMinutes < 5) return false;
      }
      return true;
    }

    // Intervalo mínimo de 5 dias
    if (lastPrompt != null) {
      final diff = DateTime.now().difference(lastPrompt);
      if (diff.inDays < 5) return false;
    }

    // Nunca mostrar instantaneamente ao abrir o app.
    if (sessionTime < _minSessionBeforePrompt) return false;

    // Engajamento real:
    // - Usuário ficou um tempo nessa sessão, OU
    // - Usuário voltou por alguns dias seguidos (mas ainda exige um mínimo de uso na sessão).
    final engaged =
        sessionTime >= _engagedSession ||
        consecutiveOpenDays >= _consecutiveDaysThreshold;

    return engaged;
  }
}
