import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:myyearmystory/models/monthly_goal_model.dart';
import 'package:myyearmystory/services/monthly_goal_service.dart';
import 'package:myyearmystory/services/daily_goal_service.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/screens/popups/popup_login.dart';


class MonthlyGoalsWidget extends StatefulWidget {
  final int month;
  final int year;

  const MonthlyGoalsWidget({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<MonthlyGoalsWidget> createState() => _MonthlyGoalsWidgetState();


}

class _MonthlyGoalsWidgetState extends State<MonthlyGoalsWidget> {
  final TextEditingController _monthlyController = TextEditingController();
  final TextEditingController _dailyController = TextEditingController();

  bool _isPremiumUser = false;
  int _currentTab = 0;
  static const Color _completedColor = Color(0xFFE2377D); // rosa vibrante


 bool get isGuest {
  return SupabaseConfig.client.auth.currentUser == null;
}



    // 🔒 Limites plano free
  static const int freeMonthlyLimit = 3;
  static const int freeDailyLimit = 5;


  List<MonthlyGoal> _monthlyGoals = [];
  Map<String, List<Map<String, dynamic>>> _dailyGoalsByDate = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _isPremiumUser = await AccessControl.isPremium();
    await _loadMonthlyGoals();
    await _loadDailyGoals();
  }

  
  // --------------------------------------------------
  // 📌 METAS DO MÊS
  // --------------------------------------------------
  Future<void> _loadMonthlyGoals() async {
    final goals = await MonthlyGoalService.getGoalsByMonth(
      mes: widget.month,
      ano: widget.year,
    );
    if (mounted) setState(() => _monthlyGoals = goals);
  }

  Future<void> _addDailyGoal() async {
  final text = _dailyController.text.trim();
  if (text.isEmpty) return;

  if (!_canAddDailyGoal()) return;

  await DailyGoalService.createGoal(
    date: DateTime.now(),
    content: text,
  );

  _dailyController.clear();
  await _loadDailyGoals();
}


Future<void> _addMonthlyGoal() async {
  final text = _monthlyController.text.trim();
  if (text.isEmpty) return;

  final user = SupabaseConfig.client.auth.currentUser;

  // 👤 não logado
  if (user == null) {
    showLoginPrompt(context);
    return;
  }

  // 🔒 limite plano free
  if (!_isPremiumUser && _monthlyGoals.length >= freeMonthlyLimit) {
    showPremiumPopup(context);
    return;
  }

  await MonthlyGoalService.createGoal(
    mes: widget.month,
    ano: widget.year,
    conteudo: text,
  );

  _monthlyController.clear();
  await _loadMonthlyGoals();
}


  // --------------------------------------------------
  // ☀️ METAS DO DIA
  // --------------------------------------------------
  Future<void> _loadDailyGoals() async {
    final goals = await DailyGoalService.getAllByMonth(
      month: widget.month,
      year: widget.year,
    );

    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final g in goals) {
      final dateKey = g['date'];
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(g);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final Map<String, List<Map<String, dynamic>>> sorted = {
      for (final k in sortedKeys) k: grouped[k]!,
    };

    if (mounted) setState(() => _dailyGoalsByDate = sorted);
  }

  

  String _formatDateLabel(String date) {
    final parts = date.split('-');
    return '${parts[2]}.${parts[1]}.${parts[0]}';
  }

  bool _isToday(String date) {
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return date == today;
  }


//. Helper para metas do DIA

bool _canAddDailyGoal() {
  final user = SupabaseConfig.client.auth.currentUser;

  // 👤 não logado
  if (user == null) {
    showLoginPrompt(context);
    return false;
  }

  // 🗓️ data de hoje
  final now = DateTime.now();
  final todayKey =
      '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';

  final todaysGoals = _dailyGoalsByDate[todayKey]?.length ?? 0;

  // 🔒 limite plano free (POR DIA)
  if (!_isPremiumUser && todaysGoals >= freeDailyLimit) {
    showPremiumPopup(context);
    return false;
  }

  return true;
}


  // --------------------------------------------------
  // 🌸 UI
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return MonthPageTemplate(
      month: widget.month,
      year: widget.year,
      title: '',
      pageLabel: 'monthly_goals.title'.tr(),
      labelColor: const Color(0xFFED54B5),
      description: 'monthly_goals.description'.tr(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tabs(),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _currentTab == 0
                  ? _monthlyGoalsContent()
                  : _dailyGoalsContent(),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // 🔀 Tabs
  // --------------------------------------------------
  // 🎨 Estilo das abas (edite aqui 👇)
final TextStyle tabTextStyle = const TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.4,
  fontFamily: 'poppins',
  // color NÃO entra aqui porque muda conforme ativo/inativo
);

	Widget _tabs() {
	  Widget tab(String text, int index) {
	    final active = _currentTab == index;
	    const accent = _MonthlyGoalsWidgetState._completedColor;

	    return GestureDetector(
	      onTap: () => setState(() => _currentTab = index),
	      child: Container(
	        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
	        decoration: BoxDecoration(
	          color: active ? accent : Colors.transparent,
	          borderRadius: BorderRadius.circular(12),
	          border: Border.all(
            color: active
                ? accent
                : const Color(0xFFE25BA6),
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
	              : [],
	        ),
	        child: Center(
	          child: Text(
	            text,
	            maxLines: 1,
	            overflow: TextOverflow.ellipsis,
	            softWrap: false,
	            style: tabTextStyle.copyWith(
	              color: active ? Colors.white : const Color(0xFFE25BA6),
	            ),
	          ),
	        ),
	      ),
	    );
	  }

	  return LayoutBuilder(
	    builder: (context, constraints) {
	      final isNarrow = constraints.maxWidth < 340;
	      return Row(
	        children: [
	          Expanded(
	            child: Padding(
	              padding: EdgeInsets.only(right: isNarrow ? 6 : 9),
	              child: tab('monthly_goals.tab_month'.tr(), 0),
	            ),
	          ),
	          Expanded(
	            child: Padding(
	              padding: EdgeInsets.only(left: isNarrow ? 6 : 0),
	              child: tab('monthly_goals.tab_day'.tr(), 1),
	            ),
	          ),
	        ],
	      );
	    },
	  );
	}

  // --------------------------------------------------
  // 📌 CONTEÚDO — METAS DO MÊS
  // --------------------------------------------------
  Widget _monthlyGoalsContent() {
  final active = _monthlyGoals.where((g) => !g.concluido).toList();
  final completed = _monthlyGoals.where((g) => g.concluido).toList();

  return Column(
    children: [
      Row(
        children: [
          Expanded(
	            child: TextField(
	              controller: _monthlyController,
	              autocorrect: true,
	              enableSuggestions: true,
	              smartQuotesType: SmartQuotesType.enabled,
	              smartDashesType: SmartDashesType.enabled,
	              decoration: InputDecoration(
	                hintText: 'monthly_goals.add_monthly'.tr(),
	                filled: true,
	                fillColor: Colors.white,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFE25BA6)),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.play_arrow_rounded,
              color: Color(0xFFE25BA6),
            ),
            onPressed: _addMonthlyGoal,
          ),
        ],
      ),

      const SizedBox(height: 16),

      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFCEAF4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌱 TEXTO QUANDO NÃO HÁ METAS
            if (active.isEmpty && completed.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'monthly_goals.empty'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),

            // 📌 METAS ATIVAS
            ...active.map(
              (goal) => _GoalTile(
                text: goal.conteudo,
                completed: false,
                onToggle: () async {
                  await MonthlyGoalService.updateGoal(
                    goalId: goal.id,
                    conteudo: goal.conteudo,
                    concluido: true,
                  );
                  await _loadMonthlyGoals();
                },
                onDelete: () async {
                  await MonthlyGoalService.deleteGoal(goal.id);
                  await _loadMonthlyGoals();
                },
              ),
            ),

            // ✅ CONCLUÍDOS
            if (completed.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'Concluídos',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              ...completed.map(
                (goal) => _GoalTile(
                  text: goal.conteudo,
                  completed: true,
                  onToggle: () async {
                    await MonthlyGoalService.updateGoal(
                      goalId: goal.id,
                      conteudo: goal.conteudo,
                      concluido: false,
                    );
                    await _loadMonthlyGoals();
                  },
                  onDelete: null,
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

  // --------------------------------------------------
  // ☀️ CONTEÚDO — METAS DO DIA
  // --------------------------------------------------
  Widget _dailyGoalsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
	              child: TextField(
	                controller: _dailyController,
	                autocorrect: true,
	                enableSuggestions: true,
	                smartQuotesType: SmartQuotesType.enabled,
	                smartDashesType: SmartDashesType.enabled,
	                decoration: InputDecoration(
	                  hintText: 'monthly_goals.add_daily'.tr(),
	                  filled: true,
	                  fillColor: Colors.white,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFE25BA6)),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) => _addDailyGoal(),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.play_arrow_rounded,
                color: Color(0xFFE25BA6),
              ),
              onPressed: _addDailyGoal,
            ),
          ],
        ),

        const SizedBox(height: 16),

        Column(
          children: _dailyGoalsByDate.entries.map((entry) {
            final date = entry.key;
            final goals = entry.value;

            final activeGoals =
                goals.where((g) => g['completed'] != true).toList();
            final completedGoals =
                goals.where((g) => g['completed'] == true).toList();

            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE25BA6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formatDateLabel(date),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_isToday(date)) ...[
                        const SizedBox(width: 8),
                        const Text(
                          'hoje',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE25BA6),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCEAF4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: activeGoals.map((goal) {
                        return _GoalTile(
                          text: goal['content'],
                          completed: false,
                          onToggle: () async {
                            await DailyGoalService.toggleCompleted(
                              goalId: goal['id'],
                              completed: true,
                            );
                            await _loadDailyGoals();
                          },
                          onDelete: () async {
                            await DailyGoalService.deleteGoal(
                                goal['id']);
                            await _loadDailyGoals();
                          },
                        );
                      }).toList(),
                    ),
                  ),

                  if (completedGoals.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const Text(
                      'Concluídos',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...completedGoals.map(
                      (goal) => _GoalTile(
                        text: goal['content'],
                        completed: true,
                        onToggle: () async {
                          await DailyGoalService.toggleCompleted(
                            goalId: goal['id'],
                            completed: false,
                          );
                          await _loadDailyGoals();
                        },
                        onDelete: null,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }



  @override
  void dispose() {
    _monthlyController.dispose();
    _dailyController.dispose();
    super.dispose();
  }
}

class _GoalTile extends StatelessWidget {
  final String text;
  final bool completed;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;

  const _GoalTile({
    required this.text,
    required this.completed,
    required this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const Color accent = _MonthlyGoalsWidgetState._completedColor;

    return AnimatedScale(
      scale: completed ? 1.0 : 0.95,
      duration: const Duration(milliseconds: 170),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: completed ? accent : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: completed ? accent : Colors.black.withOpacity(0.08),
            ),
            boxShadow: completed
                ? [
                    BoxShadow(
                      color: accent.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                completed ? Icons.star_rounded : Icons.radio_button_unchecked,
                color: completed ? Colors.white : const Color(0xFFE25BA6),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: completed ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (completed) ...[
                      const SizedBox(height: 4),
                      Text(
                        'monthly_goals.completed_message'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.92),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 10),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_rounded,
                    color: Color(0xFFB0B0B0),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
