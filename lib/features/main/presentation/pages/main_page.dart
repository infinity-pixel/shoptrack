import 'package:flutter/material.dart';
import '../../../../app.dart';
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
  int _homeRefreshRevision = 0;

  @override
  Widget build(BuildContext context) {
    final settingsService = ShopTrackApp.of(context);

    return ListenableBuilder(
      listenable: settingsService,
      builder: (context, _) {
        return Scaffold(
          key: ValueKey('main_scaffold_${settingsService.dataToken}'),
          backgroundColor: Colors.transparent,
          body: IndexedStack(
            index: _currentIndex,
            children: [_buildHomeTab(), _buildHistoryTab(), _buildAccountTab()],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
                // Clear historical date when switching tabs (unless it's the home tab)
                if (index != 0) {
                  _selectedHistoricalDate = null;
                }
              });
            },
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.description),
                label: 'Lists',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.manage_accounts_outlined),
                activeIcon: Icon(Icons.manage_accounts),
                label: 'Account',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHomeTab() {
    return HomePage(
      key: ValueKey(_selectedHistoricalDate?.toIso8601String() ?? 'today'),
      sessionDate: _selectedHistoricalDate,
      refreshRevision: _homeRefreshRevision,
      onBackToHistory: _selectedHistoricalDate != null
          ? () {
              setState(() {
                _selectedHistoricalDate = null;
                _currentIndex = 1;
                _homeRefreshRevision++;
              });
            }
          : null,
    );
  }

  Widget _buildHistoryTab() {
    return HistoryPage(
      onSessionSelected: (date) {
        final now = DateTime.now();
        final isToday =
            date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
        setState(() {
          _selectedHistoricalDate = isToday ? null : date;
          _currentIndex = 0;
          _homeRefreshRevision++;
        });
      },
    );
  }

  Widget _buildAccountTab() {
    return const AccountPage();
  }
}
