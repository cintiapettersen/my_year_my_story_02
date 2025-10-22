import 'package:flutter/material.dart';
import 'package:my_year_my_story/models/monthly_goal_model.dart';
import 'package:my_year_my_story/services/monthly_goal_service.dart';
import 'package:my_year_my_story/supabase/supabase_config.dart';
import 'package:my_year_my_story/widgets/monthly/monthly_page_template.dart';
import 'package:my_year_my_story/widgets/shared/show_login_prompt.dart'; // 🌸 Import do helper

class MonthlyGoalsWidget extends StatefulWidget {
  final int? month;
  final int? year;

  const MonthlyGoalsWidget({
    super.key,
    this.month,
    this.year,
  });

  @override
  State<MonthlyGoalsWidget> createState() => _MonthlyGoalsWidgetState();
}

class _MonthlyGoalsWidgetState extends State<MonthlyGoalsWidget> {
  final TextEditingController _goalController = TextEditingController();
  List<MonthlyGoal> _goals = [];
  bool _isLoading = false;

  late int currentMonth;
  late int currentYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    currentMonth = widget.month ?? now.month;
    currentYear = widget.year ?? now.year;
    _loadGoals();
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return; // 👈 convidado: não carrega nada

    setState(() => _isLoading = true);
    try {
      final goals = await MonthlyGoalService.getGoalsByMonth(
        currentMonth,
        currentYear,
        user.id,
      );
      setState(() => _goals = goals);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar metas: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addGoal() async {
    final user = SupabaseConfig.client.auth.currentUser;
    final text = _goalController.text.trim();

    print('🔎 Usuário atual: ${user?.id}');
// 🌷 se não estiver logado, mostra o aviso e interrompe
    if (user == null) {
      showLoginPrompt(context);
      return;
    }

    if (text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await MonthlyGoalService.createGoal(
        user.id,
        currentMonth,
        currentYear,
        text,
        false,
        DateTime.now(),
      );

      _goalController.clear();
      await _loadGoals();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meta adicionada com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar meta: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleGoal(MonthlyGoal goal) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showLoginPrompt(context);
      });
      return;
    }


    setState(() => _isLoading = true);
    try {
      await MonthlyGoalService.updateGoal(
        goal.id,
        goal.conteudo,
        !goal.concluido,
      );
      await _loadGoals();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar meta: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteGoal(MonthlyGoal goal) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      showLoginPrompt(context); // 🌸 avisa antes de excluir meta
      return;
    }

    setState(() => _isLoading = true);
    try {
      await MonthlyGoalService.deleteGoal(goal.id);
      await _loadGoals();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meta removida com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao remover meta: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MonthlyPageTemplate(
      month: currentMonth,
      year: currentYear,
      title: 'Metas do Mês',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _goalController,
                    decoration: const InputDecoration(
                      hintText: 'Digite sua nova meta...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addGoal(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addGoal,
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
            if (_goals.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'Nenhuma meta adicionada ainda.\nComece definindo suas metas para este mês!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _goals.length,
                itemBuilder: (context, index) {
                  final goal = _goals[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Checkbox(
                        value: goal.concluido,
                        onChanged: (_) => _toggleGoal(goal),
                        activeColor: Colors.purple,
                      ),
                      title: Text(
                        goal.conteudo,
                        style: TextStyle(
                          decoration: goal.concluido
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: goal.concluido
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteGoal(goal),
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
