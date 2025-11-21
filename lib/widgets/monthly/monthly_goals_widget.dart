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

  // 🌈 Cores das lixeiras (repetem em loop)
  final List<Color> trashColors = [
    Color(0xFFE57373), 
    Color(0xFFF06292),
    Color(0xFFBA68C8),
    Color(0xFF9575CD),
    Color(0xFF64B5F6),
    Color(0xFF4DD0E1),
    Color(0xFF4DB6AC),
    Color(0xFFAED581),
    Color(0xFFFF8A65),
    Color(0xFFFFB74D),
  ];

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

  // 🔄 Carregar metas
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
          SnackBar(content: Text('monthly_goals.error_load_goals'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ➕ Adicionar meta
  Future<void> _addGoal() async {
    final user = SupabaseConfig.client.auth.currentUser;
    final text = _goalController.text.trim();

    if (user == null) {
      AccessControl.showLoginPopup(context);
      return;
    }

    final isPremium = await AccessControl.checkPremiumStatus(user.id);

    if (!isPremium && _goals.length >= 3) {
      showPremiumPopup(context);
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
          SnackBar(content: Text('monthly_goals.goal_added'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('monthly_goals.error_add_goal'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✔️ Marcar meta concluída
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
          SnackBar(content: Text('monthly_goals.error_update_goal'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🗑️ Deletar meta
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
          SnackBar(content: Text('monthly_goals.goal_removed'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('monthly_goals.error_remove_goal'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🌸 UI
  @override
  Widget build(BuildContext context) {
    return MonthPageTemplate(
      month: currentMonth,
      year: currentYear,
      title: "",
      pageLabel: "monthly_goals.title".tr(),
      
      // 💚 Cor temporária (pode trocar quando quiser)
      labelColor: const Color.fromARGB(255, 237, 84, 181),

      description: "monthly_goals.description".tr(),

      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ➕ Campo adicionar meta
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _goalController,
                          decoration: InputDecoration(
                            hintText: "monthly_goals.add_goal_hint".tr(),
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
                          onSubmitted: (_) => _addGoal(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _addGoal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 139, 111, 196),
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

                  if (_goals.isEmpty)
                    _emptyState
                  else
                    _goalsList(),
                ],
              ),
            ),
    );
  }

  // 🌸 Estado vazio
  Widget get _emptyState => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            "monthly_goals.no_goals_yet".tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );

  // 🌸 Lista com lixeirinhas coloridas
  Widget _goalsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _goals.length,
      itemBuilder: (context, index) {
        final goal = _goals[index];

        return Container(
  margin: const EdgeInsets.only(bottom: 12),
  decoration: BoxDecoration(
    color: const Color(0xFFFDF0F4),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0xFFF3DCE4)),
  ),
  child: ListTile(
    dense: true, // 🔹 deixa o tile mais compacto
    visualDensity: const VisualDensity(
      horizontal: -3,
      vertical: -3, // 🔹 reduz bastante a altura sem perder conforto
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 10, // 🔹 bordas mais próximas
      vertical: 4, // 🔹 menos altura
    ),

    leading: Transform.translate(
      offset: const Offset(-4, 0), // 🔹 encosta mais o checkbox no canto
      child: Checkbox(
        value: goal.concluido,
        onChanged: (_) => _toggleGoal(goal),
        activeColor: const Color.fromARGB(255, 239, 77, 193),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // 🔹 diminui hitbox
      ),
    ),

    title: Text(
      goal.conteudo,
      style: TextStyle(
        fontSize: 14.5,       // 🔹 menorzinho
        height: 1.25,         // 🔹 linhas mais juntinhas
        fontWeight: FontWeight.w500,
        decoration: goal.concluido ? TextDecoration.lineThrough : null,
        color: goal.concluido ? Colors.grey : Colors.black87,
      ),
    ),

    trailing: Transform.translate(
      offset: const Offset(4, 0), // 🔹 encosta mais a lixeirinha no canto
      child: IconButton(
        icon: Icon(
          Icons.delete_rounded,
          color: trashColors[index % trashColors.length],
          size: 22, // 🔹 menorzinho pra combinar
        ),
        padding: EdgeInsets.zero, // 🔹 remove o espaço extra
        onPressed: () => _deleteGoal(goal),
      ),
    ),
  ),
);

      },
    );
  }
}
