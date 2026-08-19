import 'package:flutter/material.dart';
import '../../../../features/home/presentation/pages/home_page.dart';
import '../../../../features/history/presentation/pages/history_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  DateTime? _selectedHistoricalDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            // Clear historical date when switching tabs
            if (index != 0) {
              _selectedHistoricalDate = null;
            }
          });
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

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return HomePage(
          key: ValueKey(_selectedHistoricalDate?.toIso8601String() ?? 'today'),
          sessionDate: _selectedHistoricalDate,
          onBackToHistory: _selectedHistoricalDate != null ? () {
            setState(() {
              _selectedHistoricalDate = null;
              _currentIndex = 1; // Switch back to history tab
            });
          } : null,
        );
      case 1:
        return HistoryPage(
          onSessionSelected: (date) {
            setState(() {
              _selectedHistoricalDate = date;
              _currentIndex = 0; // Switch to home tab to show historical session
            });
          },
        );
      case 2:
        return const Center(child: Text('Account Screen (Coming Soon)'));
      default:
        return const SizedBox();
    }
  }
}
