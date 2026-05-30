import 'package:flutter/material.dart';

import 'chatbot.dart';
import 'dashboard.dart';
import 'profil.dart';
import 'riwayat.dart';
import 'transaksi.dart';
import 'viewmodels/main_tab_view_model.dart';
import 'viewmodels/profile_view_model.dart';

class MainTabScaffold extends StatefulWidget {
  const MainTabScaffold({
    super.key,
    this.initialIndex = homeIndex,
    ProfileViewModel? profileViewModel,
  }) : _profileViewModel = profileViewModel;

  static const int homeIndex = 0;
  static const int transaksiIndex = 1;
  static const int chatIndex = 2;
  static const int riwayatIndex = 3;
  static const int profilIndex = 4;

  final int initialIndex;
  final ProfileViewModel? _profileViewModel;

  @override
  State<MainTabScaffold> createState() => _MainTabScaffoldState();
}

class _MainTabScaffoldState extends State<MainTabScaffold> {
  late final MainTabViewModel _viewModel;
  late final PageController _pageController;
  late final List<Widget?> _pages;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _viewModel = MainTabViewModel(
      maxIndex: MainTabScaffold.profilIndex,
      initialIndex: widget.initialIndex,
    );
    _pageController = PageController(initialPage: _viewModel.selectedIndex);
    _pages = List<Widget?>.filled(MainTabScaffold.profilIndex + 1, null);
    _ensurePage(_viewModel.selectedIndex);
  }

  @override
  void didUpdateWidget(covariant MainTabScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _viewModel.updateInitialIndex(widget.initialIndex);
      _ensurePage(_viewModel.selectedIndex);
      _jumpToSelectedPage();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    final previousIndex = _viewModel.selectedIndex;
    _viewModel.selectTab(index);
    _ensurePage(_viewModel.selectedIndex);
    if (previousIndex != _viewModel.selectedIndex) {
      _animateToSelectedPage();
    }
  }

  void _handlePageChanged(int index) {
    _viewModel.selectTab(index);
    _ensurePage(_viewModel.selectedIndex);
  }

  void _animateToSelectedPage() {
    if (!_pageController.hasClients) return;

    _pageController.animateToPage(
      _viewModel.selectedIndex,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _jumpToSelectedPage() {
    if (!_pageController.hasClients) return;

    _pageController.jumpToPage(_viewModel.selectedIndex);
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
        return ProfilScreen(
          viewModel: widget._profileViewModel,
          onLoggedOut: _handleLoggedOut,
        );
      case MainTabScaffold.homeIndex:
      default:
        return const DashboardScreen();
    }
  }

  void _handleLoggedOut() {
    if (!mounted || _loggingOut) return;

    setState(() {
      _loggingOut = true;
      for (var index = 0; index < _pages.length; index++) {
        _pages[index] = null;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamedAndRemoveUntil('/welcome', (route) => false);
    });
  }

  List<BottomNavigationItemConfig> _buildNavItems() {
    final selectedIndex = _viewModel.selectedIndex;
    return [
      BottomNavigationItemConfig(
        iconAsset: 'assets/home11.png',
        label: 'Home',
        isActive: selectedIndex == MainTabScaffold.homeIndex,
        fallbackIcon: Icons.home,
        onTap: () => _selectTab(MainTabScaffold.homeIndex),
      ),
      BottomNavigationItemConfig(
        iconAsset: 'assets/riwayat1.png',
        label: 'Transaksi',
        isActive: selectedIndex == MainTabScaffold.transaksiIndex,
        fallbackIcon: Icons.swap_horiz,
        onTap: () => _selectTab(MainTabScaffold.transaksiIndex),
      ),
      BottomNavigationItemConfig(
        iconAsset: 'assets/chat_ai.png',
        label: 'Chat AI',
        isActive: selectedIndex == MainTabScaffold.chatIndex,
        fallbackIcon: Icons.smart_toy,
        onTap: () => _selectTab(MainTabScaffold.chatIndex),
      ),
      BottomNavigationItemConfig(
        iconAsset: 'assets/history.png',
        label: 'Riwayat',
        isActive: selectedIndex == MainTabScaffold.riwayatIndex,
        fallbackIcon: Icons.history,
        onTap: () => _selectTab(MainTabScaffold.riwayatIndex),
      ),
      BottomNavigationItemConfig(
        iconAsset: selectedIndex == MainTabScaffold.profilIndex
            ? 'assets/person2.png'
            : 'assets/person.png',
        label: 'Profil',
        isActive: selectedIndex == MainTabScaffold.profilIndex,
        fallbackIcon: Icons.person,
        onTap: () => _selectTab(MainTabScaffold.profilIndex),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_loggingOut) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SizedBox.expand(),
      );
    }

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: _handlePageChanged,
            itemBuilder: (context, index) {
              _ensurePage(index);
              return _pages[index] ?? const SizedBox.shrink();
            },
          ),
          bottomNavigationBar: DashboardBottomNavigation(
            items: _buildNavItems(),
          ),
        );
      },
    );
  }
}
