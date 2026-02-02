class ReviewService {
  static bool canShowReview({
    required String reviewStatus,
    DateTime? lastPrompt,
    required Duration sessionTime,
    required int daysSinceFirstOpen,
  }) {
    if (reviewStatus == 'reviewed') return false;

    if (reviewStatus == 'dismissed' && lastPrompt != null) {
      final diff = DateTime.now().difference(lastPrompt);
      if (diff.inDays < 30) return false;
    }

    final engaged =
        sessionTime.inMinutes >= 10 || daysSinceFirstOpen >= 4;

    return engaged;
  }
}
