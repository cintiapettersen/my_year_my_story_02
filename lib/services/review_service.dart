class ReviewService {
  static bool canShowReview({
    required String reviewStatus,
    DateTime? lastPrompt,
    required Duration sessionTime,
    required int daysSinceFirstOpen,
  }) {
    // Nunca mais se já avaliou
    if (reviewStatus == 'reviewed') return false;

    // Intervalo mínimo de 5 dias
    if (lastPrompt != null) {
      final diff = DateTime.now().difference(lastPrompt);
      if (diff.inDays < 5) return false;
    }

    // Engajamento real
    final engaged =
        sessionTime.inMinutes >= 12 || daysSinceFirstOpen >= 5;

    return engaged;
  }
}
