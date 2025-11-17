// 🎀 MonthlyGoalsWidget — agora com etiqueta fofinha igual às outras páginas 🎀

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

  // 🧁 Paleta suave aleatória para as lixeirinhas
  final List<Color> cuteTrashColors = const [
    Color.fromARGB(255, 229, 89, 142),
    Color.fromARGB(255, 105, 183, 216),
    Color.fromARGB(255, 208, 176, 95),
    Color.fromARGB(255, 159, 135, 209),
    Color.fromARGB(255, 113, 88, 150),
    Color.fromARGB(255, 120, 43, 84),
  ];

  // 🎨 Cores por mês (para borda da caixa de texto)
  final Map<int, Color> monthColors = {
    1: Color(0xFFF8DDE1),
    2: Color(0xFFE25BA6),
    3: Color(0xFFD8B24F),
    4: Color(0xFF7EA6D9),
    5: Color(0xFFC9A6E5),
    6: Color(0xFFBDB6E3),
    7: Color(0xFF7476B8),
    8: Color(0xFF893950),
    9: Color(0xFFA63484),
    10: Color(0xFFC29532),
    11: Color(0xFF4A86C6),
    12: Color(0xFF9370C8),
  };

  @override
  Widget build(BuildContext context) {
    final Color monthColor = monthColors[currentMonth] ?? Colors.pink;

    return MonthPageTemplate(
      month: currentMonth,
      year: currentYear,   
      /// ⛔ PRECISA existir (é obrigatório)
  /// ✔️ MAS vazio para não exibir no banner
  title: '',

  pageLabel: 'monthly_goals.title'.tr(),
  labelColor: const Color.fromARGB(255, 238, 33, 173),
 
      description: 'monthly_goals.description'.tr(),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

               
                const SizedBox(height: 6),

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

                          // 📌 Altura e bordas restauradas
                          isDense: false,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 16),

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: monthColor, width: 1.2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: monthColor, width: 1.4),
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
                          color: monthColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 🌸 Lista de metas
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
                        style:
                            const TextStyle(fontSize: 16, color: Colors.black54),
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

                      // 🌈 Define cor estável por item usando índice
                      final cuteTrashColor =
                          cuteTrashColors[index % cuteTrashColors.length];

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Checkbox(
                                value: goal.concluido,
                                onChanged: (_) => _toggleGoal(goal),
                                activeColor: monthColor,
                              ),

                              Expanded(
                                child: Text(
                                  goal.conteudo,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.3,
                                    decoration: goal.concluido
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                    color: goal.concluido
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                              ),

                              IconButton(
                                icon: Icon(Icons.delete, color: cuteTrashColor),
                                onPressed: () => _deleteGoal(goal),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
    );
  }
}
