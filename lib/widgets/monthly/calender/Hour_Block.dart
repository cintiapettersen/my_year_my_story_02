import 'package:flutter/material.dart';

import 'package:easy_localization/easy_localization.dart';

class HourBlock extends StatelessWidget {
  final int hour;
  final List<Map<String, dynamic>> entries;
  final VoidCallback onAdd;
  final Function(Map<String, dynamic>) onEdit;
  final Function(String entryId) onDelete;

  const HourBlock({
    super.key,
    required this.hour,
    required this.entries,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final label = "${hour.toString().padLeft(2, '0')}:00";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // 🔑 fundo sólido
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),

          if (entries.isEmpty)
            GestureDetector(
              onTap: onAdd,
              child: Text(
                "agenda.tap_to_add_note".tr(),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          if (entries.isNotEmpty)
            ...entries.map(
              (e) => GestureDetector(
                onTap: () => onEdit(e),
                onLongPress: () {
                  final id = e['id'];
                  if (id != null) {
                    onDelete(id.toString());
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    "• ${e['note']}",
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
