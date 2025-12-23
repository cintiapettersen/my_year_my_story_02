import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

String getLocalizedTipText(
  BuildContext context,
  Map<String, dynamic> tip,
) {
  final locale = context.locale.languageCode;

  if (locale == "en" &&
      tip["text_en"] != null &&
      tip["text_en"].toString().trim().isNotEmpty) {
    return tip["text_en"];
  }

  return tip["text"];
}
