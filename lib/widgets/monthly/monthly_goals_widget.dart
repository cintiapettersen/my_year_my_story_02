import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:my_year_my_story/models/monthly_goal_model.dart';
import 'package:my_year_my_story/services/monthly_goal_service.dart';
import 'package:my_year_my_story/supabase/supabase_config.dart';
import 'package:my_year_my_story/widgets/monthly/monthly_page_template.dart';
import 'package:my_year_my_story/utils/access_control.dart';
import 'package:my_year_my_story/screens/premium/premium_popup.dart'; // usamos showPremiumPrompt()

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
    if (user == null) return;

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
          SnackBar(content: Text('error_load_goals'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addGoal() async {
    final user = SupabaseConfig.client.auth.currentUser;
    final text = _goalController.text.trim();

    // 🌸 convidado → popup de login
    if (user == null) {
      AccessControl.showLoginPopup(context);
      return;
    }

    // 💎 verifica status premium
    final isPremium = await AccessControl.checkPremiumStatus(user.id);

    // 🌸 usuário free e já tem 5 metas → mostra popup premium
    if (!isPremium && _goals.length >= 5) {
      showPremiumPrompt(context, month: currentMonth, year: currentYear);
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
          SnackBar(content: Text('goal_added'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_add_goal'.tr())),
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
        AccessControl.showLoginPopup(context);
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
          SnackBar(content: Text('error_update_goal'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteGoal(MonthlyGoal goal) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      AccessControl.showLoginPopup(context);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await MonthlyGoalService.deleteGoal(goal.id);
      await _loadGoals();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('goal_removed'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_remove_goal'.tr())),
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
      title: 'monthly_goals_title'.tr(),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌸 Descrição inspiracional
            Text(
              'monthly_goals_description'.tr(),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),

            // 🌸 Campo nova meta
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _goalController,
                    decoration: InputDecoration(
                      hintText: 'add_goal_hint'.tr(),
                      border: const OutlineInputBorder(),
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

            // 🌸 Lista de metas
            if (_goals.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'no_goals_yet'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
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
