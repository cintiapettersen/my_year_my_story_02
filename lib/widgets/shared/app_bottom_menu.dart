import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// 🌸 Import das telas principais
import 'package:my_year_my_story/screens/dashboard/dashboard_screen.dart';
import 'package:my_year_my_story/widgets/monthly/month_menu.dart';
import 'package:my_year_my_story/screens/annual/annual_photo_album_screen.dart';
import 'package:my_year_my_story/screens/diary/diary_screen.dart';
import 'package:my_year_my_story/screens/mood/mood_screen.dart';
import 'package:my_year_my_story/screens/monthly/current_month_screen.dart';


class AppBottomMenu extends StatelessWidget {
  final int currentIndex;

  const AppBottomMenu({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    // 🌸 mês e ano automáticos
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
                nextScreen = AnnualPhotoAlbumScreen(
                  month: currentMonth,
                  year: currentYear,
                );
                break;
              case 3:
                nextScreen = DiaryScreen(month: currentMonth, year: currentYear);
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
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFC03B66),
          unselectedItemColor: Colors.grey[500],
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
          showUnselectedLabels: true,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(PhosphorIconsRegular.house),
              activeIcon: Icon(PhosphorIconsFill.house),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIconsRegular.calendarBlank),
              activeIcon: Icon(PhosphorIconsFill.calendarBlank),
              label: 'Mês Atual',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIconsRegular.images),
              activeIcon: Icon(PhosphorIconsFill.images),
              label: 'Fotos',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIconsRegular.bookOpenText),
              activeIcon: Icon(PhosphorIconsFill.bookOpenText),
              label: 'Diário',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIconsRegular.smiley),
              activeIcon: Icon(PhosphorIconsFill.smiley),
              label: 'Humor',
            ),
          ],
        ),
      ),
    );
  }
}
