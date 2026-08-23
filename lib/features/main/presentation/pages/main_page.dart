import 'package:flutter/material.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../account/presentation/pages/account_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  DateTime? _selectedHistoricalDate;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            // Clear historical date when switching tabs (unless it's the home tab)
            if (index != 0) {
              _selectedHistoricalDate = null;
            }
          });
        },
        physics: const ClampingScrollPhysics(),
        children: [
          _buildHomeTab(),
          _buildHistoryTab(),
          _buildAccountTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        elevation: 0,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return HomePage(
      key: ValueKey(_selectedHistoricalDate?.toIso8601String() ?? 'today'),
      sessionDate: _selectedHistoricalDate,
      onBackToHistory: _selectedHistoricalDate != null
          ? () {
              setState(() {
                _selectedHistoricalDate = null;
                _pageController.jumpToPage(1);
              });
            }
          : null,
    );
  }

  Widget _buildHistoryTab() {
    return HistoryPage(
      onSessionSelected: (date) {
        setState(() {
          _selectedHistoricalDate = date;
          _pageController.jumpToPage(0);
        });
      },
    );
  }

  Widget _buildAccountTab() {
    return const AccountPage();
  }
}
