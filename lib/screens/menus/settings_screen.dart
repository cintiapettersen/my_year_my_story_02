import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:myyearmystory/services/analytics_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyDataScreen extends StatefulWidget {
  const PrivacyDataScreen({super.key});

  @override
  State<PrivacyDataScreen> createState() => _PrivacyDataScreenState();
}

class _PrivacyDataScreenState extends State<PrivacyDataScreen> {
  static final Uri _privacyPolicyUri = Uri.parse(
    'https://sonhodepapel.com/my-year-my-story-policy/',
  );

  bool _saving = false;

  Future<void> _setAnalyticsEnabled(bool enabled) async {
    if (_saving) return;
    setState(() => _saving = true);
    await AnalyticsService.instance.setConsent(enabled);
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _openPrivacyPolicy() async {
    await launchUrl(_privacyPolicyUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE9EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE04CB7),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('privacy_data.title'.tr()),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'privacy_data.introduction'.tr(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF624B59),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: ValueListenableBuilder<AnalyticsConsentStatus>(
                  valueListenable: AnalyticsService.instance.consent,
                  builder: (context, status, _) {
                    return SwitchListTile.adaptive(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      secondary: const Icon(
                        Icons.analytics_outlined,
                        color: Color(0xFFE04CB7),
                      ),
                      title: Text('analytics_settings.title'.tr()),
                      subtitle: Text('analytics_settings.description'.tr()),
                      value: status == AnalyticsConsentStatus.granted,
                      onChanged: _saving ? null : _setAnalyticsEnabled,
                      activeThumbColor: const Color(0xFFE04CB7),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: const Icon(
                  Icons.privacy_tip_outlined,
                  color: Color(0xFFE04CB7),
                ),
                title: Text('privacy_data.policy_link'.tr()),
                trailing: const Icon(Icons.open_in_new, size: 20),
                onTap: _openPrivacyPolicy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
