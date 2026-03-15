import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:share_plus/share_plus.dart';

class DailyPopup {
  static Future<void> show(BuildContext context, Map<String, dynamic> event) {
    return showDialog<void>(
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
  final GlobalKey _shareKey = GlobalKey();

  static const String _timeCapsuleColorHex = 'ff679bd3';

  bool _isTimeCapsule(Map<String, dynamic> event) {
    final color = (event['color'] ?? '').toString().trim().toLowerCase();
    return color == _timeCapsuleColorHex;
  }

  Future<void> _shareAsImage() async {
    final ctx = _shareKey.currentContext;
    if (ctx == null) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final boundary = ctx.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      await Share.shareXFiles(
        [
          XFile.fromData(
            pngBytes,
            mimeType: 'image/png',
            name: 'alert.png',
          ),
        ],
        text: 'daily_popup.share_caption'.tr(),
      );
    } catch (_) {
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(
          content: Text('daily_popup.share_error'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final colorHex = event['color'] ?? "FFe04cb7";
    final color = Color(int.parse(colorHex, radix: 16));
    final isTimeCapsule = _isTimeCapsule(event);

    return Center(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 26),
          child: RepaintBoundary(
            key: _shareKey,
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

                      const SizedBox(height: 12),

                      if ((event['description'] ?? '').toString().trim().isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                            ),
                          ),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Text(
                              event['description'].toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.45,
                                color: Colors.white.withOpacity(0.95),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      else
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
                        onPressed: _shareAsImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.18),
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          "daily_popup.share".tr(),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),

                      const SizedBox(height: 12),

                      ElevatedButton(
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          if (isTimeCapsule) {
                            await supabase
                                .from('calendar_events')
                                .update({'remind': false})
                                .eq('id', event['id']);
                          }

                          if (!mounted) return;
                          navigator.pop();
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
                          isTimeCapsule
                              ? "daily_popup.mark_seen".tr()
                              : "daily_popup.close".tr(),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          await supabase
                              .from('calendar_events')
                              .update({'remind': false})
                              .eq('id', event['id']);

                          if (!mounted) return;
                          navigator.pop();
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
      ),
    );
  }
}
