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

  // Verifica eventos relevantes (pode haver mais de um no mesmo dia)
  final alerts = await _getRelevantAlertsForNow(now);
  if (alerts.isEmpty) return;

  for (final alert in alerts) {
    final alertId = (alert['id'] ?? '').toString().trim();
    if (alertId.isEmpty) continue;

    final perAlertKey = 'last_daily_notification_shown_$alertId';
    if (prefs.getString(perAlertKey) == todayKey) continue;

    if (!context.mounted) return;
    await DailyPopup.show(context, alert);

    await saveNotificationHistory(
      title: alert['title'],
      date: DateTime.now(),
    );

    await prefs.setString(perAlertKey, todayKey);
  }
}

/// ===========================================================
/// 🌸 Busca evento relevante baseado em repeatType / repeatDays
/// ===========================================================
const String _timeCapsuleColorHex = 'ff679bd3';

bool _isTimeCapsuleEvent(Map<String, dynamic> event) {
  final color = (event['color'] ?? '').toString().trim().toLowerCase();
  return color == _timeCapsuleColorHex;
}

Future<List<Map<String, dynamic>>> _getRelevantAlertsForNow(DateTime now) async {
  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) return [];

  final weekday = _weekdayKey(now.weekday);
  final today = _dateOnly(now);

  // Busca todos os eventos
  final allEvents = await SupabaseConfig.client
      .from('calendar_events')
      .select()
      .eq('user_id', user.id)
      .eq('remind', true);

  final List<Map<String, dynamic>> relevant = [];

  for (final event in allEvents) {
    final repeatType = event['repeat_type'] ?? 'none';
    final repeatDays = (event['repeat_days'] as List?)?.cast<String>() ?? [];
    final daysBefore = event['days_before'] ?? 0;
    final eventDate = DateTime(event['year'], event['month'], event['day']);
    final hour = (event['hour'] is int) ? (event['hour'] as int) : 9;

    // Dia alvo (quando o alerta começa a valer)
    final startDate = _dateOnly(eventDate.subtract(Duration(days: daysBefore)));

    // Não dispara antes do início
    if (today.isBefore(startDate)) continue;

    if (repeatType == 'daily') {
      final triggerTimeToday =
          DateTime(today.year, today.month, today.day, hour);
      if (now.isBefore(triggerTimeToday)) continue;
      relevant.add(event);
      continue;
    }

    if (repeatType == 'weekly') {
      if (repeatDays.contains(weekday)) {
        final triggerTimeToday =
            DateTime(today.year, today.month, today.day, hour);
        if (now.isBefore(triggerTimeToday)) continue;
        relevant.add(event);
      }
      continue;
    }

    if (repeatType == 'monthly') {
      if (eventDate.day == now.day) {
        final triggerTimeToday =
            DateTime(today.year, today.month, today.day, hour);
        if (now.isBefore(triggerTimeToday)) continue;
        relevant.add(event);
      }
      continue;
    }

    if (repeatType == 'yearly') {
      if (eventDate.day == now.day && eventDate.month == now.month) {
        final triggerTimeToday =
            DateTime(today.year, today.month, today.day, hour);
        if (now.isBefore(triggerTimeToday)) continue;
        relevant.add(event);
      }
      continue;
    }

    // Evento único
    if (repeatType == 'none') {
      if (_isTimeCapsuleEvent(event)) {
        // Cápsula do Tempo: mostra no dia definido ou no primeiro acesso depois do dia definido,
        // e continua aparecendo (1x por dia) até a pessoa marcar como lido.
        relevant.add(event);
        continue;
      }

      // Calendário: respeita o dia (startDate) e a hora configurada.
      if (!_isSameDay(startDate, today)) continue;
      final triggerTimeToday =
          DateTime(today.year, today.month, today.day, hour);
      if (now.isBefore(triggerTimeToday)) continue;
      relevant.add(event);
      continue;
    }
  }

  // Evita conflito: mostra alertas do calendário (com hora) primeiro, depois cápsula do tempo.
  relevant.sort((a, b) {
    final aIsCapsule = _isTimeCapsuleEvent(a);
    final bIsCapsule = _isTimeCapsuleEvent(b);
    if (aIsCapsule != bIsCapsule) return aIsCapsule ? 1 : -1;

    final aHour = (a['hour'] is int) ? (a['hour'] as int) : 9;
    final bHour = (b['hour'] is int) ? (b['hour'] as int) : 9;
    if (aHour != bHour) return aHour.compareTo(bHour);

    final aId = (a['id'] ?? '').toString();
    final bId = (b['id'] ?? '').toString();
    return aId.compareTo(bId);
  });

  return relevant;
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
