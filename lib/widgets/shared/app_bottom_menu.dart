import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:myyearmystory/screens/dashboard/dashboard_screen.dart';
import 'package:myyearmystory/screens/monthly/current_month_screen.dart';
import 'package:myyearmystory/screens/diary/diary_screen.dart';
import 'package:myyearmystory/screens/mood/mood_screen.dart';

class AppBottomMenu extends StatelessWidget {
  final int? currentIndex; // AGORA OPCIONAL
  final Color themeColor;

  const AppBottomMenu({
    super.key,
    this.currentIndex, // opcional
    this.themeColor = const Color(0xFFE32278),
  });

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final int currentMonth = now.month;
    final int currentYear = now.year;

    // -------------------------------------
    // SEGURANÇA: evita erro de índice
    // -------------------------------------
    final bool highlightDisabled =
        (currentIndex == null || currentIndex! < 0 || currentIndex! > 3);

    // se não tiver highlight → não usar índice válido
    final int safeIndex = highlightDisabled ? 0 : currentIndex!;

    return Container(
      decoration: BoxDecoration(
        color: themeColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
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
          currentIndex: safeIndex, // <- sempre dentro do range (0–3)
          onTap: (index) {
            if (!highlightDisabled && index == safeIndex) return;

            Widget nextScreen;
            switch (index) {
              case 0:
                nextScreen = DashboardScreen(
                  month: currentMonth,
                  year: currentYear,
                );
                break;

              case 1:
                nextScreen = const CurrentMonthScreen();
                break;

              case 2:
                nextScreen = DiaryScreen();
                break;

              case 3:
                nextScreen =
                    MoodScreen(month: currentMonth, year: currentYear);
                break;

              default:
                return;
            }

            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => nextScreen,
                transitionDuration: const Duration(milliseconds: 300),
                transitionsBuilder: (_, anim, __, child) {
                  return FadeTransition(opacity: anim, child: child);
                },
              ),
            );
          },

          type: BottomNavigationBarType.fixed,
          backgroundColor: themeColor,

          selectedItemColor:
              highlightDisabled ? Colors.white : const Color(0xFFFFB500),

          unselectedItemColor: Colors.white,
          showUnselectedLabels: true,
          elevation: 0,

          items: [
            _buildItem(
              index: 0,
              currentIndex: highlightDisabled ? -1 : safeIndex,
              icon: PhosphorIconsRegular.house,
              activeIcon: PhosphorIconsFill.house,
              label: 'bottom.home'.tr(),
            ),
            _buildItem(
              index: 1,
              currentIndex: highlightDisabled ? -1 : safeIndex,
              icon: PhosphorIconsRegular.calendarBlank,
              activeIcon: PhosphorIconsFill.calendarBlank,
              label: 'bottom.current_month'.tr(),
            ),
            _buildItem(
              index: 2,
              currentIndex: highlightDisabled ? -1 : safeIndex,
              icon: PhosphorIconsRegular.notebook,
              activeIcon: PhosphorIconsFill.notebook,
              label: 'bottom.diary'.tr(),
            ),
            _buildItem(
              index: 3,
              currentIndex: highlightDisabled ? -1 : safeIndex,
              icon: PhosphorIconsRegular.smiley,
              activeIcon: PhosphorIconsFill.smiley,
              label: 'bottom.mood'.tr(),
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildItem({
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
          color: isActive ? const Color(0xFFFFB500) : Colors.white,
        ),
      ),
    );
  }
}
