import 'package:flutter/material.dart';
import 'package:myyearmystory/services/gratitude_service.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:myyearmystory/widgets/shared/show_login_prompt.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';

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

  // 🌈 Lixeirinhas arco-íris (12 cores)
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
    _loadGratitudes();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------
  // ❤️‍🔥 ANIMAÇÃO DOS CORAÇÕES FOFOS SUBINDO
  // ---------------------------------------------------------
  void _showHeartAnimation() {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final randomX = (MediaQuery.of(context).size.width *
        (0.2 + (0.6 * (DateTime.now().millisecond % 100) / 100)));

    final colors = [
      Colors.pinkAccent,
      Colors.purpleAccent,
      Colors.redAccent,
      Colors.orangeAccent,
      Colors.deepPurpleAccent,
    ];

    final color = colors[DateTime.now().millisecond % colors.length];

    final entry = OverlayEntry(
      builder: (context) {
        return _HeartFloating(
          startX: randomX,
          color: color,
        );
      },
    );

    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 2), () {
      entry.remove();
    });
  }

  // ---------------------------------------------------------

  Future<void> _loadGratitudes() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    final list = await GratitudeService.getGratitudeList(
      widget.month,
      widget.year,
      user.id,
    );

    setState(() {
      _gratitudes = list;
      _isLoading = false;
    });
  }

  Future<void> _addGratitude() async {
    final user = SupabaseConfig.client.auth.currentUser;
    final text = _controller.text.trim();

    if (user == null) {
      showLoginPrompt(context);
      return;
    }

    if (text.isEmpty) return;

    final profile = await SupabaseConfig.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    final userProfile = profile ?? {'plan_type': 'guest'};
    final isPremium = AccessControl.isPremium(userProfile);
    final isFree = AccessControl.isFree(userProfile);

    if (isFree && _gratitudes.length >= 3) {
      showPremiumPopup(context);
      return;
    }

    setState(() => _isLoading = true);

    final newList = [..._gratitudes, text];
    final success = await GratitudeService.saveGratitudeList(
      newList,
      widget.month,
      widget.year,
      user.id,
    );

    if (success) {
      _controller.clear();
      setState(() => _gratitudes = newList);

      // 💖 dispara o coraçãozinho fofo!
      _showHeartAnimation();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gratidão adicionada! 💖')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar. 😞')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _deleteGratitude(int index) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    final newList = List<String>.from(_gratitudes)..removeAt(index);

    setState(() => _isLoading = true);

    final success = await GratitudeService.saveGratitudeList(
      newList,
      widget.month,
      widget.year,
      user.id,
    );

    if (success) {
      setState(() => _gratitudes = newList);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item removido!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao remover.')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return MonthPageTemplate(
      month: widget.month,
      year: widget.year,
      title: "",
      pageLabel: "Página da Gratidão",
      labelColor: const Color(0xFFe2377d),
      description:
          "A gratidão nos ajuda a enxergar o lado bom da vida e fortalecer o coração. Registre as coisas boas que aconteceram neste mês 💖",

      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ➕ Campo de adicionar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Sou grato por...',
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
                        onPressed: _isLoading ? null : _addGratitude,
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
                      child: const Center(
                        child: Text(
                          'Nenhum registro ainda.\nComece adicionando algo pelo qual você é grato 💛',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey),
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
                            border:
                                Border.all(color: const Color(0xFFF3DCE4)),
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
                                color: Colors.black87,
                              ),
                            ),
                            trailing: Transform.translate(
                              offset: const Offset(4, 0),
                              child: IconButton(
                                icon: Icon(
                                  Icons.delete_rounded,
                                  color: trashColors[
                                      index % trashColors.length],
                                  size: 22,
                                ),
                                padding: EdgeInsets.zero,
                                onPressed: () => _deleteGratitude(index),
                              ),
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



// ----------------------------------------------------------------------
// ❤️ WIDGET DO CORAÇÃO FLUTUANTE
// ----------------------------------------------------------------------
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
