import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Privacy-first entry point for all Analytics usage in the app.
///
/// PROHIBITED ANALYTICS PARAMETERS/DATA:
/// diary text, AI prompts or responses, audio, transcriptions, mood/emotion,
/// searched or selected dates, name, email, Supabase user ID, any user-provided
/// content, entry length, localized price, and product identifiers.
///
/// Do not add identifiers, user properties, or calls to `setUserId` here.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  static const String _consentKey = 'analytics_consent_v1';

  /// Kept as code-level documentation so additions are reviewed explicitly.
  static const Set<String> prohibitedParameters = {
    'diary_text',
    'ai_prompt',
    'ai_response',
    'audio',
    'transcription',
    'mood',
    'emotion',
    'date',
    'name',
    'email',
    'user_id',
    'supabase_user_id',
    'user_content',
    'entry_length',
    'localized_price',
    'product_id',
  };

  static const Set<String> _allowedEvents = {
    'onboarding_started',
    'onboarding_completed',
    'sign_up_completed',
    'login_completed',
    'diary_opened',
    'diary_entry_started',
    'diary_entry_saved',
    'diary_entry_updated',
    'diary_entry_deleted',
    'diary_filter_used',
    'diary_filter_cleared',
    'reflection_requested',
    'reflection_completed',
    'premium_viewed',
    'subscription_checkout_started',
    'subscription_completed',
    'purchase_restored',
  };

  static const Map<String, Set<String>> _allowedParameters = {
    'diary_filter_used': {'filter_type'},
    'subscription_checkout_started': {'plan_type'},
    'subscription_completed': {'plan_type'},
  };

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final ValueNotifier<AnalyticsConsentStatus> consent =
      ValueNotifier<AnalyticsConsentStatus>(AnalyticsConsentStatus.unknown);
  final Set<String> _oncePerRun = <String>{};
  String? _lastScreenName;

  bool get hasConsentChoice => consent.value != AnalyticsConsentStatus.unknown;
  bool get isEnabled => consent.value == AnalyticsConsentStatus.granted;

  Future<void> initialize() async {
    // Collection is disabled natively too; repeat before reading preferences.
    await _silently(() => _analytics.setAnalyticsCollectionEnabled(false));
    final preferences = await SharedPreferences.getInstance();
    final savedChoice = preferences.getBool(_consentKey);
    consent.value = switch (savedChoice) {
      true => AnalyticsConsentStatus.granted,
      false => AnalyticsConsentStatus.denied,
      null => AnalyticsConsentStatus.unknown,
    };
    if (savedChoice == true) {
      await _silently(() => _analytics.setAnalyticsCollectionEnabled(true));
    }
  }

  Future<void> setConsent(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_consentKey, enabled);
    consent.value =
        enabled
            ? AnalyticsConsentStatus.granted
            : AnalyticsConsentStatus.denied;
    if (!enabled) {
      _lastScreenName = null;
      _oncePerRun.clear();
    }
    await _silently(() => _analytics.setAnalyticsCollectionEnabled(enabled));
  }

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    if (!isEnabled || !_allowedEvents.contains(name)) return;
    final values = parameters ?? const <String, Object>{};
    final allowedKeys = _allowedParameters[name] ?? const <String>{};
    if (values.keys.any((key) => !allowedKeys.contains(key))) {
      _debugFailure('Rejected non-allowlisted Analytics parameter');
      return;
    }
    await _silently(() => _analytics.logEvent(name: name, parameters: values));
  }

  Future<void> logOnce(String name) async {
    if (!isEnabled) return;
    if (_oncePerRun.contains(name)) return;
    _oncePerRun.add(name);
    await logEvent(name);
  }

  Future<void> trackScreen(String screenName) async {
    if (!isEnabled || screenName == _lastScreenName) return;
    _lastScreenName = screenName;
    await _silently(
      () => _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenName,
      ),
    );
  }

  Future<void> diaryFilterUsed(String filterType) async {
    if (!const {'month', 'date', 'range'}.contains(filterType)) return;
    await logEvent(
      'diary_filter_used',
      parameters: {'filter_type': filterType},
    );
  }

  Future<void> checkoutStarted(String planType) =>
      _logPlanEvent('subscription_checkout_started', planType);

  Future<void> subscriptionCompleted(String planType) =>
      _logPlanEvent('subscription_completed', planType);

  Future<void> _logPlanEvent(String event, String planType) async {
    if (!const {'monthly', 'yearly'}.contains(planType)) return;
    await logEvent(event, parameters: {'plan_type': planType});
  }

  Future<void> _silently(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (_) {
      _debugFailure('Analytics operation failed');
    }
  }

  void _debugFailure(String message) {
    if (kDebugMode) debugPrint(message);
  }
}

enum AnalyticsConsentStatus { unknown, granted, denied }
