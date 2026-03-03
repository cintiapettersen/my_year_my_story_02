import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myyearmystory/services/alerts_history_service.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';

/// ===========================================================
/// 🌸 Função chamada sempre que o app abre o Dashboard
/// ===========================================================
Future<void> showDailyNotification(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final today = DateTime.now();
  final todayKey = today.toIso8601String().substring(0, 10);

  // Evita mostrar mais de uma vez no mesmo dia
  if (prefs.getString('last_daily_notification') == todayKey) return;

  // Verifica eventos relevantes
  final alert = await _getRelevantAlertForToday();

  if (alert != null) {
    await _showAlertPopup(context, alert['title']);

    await saveNotificationHistory(
      title: alert['title'],
      date: DateTime.now(),
    );
  }

  // Marca como exibido hoje
  await prefs.setString('last_daily_notification', todayKey);
}

/// ===========================================================
/// 🌸 Busca evento relevante baseado em repeatType / repeatDays
/// ===========================================================
Future<Map<String, dynamic>?> _getRelevantAlertForToday() async {
  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) return null;

  final now = DateTime.now();
  final weekday = _weekdayKey(now.weekday);

  // Busca todos os eventos
  final allEvents = await SupabaseConfig.client
      .from('calendar_events')
      .select()
      .eq('user_id', user.id);

  for (final event in allEvents) {
    final repeatType = event['repeat_type'] ?? 'none';
    final repeatDays = (event['repeat_days'] as List?)?.cast<String>() ?? [];
    final daysBefore = event['days_before'] ?? 0;
    final eventDate = DateTime(event['year'], event['month'], event['day']);

    // Dia alvo
    final targetDate = eventDate.subtract(Duration(days: daysBefore));

    if (repeatType == 'daily') {
      if (_isSameDay(targetDate, now)) return event;
    }

    if (repeatType == 'weekly') {
      if (repeatDays.contains(weekday)) return event;
    }

    if (repeatType == 'monthly') {
      if (eventDate.day == now.day) return event;
    }

    if (repeatType == 'yearly') {
      if (eventDate.day == now.day && eventDate.month == now.month) {
        return event;
      }
    }

    // Evento único
    if (repeatType == 'none') {
      if (_isSameDay(targetDate, now)) return event;
    }
  }

  return null;
}

/// ===========================================================
/// 🌸 Converte weekday pro formato usado nos repeatDays
/// ===========================================================
String _weekdayKey(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return "Mon";
    case DateTime.tuesday:
      return "Tue";
    case DateTime.wednesday:
      return "Wed";
    case DateTime.thursday:
      return "Thu";
    case DateTime.friday:
      return "Fri";
    case DateTime.saturday:
      return "Sat";
    case DateTime.sunday:
      return "Sun";
    default:
      return "";
  }
}

/// ===========================================================
/// 🌸 Compara datas ignorando horas
/// ===========================================================
bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// ===========================================================
/// 🌸 Popup exibido ao abrir o app — com “Marcar como visto”
/// ===========================================================
Future<void> _showAlertPopup(BuildContext context, String title) async {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          "✨ $title",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Você tem um lembrete importante hoje 💗",
        ),
        actions: [
          // MARCAR COMO VISTO
          TextButton(
            onPressed: () {
              context.pop(); // fecha popup
            },
            child: const Text(
              "Marcar como visto",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          // BOTÃO OK
          TextButton(
            onPressed: () {
              context.pop(); // fecha popup
            },
            child: const Text(
              "OK",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    },
  );
}
