import 'package:flutter/material.dart';
import 'package:my_year_my_story/services/gratitude_service.dart';
import 'package:my_year_my_story/supabase/supabase_config.dart';
import 'package:my_year_my_story/widgets/shared/month_page_template.dart'; // 🌸 novo template

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

    if (user == null || text.isEmpty) return;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gratidão adicionada com sucesso!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar gratidão.')),
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
          const SnackBar(content: Text('Gratidão removida com sucesso!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao remover gratidão.')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return MonthPageTemplate( // 🌸 novo template unificado
      month: widget.month,
      year: widget.year,
      title: 'Página da Gratidão',
      description: 'Registre as coisas boas que aconteceram neste mês 💖',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Sou grato por...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addGratitude(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addGratitude,
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_gratitudes.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'Nenhum registro de gratidão ainda.\nComece registrando algo pelo qual você é grato este mês!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
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
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(text),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
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
