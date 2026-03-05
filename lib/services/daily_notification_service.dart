import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myyearmystory/services/alerts_history_service.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/screens/notifications/daily_popup.dart';

/// ===========================================================
/// 🌸 Função chamada sempre que o app abre o Dashboard
/// ===========================================================
Future<void> showDailyNotification(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final now = DateTime.now();
  final todayKey = _dateKey(now);

  // Evita mostrar mais de uma vez no mesmo dia
  if (prefs.getString('last_daily_notification') == todayKey) return;

  // Verifica eventos relevantes
  final alert = await _getRelevantAlertForToday(now);

  if (alert != null) {
    if (!context.mounted) return;
    DailyPopup.show(context, alert);

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
Future<Map<String, dynamic>?> _getRelevantAlertForToday(DateTime now) async {
  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) return null;

  final weekday = _weekdayKey(now.weekday);
  final today = _dateOnly(now);

  // Busca todos os eventos
  final allEvents = await SupabaseConfig.client
      .from('calendar_events')
      .select()
      .eq('user_id', user.id)
      .eq('remind', true);

  for (final event in allEvents) {
    final repeatType = event['repeat_type'] ?? 'none';
    final repeatDays = (event['repeat_days'] as List?)?.cast<String>() ?? [];
    final daysBefore = event['days_before'] ?? 0;
    final eventDate = DateTime(event['year'], event['month'], event['day']);

    // Dia alvo (quando o alerta começa a valer)
    final startDate = _dateOnly(eventDate.subtract(Duration(days: daysBefore)));

    // Não dispara antes do início
    if (today.isBefore(startDate)) continue;

    if (repeatType == 'daily') {
      return event;
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
      if (_isSameDay(startDate, today)) return event;
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

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

String _dateKey(DateTime dt) =>
    '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
