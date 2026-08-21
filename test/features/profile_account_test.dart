import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_clarity/l10n/generated/app_localizations.dart';
import 'package:meal_clarity/src/domain/nutrition_goals.dart';
import 'package:meal_clarity/src/features/profile_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    locale: const Locale('tr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );

  testWidgets('renders the goals it is given rather than fixed numbers', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ProfileScreen(
          goals: NutritionGoals.forCalories(2600),
          onNavigationSelected: (_) {},
        ),
      ),
    );

    expect(find.text('2.600 kcal'), findsOneWidget);
    expect(
      find.text('195 g protein · 293 g karbonhidrat · 72 g yağ'),
      findsOneWidget,
    );
  });

  testWidgets('account rows are hidden when no repository is wired', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const ProfileScreen(
          goals: NutritionGoals.fallback,
          onNavigationSelected: _ignore,
        ),
      ),
    );

    expect(find.byKey(const Key('profile-sign-out')), findsNothing);
    expect(find.byKey(const Key('profile-delete-account')), findsNothing);
    expect(find.text('Hesap'), findsNothing);
  });

  testWidgets('sign out asks for confirmation before calling back', (
    tester,
  ) async {
    var signOutCount = 0;
    await tester.pumpWidget(
      wrap(
        ProfileScreen(
          goals: NutritionGoals.fallback,
          onNavigationSelected: (_) {},
          onSignOut: () async => signOutCount++,
          showBottomNavigationBar: false,
        ),
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('profile-sign-out')));
    await tester.tap(find.byKey(const Key('profile-sign-out')));
    await tester.pumpAndSettle();
    expect(signOutCount, 0);

    await tester.tap(find.byKey(const Key('sign-out-confirm')));
    await tester.pumpAndSettle();
    expect(signOutCount, 1);
  });

  testWidgets(
    'account deletion needs two confirmations and an acknowledgement',
    (tester) async {
      var deleteCount = 0;
      await tester.pumpWidget(
        wrap(
          ProfileScreen(
            goals: NutritionGoals.fallback,
            onNavigationSelected: (_) {},
            onDeleteAccount: () async {
              deleteCount++;
              return true;
            },
            showBottomNavigationBar: false,
          ),
        ),
      );

      await tester.ensureVisible(
        find.byKey(const Key('profile-delete-account')),
      );
      await tester.tap(find.byKey(const Key('profile-delete-account')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('delete-account-continue')));
      await tester.pumpAndSettle();

      // The destructive action stays disabled until the user opts in.
      final confirm = find.byKey(const Key('delete-account-confirm'));
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(deleteCount, 0);

      await tester.tap(find.byKey(const Key('delete-account-acknowledge')));
      await tester.pumpAndSettle();
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(deleteCount, 1);
    },
  );

  testWidgets('language row switches the override and offers system default', (
    tester,
  ) async {
    Locale? selected = const Locale('tr');
    await tester.pumpWidget(
      wrap(
        ProfileScreen(
          goals: NutritionGoals.fallback,
          locale: selected,
          onNavigationSelected: (_) {},
          onLocaleChanged: (locale) => selected = locale,
        ),
      ),
    );

    expect(find.text('Türkçe'), findsOneWidget);
    await tester.tap(find.text('Dil'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('language-option-english')));
    await tester.pumpAndSettle();
    expect(selected, const Locale('en'));

    await tester.tap(find.text('Dil'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-option-system')));
    await tester.pumpAndSettle();
    expect(selected, isNull);
  });
}

void _ignore(int _) {}
