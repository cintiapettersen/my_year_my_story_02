import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:easy_localization/easy_localization.dart';

class DailyPopup {
  static void show(BuildContext context, Map<String, dynamic> event) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _DailyPopupContent(event: event),
    );
  }
}

class _DailyPopupContent extends StatefulWidget {
  final Map<String, dynamic> event;

  const _DailyPopupContent({required this.event});

  @override
  State<_DailyPopupContent> createState() => _DailyPopupContentState();
}

class _DailyPopupContentState extends State<_DailyPopupContent> {
  final supabase = SupabaseConfig.client;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final colorHex = event['color'] ?? "FFe04cb7";
    final color = Color(int.parse(colorHex, radix: 16));

    return Center(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 26),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              color: const Color(0xFFFFE4EC).withOpacity(0.60),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1.3,
              ),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFF1F7).withOpacity(0.65),
                  const Color(0xFFFFD4E3).withOpacity(0.55),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.28),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 20, color: Colors.white),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.28),
                        ),
                        child: const Icon(
                          Icons.notifications_active,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Text(
                        event['title'] ?? "daily_popup.default_title".tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "daily_popup.subtitle".tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),

                      const SizedBox(height: 26),

                      ElevatedButton(
                        onPressed: () async {
                          await supabase
                              .from('calendar_events')
                              .update({'seen_today': true})
                              .eq('id', event['id']);

                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.25),
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          "daily_popup.mark_seen".tr(),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: () async {
                          await supabase
                              .from('calendar_events')
                              .update({'remind': false})
                              .eq('id', event['id']);

                          Navigator.pop(context);
                        },
                        child: Text(
                          "daily_popup.cancel_alert".tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
