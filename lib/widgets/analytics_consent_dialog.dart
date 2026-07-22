import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class AnalyticsConsentDialog extends StatelessWidget {
  const AnalyticsConsentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('analytics_consent.title'.tr()),
      content: Text('analytics_consent.message'.tr()),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('analytics_consent.not_now'.tr()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('analytics_consent.allow'.tr()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
