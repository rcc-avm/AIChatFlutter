import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'token_stats_screen.dart';
import 'expense_chart_screen.dart';
import 'history_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Consumer<NavigationProvider>(
        builder: (context, navigation, child) {
          return IndexedStack(
            index: navigation.currentTab.index,
            children: [
              const ChatScreen(),
              const ProfileScreen(),
              const TokenStatsScreen(),
              const ExpenseChartScreen(),
              const HistoryScreen(),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<NavigationProvider>(
        builder: (context, navigation, child) {
          return BottomNavigationBar(
            currentIndex: navigation.currentTab.index,
            onTap: (index) {
              final tab = NavigationTab.values[index];
              if (navigation.isTabEnabled(tab)) {
                navigation.setCurrentTab(tab);
              }
            },
            backgroundColor: const Color(0xFF262626),
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.white70,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.chat),
                label: navigation.getTabTitle(NavigationTab.chat),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person),
                label: navigation.getTabTitle(NavigationTab.profile),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.bar_chart),
                label: navigation.getTabTitle(NavigationTab.tokenStats),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.timeline),
                label: navigation.getTabTitle(NavigationTab.expenseChart),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.history),
                label: navigation.getTabTitle(NavigationTab.history),
              ),
            ],
          );
        },
      ),
    );
  }
}
