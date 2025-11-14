import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:myyearmystory/models/monthly_goal_model.dart';
import 'package:myyearmystory/services/monthly_goal_service.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';

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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addGoal() async {
    final user = SupabaseConfig.client.auth.currentUser;
    final text = _goalController.text.trim();

    if (user == null) {
      AccessControl.showLoginPopup(context);
      return;
    }

    final isPremium = await AccessControl.checkPremiumStatus(user.id);

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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleGoal(MonthlyGoal goal) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      AccessControl.showLoginPopup(context);
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MonthPageTemplate(
      month: currentMonth,
      year: currentYear,
      title: 'monthly_goals.title'.tr(),
      description: 'monthly_goals.description'.tr(),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // 🌸 Campo + botão
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _goalController,
                          decoration: InputDecoration(
                            hintText: 'monthly_goals.add_goal_hint'.tr(),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300, width: 1),
                            ),
                          ),
                          onSubmitted: (_) => _addGoal(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _addGoal,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFE2377D),
                                Color(0xFFEA7ACD),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pink.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 🌸 Lista
                  if (_goals.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'monthly_goals.no_goals_yet'.tr(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: Colors.black54),
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
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: Checkbox(
                                value: goal.concluido,
                                onChanged: (_) => _toggleGoal(goal),
                                activeColor: const Color(0xFFE2377D),
                              ),
                              title: Text(
                                goal.conteudo,
                                style: TextStyle(
                                  decoration: goal.concluido
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  color: goal.concluido ? Colors.grey : Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteGoal(goal),
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
