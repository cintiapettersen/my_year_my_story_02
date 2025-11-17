import 'package:flutter/material.dart';
import 'package:myyearmystory/widgets/shared/app_bottom_menu.dart';
import 'package:myyearmystory/widgets/shared/month_header.dart';
import 'package:myyearmystory/utils/label_colors.dart';

/// 🌸 Template base para as páginas mensais do app
class MonthPageTemplate extends StatefulWidget {
  final int month;
  final int year;
  final String title;
  final String? description;

  /// ⭐ Etiqueta exibida no banner
  final String? pageLabel;

  /// ❌ REMOVIDO: não precisamos mais receber labelColor manualmente
  final Color? labelColor;

  /// 🌟 Controle: usar ou não o card com sombra ao redor
  final bool useScaffoldContainer;

  final Widget child;

  const MonthPageTemplate({
    super.key,
    required this.month,
    required this.year,
    required this.title,
    this.description,
    this.pageLabel,
    this.labelColor,
    this.useScaffoldContainer = true,
    required this.child,
  });

  @override
  State<MonthPageTemplate> createState() => _MonthPageTemplateState();
}

class _MonthPageTemplateState extends State<MonthPageTemplate> {
  Future<void> _playClick() async {
    try {} catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final hasScaffold = Scaffold.maybeOf(context) != null;




    final Map<String, Color> labelColors = {
  'Metas do Mês': Color(0xFFE18B50),
  'Sobre Mim': Color(0xFF9CBC68),
  'Quiz Interativo': Color(0xFFA07756),
  'Signos do Mês': Color(0xFFD072CC),
  'Dicas do Mês': Color(0xFFA8C5DB),
  'Entrevista': Color(0xFFE9B9C9),
  'Minhas Listas': Color(0xFFE18B50),
  'Página da Gratidão': Color(0xFF7BA5D7),
  'Reflexões': Color(0xFFC03B66),
  'Fotos do Mês': Color(0xFFA07756),
  'Sorte do Dia': Color(0xFF9CBC68),
};

    /// 🌈 1) Resolve automaticamente a cor da etiqueta
    final Color resolvedLabelColor =
    labelColors[widget.pageLabel] ?? Colors.black26;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        /// 🩵 Cabeçalho com banner e etiqueta dinâmica
        MonthHeader(
          month: widget.month,
          year: widget.year,
          title: widget.title,
          pageLabel: widget.pageLabel,
          labelColor: resolvedLabelColor, // 🌈 AGORA SEMPRE CORRETO
        ),

        const SizedBox(height: 12),

        /// ✨ Descrição (opcional)
        if (widget.description != null && widget.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
            child: Column(
              children: [
                Text(
                  widget.description!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 1,
                  color: Color(0xFFE9B9C9),
                  margin: EdgeInsets.symmetric(horizontal: 12),
                ),
              ],
            ),
          ),

        /// 🌸 Conteúdo principal
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: GestureDetector(
              onTapDown: (_) => _playClick(),
              behavior: HitTestBehavior.translucent,
              child: widget.child,
            ),
          ),
        ),
      ],
    );

    /// 🌟 Se já houver Scaffold PAI **ou** se o card não for desejado
    if (hasScaffold || !widget.useScaffoldContainer) {
      return content;
    }

    /// 🌟 Caso contrário, aplica o card com sombra linda
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE2377D),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Year, My Story',
          style: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: content,
        ),
      ),
      bottomNavigationBar: const AppBottomMenu(currentIndex: 1),
    );
  }
}
