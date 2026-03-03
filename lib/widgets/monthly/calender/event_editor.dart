import 'package:flutter/material.dart';

class EventEditor extends StatefulWidget {
  final int year;
  final int month;
  final int day;
  final Map<String, dynamic> event;
  final VoidCallback onCancel;
  final VoidCallback onSaved;

  const EventEditor({
    super.key,
    required this.year,
    required this.month,
    required this.day,
    required this.event,
    required this.onCancel,
    required this.onSaved,
  });

  @override
  State<EventEditor> createState() => _EventEditorState();
}
class _EventEditorState extends State<EventEditor> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text("Edit event"),
          // resto do editor
        ],
      ),
    );
  }
}
