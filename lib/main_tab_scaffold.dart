import 'package:flutter/material.dart';

import 'chatbot.dart';
import 'dashboard.dart';
import 'profil.dart';
import 'riwayat.dart';
import 'transaksi.dart';

class MainTabScaffold extends StatefulWidget {
  const MainTabScaffold({super.key, this.initialIndex = homeIndex});

  static const int homeIndex = 0;
  static const int transaksiIndex = 1;
  static const int chatIndex = 2;
  static const int riwayatIndex = 3;
  static const int profilIndex = 4;

  final int initialIndex;

  @override
  State<MainTabScaffold> createState() => _MainTabScaffoldState();
}

class _MainTabScaffoldState extends State<MainTabScaffold> {
  late int _selectedIndex;
  late final List<Widget?> _pages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _normalizeIndex(widget.initialIndex);
    _pages = List<Widget?>.filled(MainTabScaffold.profilIndex + 1, null);
    _ensurePage(_selectedIndex);
  }

  @override
  void didUpdateWidget(covariant MainTabScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _selectedIndex = _normalizeIndex(widget.initialIndex);
      _ensurePage(_selectedIndex);
    }
  }

  void _selectTab(int index) {
    final nextIndex = _normalizeIndex(index);
    if (_selectedIndex == nextIndex) {
      return;
    }

    setState(() {
      _ensurePage(nextIndex);
      _selectedIndex = nextIndex;
    });
  }

  void _ensurePage(int index) {
    _pages[index] ??= _createPage(index);
  }

  Widget _createPage(int index) {
    switch (index) {
      case MainTabScaffold.transaksiIndex:
        return const TransaksiScreen();
      case MainTabScaffold.chatIndex:
        return ChatbotScreen(
          onBack: () => _selectTab(MainTabScaffold.homeIndex),
        );
      case MainTabScaffold.riwayatIndex:
        return const RiwayatScreen();
      case MainTabScaffold.profilIndex:
        return const ProfilScreen();
      case MainTabScaffold.homeIndex:
      default:
        return const DashboardScreen();
    }
  }

  int _normalizeIndex(int index) {
    if (index < MainTabScaffold.homeIndex) {
      return MainTabScaffold.homeIndex;
    }
    if (index > MainTabScaffold.profilIndex) {
      return MainTabScaffold.profilIndex;
    }
    return index;
  }

  List<BottomNavigationItemConfig> _buildNavItems() {
    return [
      BottomNavigationItemConfig(
        iconAsset: 'assets/home11.png',
        label: 'Home',
        isActive: _selectedIndex == MainTabScaffold.homeIndex,
        fallbackIcon: Icons.home,
        onTap: () => _selectTab(MainTabScaffold.homeIndex),
      ),
      BottomNavigationItemConfig(
        iconAsset: 'assets/riwayat1.png',
        label: 'Transaksi',
        isActive: _selectedIndex == MainTabScaffold.transaksiIndex,
        fallbackIcon: Icons.swap_horiz,
        onTap: () => _selectTab(MainTabScaffold.transaksiIndex),
      ),
      BottomNavigationItemConfig(
        iconAsset: 'assets/chat_ai.png',
        label: 'Chat AI',
        isActive: _selectedIndex == MainTabScaffold.chatIndex,
        fallbackIcon: Icons.smart_toy,
        onTap: () => _selectTab(MainTabScaffold.chatIndex),
      ),
      BottomNavigationItemConfig(
        iconAsset: 'assets/history.png',
        label: 'Riwayat',
        isActive: _selectedIndex == MainTabScaffold.riwayatIndex,
        fallbackIcon: Icons.history,
        onTap: () => _selectTab(MainTabScaffold.riwayatIndex),
      ),
      BottomNavigationItemConfig(
        iconAsset: _selectedIndex == MainTabScaffold.profilIndex
            ? 'assets/person2.png'
            : 'assets/person.png',
        label: 'Profil',
        isActive: _selectedIndex == MainTabScaffold.profilIndex,
        fallbackIcon: Icons.person,
        onTap: () => _selectTab(MainTabScaffold.profilIndex),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(
          _pages.length,
          (index) => _pages[index] ?? const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: DashboardBottomNavigation(items: _buildNavItems()),
    );
  }
}
