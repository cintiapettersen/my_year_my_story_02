import 'package:flutter/material.dart';

class MonthlyCalendar extends StatelessWidget {
  final Function(int)? onMonthTap;
  
  const MonthlyCalendar({super.key, this.onMonthTap});

  @override
  Widget build(BuildContext context) {
    final currentMonth = DateTime.now().month;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${DateTime.now().year}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Icon(
                Icons.calendar_today,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final monthIndex = index + 1;
              final isCurrentMonth = monthIndex == currentMonth;
              final monthName = _getMonthName(monthIndex);
              
              return GestureDetector(
                onTap: () => onMonthTap?.call(monthIndex) ?? _navigateToMonth(context, monthIndex),
                child: Container(
                  decoration: BoxDecoration(
                    color: isCurrentMonth 
                        ? Theme.of(context).primaryColor
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: isCurrentMonth 
                        ? null 
                        : Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        monthName.substring(0, 3).toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCurrentMonth 
                              ? Colors.white 
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        monthIndex.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isCurrentMonth 
                              ? Colors.white 
                              : Theme.of(context).primaryColor,
                        ),
                      ),
                      if (isCurrentMonth) ...[
                        const SizedBox(height: 2),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
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

  String _getMonthName(int month) {
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return months[month - 1];
  }

  void _navigateToMonth(BuildContext context, int month) {
    // TODO: Navigate to specific month screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navegando para ${_getMonthName(month)}...'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}