// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mob_2/main.dart';
import 'package:mob_2/main_tab_scaffold.dart';
import 'package:mob_2/profil.dart';
import 'package:mob_2/viewmodels/profile_view_model.dart';
import 'package:mob_2/welcome_screen.dart';

void main() {
  testWidgets('Welcome screen renders expected widgets', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    SharedPreferences.setMockInitialValues({});
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MyApp(appInitialization: Future<void>.value()));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNWidgets(2));
  });

  testWidgets('Profile logout clears snackbars and returns to welcome screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    SharedPreferences.setMockInitialValues({});
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        routes: {'/welcome': (context) => const WelcomeScreen()},
        home: Scaffold(body: ProfilScreen(viewModel: _TestProfileViewModel())),
      ),
    );

    await tester.pumpAndSettle();
    final messenger = ScaffoldMessenger.of(
      tester.element(find.byType(ProfilScreen)),
    );
    messenger.showSnackBar(
      const SnackBar(content: Text('Pesan transaksi lama')),
    );
    await tester.pump();
    expect(find.text('Pesan transaksi lama'), findsOneWidget);

    await tester.tap(find.byTooltip('Logout'));
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi Logout'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Batal'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Logout'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi Logout'), findsNothing);
    expect(find.text('Pesan transaksi lama'), findsOneWidget);

    await tester.tap(find.byTooltip('Logout'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(find.text('Pesan transaksi lama'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile logout works from main tab scaffold', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    SharedPreferences.setMockInitialValues({});
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        routes: {'/welcome': (context) => const WelcomeScreen()},
        home: MainTabScaffold(
          initialIndex: MainTabScaffold.profilIndex,
          profileViewModel: _TestProfileViewModel(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Transaksi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Logout'));
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi Logout'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _TestProfileViewModel extends ProfileViewModel {
  @override
  Future<void> loadProfile({
    String? emailArgument,
    bool forceRefresh = false,
  }) async {}

  @override
  Future<void> signOut() async {}
}
