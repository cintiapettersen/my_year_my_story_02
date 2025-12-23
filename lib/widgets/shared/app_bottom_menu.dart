import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:myyearmystory/screens/dashboard/dashboard_screen.dart';
import 'package:myyearmystory/screens/monthly/current_month_screen.dart';
import 'package:myyearmystory/screens/diary/diary_screen.dart';
import 'package:myyearmystory/screens/mood/mood_screen.dart';

class AppBottomMenu extends StatelessWidget {
  final int? currentIndex;
  final Color themeColor;

  const AppBottomMenu({
    super.key,
    this.currentIndex,
    this.themeColor = const Color(0xFFE32278),
  });

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final int currentMonth = now.month;
    final int currentYear = now.year;

    // 📐 Responsividade base
    final double screenWidth = MediaQuery.of(context).size.width;

    final double iconSizeInactive =
        (screenWidth * 0.055).clamp(22, 28);

    final double iconSizeActive =
        (screenWidth * 0.065).clamp(26, 32);

    final double labelFontSize =
        (screenWidth * 0.026).clamp(11, 13);

    // -------------------------------------
    // SEGURANÇA: evita erro de índice
    // -------------------------------------
    final bool highlightDisabled =
        (currentIndex == null || currentIndex! < 0 || currentIndex! > 3);

    final int safeIndex = highlightDisabled ? 0 : currentIndex!;

    return SafeArea(
      top: false,
      child: Container(
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
            currentIndex: safeIndex,
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
                  nextScreen = DiaryScreen(date: DateTime.now());
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
            elevation: 0,

            selectedItemColor: highlightDisabled
                ? Colors.white
                : const Color.fromARGB(255, 87, 24, 77),

            unselectedItemColor: Colors.white,
            showUnselectedLabels: true,

            selectedLabelStyle: TextStyle(
              fontSize: labelFontSize,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: labelFontSize,
              fontWeight: FontWeight.w500,
            ),

            items: [
              _buildItem(
                index: 0,
                currentIndex: highlightDisabled ? -1 : safeIndex,
                icon: PhosphorIconsRegular.house,
                activeIcon: PhosphorIconsFill.house,
                label: 'bottom.home'.tr(),
                iconSize: iconSizeInactive,
                activeIconSize: iconSizeActive,
              ),
              _buildItem(
                index: 1,
                currentIndex: highlightDisabled ? -1 : safeIndex,
                icon: PhosphorIconsRegular.calendarBlank,
                activeIcon: PhosphorIconsFill.calendarBlank,
                label: 'bottom.current_month'.tr(),
                iconSize: iconSizeInactive,
                activeIconSize: iconSizeActive,
              ),
              _buildItem(
                index: 2,
                currentIndex: highlightDisabled ? -1 : safeIndex,
                icon: PhosphorIconsRegular.notebook,
                activeIcon: PhosphorIconsFill.notebook,
                label: 'bottom.diary'.tr(),
                iconSize: iconSizeInactive,
                activeIconSize: iconSizeActive,
              ),
              _buildItem(
                index: 3,
                currentIndex: highlightDisabled ? -1 : safeIndex,
                icon: PhosphorIconsRegular.smiley,
                activeIcon: PhosphorIconsFill.smiley,
                label: 'bottom.mood'.tr(),
                iconSize: iconSizeInactive,
                activeIconSize: iconSizeActive,
              ),
            ],
          ),
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
    required double iconSize,
    required double activeIconSize,
  }) {
    final bool isActive = index == currentIndex;

    return BottomNavigationBarItem(
      label: label,
      icon: Icon(
        isActive ? activeIcon : icon,
        size: isActive ? activeIconSize : iconSize,
        color: isActive
            ? const Color.fromARGB(255, 229, 213, 35)
            : Colors.white,
      ),
    );
  }
}
