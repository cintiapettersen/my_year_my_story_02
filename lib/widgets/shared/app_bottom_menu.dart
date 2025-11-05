import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

// 🌸 Import das telas principais
import 'package:my_year_my_story/screens/dashboard/dashboard_screen.dart';
import 'package:my_year_my_story/screens/monthly/current_month_screen.dart';
import 'package:my_year_my_story/screens/diary/diary_screen.dart';
import 'package:my_year_my_story/screens/mood/mood_screen.dart';
import 'package:my_year_my_story/widgets/monthly/dailyluckpage.dart';
 // 🍀 nova tela da sorte

class AppBottomMenu extends StatelessWidget {
  final int currentIndex;

  const AppBottomMenu({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final int currentMonth = now.month;
    final int currentYear = now.year;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            if (index == currentIndex) return;

            Widget nextScreen;
            switch (index) {
              case 0:
                nextScreen = DashboardScreen(month: currentMonth, year: currentYear);
                break;
              case 1:
                nextScreen = const CurrentMonthScreen();
                break;
              case 2:
                nextScreen = const DailyLuckPage(); // 🍀 substituindo Fotos por Sorte
                break;
              case 3:
                nextScreen = const DiaryScreen();
                break;
              case 4:
                nextScreen = MoodScreen(month: currentMonth, year: currentYear);
                break;
              default:
                return;
            }

            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => nextScreen,
                transitionDuration: const Duration(milliseconds: 300),
                transitionsBuilder: (_, anim, __, child) => FadeTransition(
                  opacity: anim,
                  child: child,
                ),
              ),
            );
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFFE32278),
          selectedItemColor: const Color(0xFFFFB500),
          unselectedItemColor: Colors.white,
          showUnselectedLabels: true,
          elevation: 0,
          items: [
            _buildItem(
              context,
              index: 0,
              currentIndex: currentIndex,
              icon: PhosphorIconsRegular.house,
              activeIcon: PhosphorIconsFill.house,
              label: 'bottom.home'.tr(),
            ),
            _buildItem(
              context,
              index: 1,
              currentIndex: currentIndex,
              icon: PhosphorIconsRegular.calendarBlank,
              activeIcon: PhosphorIconsFill.calendarBlank,
              label: 'bottom.current_month'.tr(),
            ),
            _buildItem(
              context,
              index: 2,
              currentIndex: currentIndex,
              icon: PhosphorIconsRegular.clover, // 🍀 novo ícone da sorte
              activeIcon: PhosphorIconsFill.clover,
              label: 'Sorte do Dia', // pode traduzir depois se quiser
            ),
            _buildItem(
              context,
              index: 3,
              currentIndex: currentIndex,
              icon: PhosphorIconsRegular.bookOpenText,
              activeIcon: PhosphorIconsFill.bookOpenText,
              label: 'bottom.diary'.tr(),
            ),
            _buildItem(
              context,
              index: 4,
              currentIndex: currentIndex,
              icon: PhosphorIconsRegular.smiley,
              activeIcon: PhosphorIconsFill.smiley,
              label: 'bottom.mood'.tr(),
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildItem(
      BuildContext context, {
        required int index,
        required int currentIndex,
        required IconData icon,
        required IconData activeIcon,
        required String label,
      }) {
    final bool isActive = index == currentIndex;

    return BottomNavigationBarItem(
      label: label,
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutQuad,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Icon(
          isActive ? activeIcon : icon,
          size: isActive ? 28 : 24,
          color: isActive
              ? const Color(0xFFFFB500) // dourado do ícone ativo
              : Colors.white,           // branco inativo
        ),
      ),
    );
  }
}
