import 'package:flutter/material.dart';
import 'package:myyearmystory/services/gratitude_service.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:myyearmystory/screens/popups/popup_login.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:easy_localization/easy_localization.dart';

class GratitudeWidget extends StatefulWidget {
  final int month;
  final int year;

  const GratitudeWidget({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<GratitudeWidget> createState() => _GratitudeWidgetState();
}

class _GratitudeWidgetState extends State<GratitudeWidget> {
  final TextEditingController _controller = TextEditingController();
  List<String> _gratitudes = [];
  bool _isLoading = false;
  bool _isPremiumUser = false;

  final List<Color> trashColors = const [
    Color(0xFFcdd8e8),
    Color(0xFFe04cb7),
    Color(0xFFdbaf35),
    Color(0xFF679bd3),
    Color(0xFFcf8ee8),
    Color(0xFFbeb6f2),
    Color(0xFF776fb5),
    Color(0xFFd83d78),
    Color(0xFFb71691),
    Color(0xFFc48c00),
    Color(0xFF3983c6),
    Color(0xFF9a5dba),
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _isPremiumUser = await AccessControl.isPremium();
    await _loadGratitudes();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ❤️ animação do coração
  void _showHeartAnimation() {
    final overlay = Overlay.of(context);

    final randomX = MediaQuery.of(context).size.width *
        (0.2 + (0.6 * (DateTime.now().millisecond % 100) / 100));

    final colors = [
      Colors.pinkAccent,
      Colors.purpleAccent,
      Colors.redAccent,
      Colors.orangeAccent,
      Colors.deepPurpleAccent,
    ];

    final color = colors[DateTime.now().millisecond % colors.length];

    final entry = OverlayEntry(
      builder: (_) => _HeartFloating(
        startX: randomX,
        color: color,
      ),
    );

    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 2), entry.remove);
  }

  Future<void> _loadGratitudes() async {
    setState(() => _isLoading = true);

    final list = await GratitudeService.getGratitudeList(
      widget.month,
      widget.year,
    );

    if (!mounted) return;

    setState(() {
      _gratitudes = list;
      _isLoading = false;
    });
  }

  Future<void> _addGratitude() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      showLoginPrompt(context);
      return;
    }

    if (!_isPremiumUser && _gratitudes.length >= 3) {
      showPremiumPopup(context);
      return;
    }

    setState(() => _isLoading = true);

    final newList = [..._gratitudes, text];
    final success = await GratitudeService.saveGratitudeList(
      newList,
      widget.month,
      widget.year,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (!success) {
      showLoginPrompt(context);
      return;
    }

    _controller.clear();
    setState(() => _gratitudes = newList);

    _showHeartAnimation();

    ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    backgroundColor: const Color(0xFFFDF0F4), // rosa clarinho
    content: Text(
      'gratitude.added'.tr(),
      style: const TextStyle(color: Colors.black),
    ),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
);
  }

  Future<void> _deleteGratitude(int index) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      showLoginPrompt(context);
      return;
    }

    setState(() => _isLoading = true);

    final newList = List<String>.from(_gratitudes)..removeAt(index);
    final success = await GratitudeService.saveGratitudeList(
      newList,
      widget.month,
      widget.year,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (!success) {
      showLoginPrompt(context);
      return;
    }

    setState(() => _gratitudes = newList);

   ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    backgroundColor: const Color(0xFFFDF0F4), // rosa clarinho
    content: Text(
      'gratitude.removed'.tr(),
      style: const TextStyle(color: Colors.black),
    ),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
);

  }

  @override
  Widget build(BuildContext context) {
    return MonthPageTemplate(
      month: widget.month,
      year: widget.year,
      title: "",
      pageLabel: "gratitude.page_label".tr(),
      labelColor: const Color.fromARGB(255, 244, 185, 210),
      description: "gratitude.description".tr(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'gratitude.hint'.tr(),
                      hintStyle: const TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (_) => _addGratitude(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addGratitude,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC03B66),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.add, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_gratitudes.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'gratitude.empty'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _gratitudes.length,
                itemBuilder: (context, index) {
                  final text = _gratitudes[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF0F4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF3DCE4)),
                    ),
                    child: ListTile(
                      dense: true,
                      visualDensity: const VisualDensity(
                        horizontal: -3,
                        vertical: -3,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      title: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 14.5,
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete_rounded,
                          color: trashColors[index % trashColors.length],
                          size: 22,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () => _deleteGratitude(index),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ❤️ Coraçãozinho animado
class _HeartFloating extends StatefulWidget {
  final double startX;
  final Color color;

  const _HeartFloating({
    required this.startX,
    required this.color,
  });

  @override
  State<_HeartFloating> createState() => _HeartFloatingState();
}

class _HeartFloatingState extends State<_HeartFloating> {
  double top = 600;
  double opacity = 1;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 30), () {
      setState(() {
        top = 200;
        opacity = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.startX,
      top: top,
      child: AnimatedOpacity(
        duration: const Duration(seconds: 2),
        opacity: opacity,
        child: AnimatedContainer(
          duration: const Duration(seconds: 2),
          curve: Curves.easeOut,
          child: Icon(
            Icons.favorite,
            size: 42,
            color: widget.color.withOpacity(0.85),
          ),
        ),
      ),
    );
  }
}
