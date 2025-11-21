import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:myyearmystory/widgets/shared/main_scaffold.dart';

// Imports dos widgets mensais
import 'package:myyearmystory/widgets/monthly/month_menu.dart';
import 'package:myyearmystory/widgets/monthly/monthly_goals_widget.dart';
import 'package:myyearmystory/widgets/monthly/curiosities_widget.dart';
import 'package:myyearmystory/widgets/monthly/interactive_quiz_widget.dart';
import 'package:myyearmystory/widgets/monthly/zodiac_widget.dart';

import 'package:myyearmystory/widgets/monthly/skills_development_widget.dart';
import 'package:myyearmystory/widgets/monthly/did_you_know_widget.dart';
import 'package:myyearmystory/widgets/monthly/interview_widget.dart';
import 'package:myyearmystory/widgets/monthly/monthly_lists_widget.dart';
import 'package:myyearmystory/widgets/monthly/gratitude_widget.dart';
import 'package:myyearmystory/widgets/monthly/reflections_widget.dart';
import 'package:myyearmystory/widgets/monthly/photo_gallery_widget.dart';
import 'package:myyearmystory/widgets/monthly/calendar_page.dart';


class CurrentMonthScreen extends StatefulWidget {
  final int? month;
  final int? year;

  const CurrentMonthScreen({
    super.key,
    this.month,
    this.year,
  });

  @override
  State<CurrentMonthScreen> createState() => _CurrentMonthScreenState();
}

class _CurrentMonthScreenState extends State<CurrentMonthScreen> {
  late int month;
  late int year;
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    month = widget.month ?? now.month;
    year = widget.year ?? now.year;
  }

  void _nextPage() {
    if (_currentPage < 11) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat.MMMM('pt_BR').format(DateTime(year, month));

    final List<Widget> pages = [
      MonthMenu(
        month: month,
        year: year,
        onNavigateToPage: (index) {
          _pageController.jumpToPage(index);
          setState(() => _currentPage = index);
        },
      ),
      MonthlyGoalsWidget(month: month, year: year),
      CuriositiesWidget(month: month, year: year),
      MonthlyQuizWidget(
        month: month,
        year: year,
        
      ),
      ZodiacWidget(month: month, year: year),
      SkillsDevelopmentWidget(month: month, year: year),
      DidYouKnowWidget(month: month, year: year),
      InterviewScreen(month: month, year: year),
      MonthlyListsWidget(month: month, year: year),
      GratitudeWidget(month: month, year: year),
      ReflectionsWidget(month: month, year: year),
      MonthlyPhotoGallery(month: month, year: year),
      CalendarPage(month: month, year: year),
    ];

    return MainScaffold(
      currentIndex: 1,
      body: SafeArea(
        child: Container(
          color: const Color(0xFFFFF7FA), // 🌸 fundo rosinha geral
          child: Column(
            children: [
              // 🔹 Cabeçalho com paginação
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${_currentPage + 1} / ${pages.length}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),

              // 🔹 Carrossel de páginas (com fundo branco e bordas suaves)
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final isActive = _currentPage == index;
                    return AnimatedScale(
                      scale: isActive ? 1.0 : 0.93,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Card(
                            elevation: isActive ? 6 : 2,
                            margin: EdgeInsets.zero,
                            color: Colors.white,
                            child: pages[index],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 🔹 Indicador + botões de navegação
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'prevBtn',
                      onPressed: _currentPage > 0 ? _previousPage : null,
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black54,
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18),
                    ),

                    Expanded(
                      child: Center(
                        child: SmoothPageIndicator(
                          controller: _pageController,
                          count: pages.length,
                          effect: WormEffect(
                            dotHeight: 8,
                            dotWidth: 8,
                            spacing: 6,
                            activeDotColor: const Color(0xFFC03B66),
                            dotColor:
                            const Color(0xFFC03B66).withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),

                    FloatingActionButton.small(
                      heroTag: 'nextBtn',
                      onPressed:
                      _currentPage < pages.length - 1 ? _nextPage : null,
                      backgroundColor: const Color(0xFFC03B66),
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
