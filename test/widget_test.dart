import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:leftovr/main.dart';
import 'package:leftovr/models/fridge_item.dart';
import 'package:leftovr/screens/home_screen.dart';
import 'package:leftovr/screens/splash_screen.dart';
import 'package:leftovr/services/expiry.dart';
import 'package:leftovr/services/quick_entry.dart';
import 'package:leftovr/widgets/decorations.dart';

Future<void> _openApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(LeftovrApp(prefs: prefs));
  await tester.tapAt(const Offset(20, 20)); // skip the splash
  await tester.pumpAndSettle();
  expect(find.byType(HomeScreen), findsOneWidget);
}

/// Scrolls a widget into view before tapping — the item list is scrollable.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _nameField() => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'e.g. Greek yogurt',
    );

Finder _searchField() => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'Search',
    );

Finder _quickField() => find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          (w.decoration?.hintText ?? '').startsWith('Quick add'),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('splash materialises the dot-matrix name on white',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(LeftovrApp(prefs: prefs));

    // The dot grid is present from the first frame.
    expect(find.byType(DotMatrixText), findsOneWidget);
    expect(find.text('leftovr'), findsNothing); // no plain text — drawn as dots

    // Let the scan wave form the word; it stays a painted grid throughout.
    await tester.pump(const Duration(milliseconds: 2400));
    expect(find.byType(DotMatrixText), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('home shows the inventory with images and controls',
      (tester) async {
    await _openApp(tester);

    expect(find.text('TOTAL ITEMS'), findsOneWidget);
    expect(find.text('Items'), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    expect(find.text('Add item'), findsWidgets);
  });

  testWidgets('typing in search filters without leaving the page',
      (tester) async {
    await _openApp(tester);

    await tester.enterText(_searchField(), 'milk');
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Eggs'), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('a category chip filters the list', (tester) async {
    await _openApp(tester);

    await _tap(tester, find.text('Dairy').first);

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Spinach'), findsNothing);
  });

  testWidgets('adding an item shows it immediately', (tester) async {
    await _openApp(tester);

    await _tap(tester, find.text('Add item').first);
    await tester.enterText(_nameField(), 'Test yogurt');
    await _tap(
      tester,
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Add item'),
      ),
    );

    expect(find.text('Test yogurt'), findsOneWidget);
  });

  testWidgets('quantity stepper updates the item in place', (tester) async {
    await _openApp(tester);

    final milkRow = find
        .ancestor(of: find.text('Milk'), matching: find.byType(RepaintBoundary))
        .first;
    expect(
      find.descendant(of: milkRow, matching: find.text('1')),
      findsOneWidget,
    );

    await _tap(
      tester,
      find.descendant(of: milkRow, matching: find.byIcon(Icons.add)).first,
    );

    expect(
      find.descendant(of: milkRow, matching: find.text('2')),
      findsOneWidget,
    );
    expect(find.text('Milk'), findsOneWidget);
  });

  testWidgets('removing an item takes it off the screen', (tester) async {
    await _openApp(tester);

    final milkRow = find
        .ancestor(of: find.text('Milk'), matching: find.byType(RepaintBoundary))
        .first;
    await _tap(
      tester,
      find.descendant(of: milkRow, matching: find.byIcon(Icons.close)).first,
    );

    expect(find.text('Milk'), findsNothing);
  });

  Color background(WidgetTester tester) =>
      tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor!;

  Color cardFill(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(find.byKey(const ValueKey('inventory-card')));
    return (box.decoration as BoxDecoration).color!;
  }

  testWidgets('theme toggle repaints the entire app, not just the toggle',
      (tester) async {
    await _openApp(tester);

    // Light by default — the real page and card colours are light.
    expect(find.byTooltip('Switch to dark'), findsOneWidget);
    final light = background(tester);
    final lightCard = cardFill(tester);
    expect(light, isNot(const Color(0xFF000000)));

    await _tap(tester, find.byTooltip('Switch to dark'));
    expect(find.byTooltip('Switch to light'), findsOneWidget);
    final dark = background(tester);
    expect(dark, const Color(0xFF000000));
    expect(dark, isNot(light));

    // Cards switch too — this is the bug the old implementation missed.
    final darkCard = cardFill(tester);
    expect(darkCard, isNot(lightCard));
    expect(darkCard, const Color(0xFF1C1C1E));

    await _tap(tester, find.byTooltip('Switch to light'));
    expect(find.byTooltip('Switch to dark'), findsOneWidget);
    expect(background(tester), light);
    expect(cardFill(tester), lightCard);
  });

  testWidgets('sorting the list works', (tester) async {
    await _openApp(tester);

    await _tap(tester, find.text('Sort'));
    await _tap(tester, find.text('By name'));

    expect(find.text('Bananas'), findsOneWidget);
    expect(find.text('Butter'), findsOneWidget);
  });

  testWidgets('keyboard quick entry parses and adds an item', (tester) async {
    await _openApp(tester);

    await tester.enterText(_quickField(), '3 yogurt 2d');
    await tester.pumpAndSettle();
    expect(
      find.text('3 × Yogurt · Dairy · use in 2 days'),
      findsOneWidget,
    );

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Yogurt'), findsOneWidget);
  });

  testWidgets('offline recipe matcher can plan a meal', (tester) async {
    await _openApp(tester);

    expect(find.text('PLAN & COOK'), findsOneWidget);
    expect(find.text('Cook this'), findsWidgets);

    await _tap(tester, find.text('Cook this').first);
    await _tap(tester, find.text('Plan'));

    expect(find.textContaining('servings · Dinner'), findsOneWidget);
  });

  testWidgets('shopping list exports Markdown with missing ingredients',
      (tester) async {
    await _openApp(tester);

    final card = find
        .ancestor(
          of: find.text('Simple Chicken & Rice'),
          matching: find.byType(AppCard),
        )
        .first;
    await _tap(
      tester,
      find.descendant(of: card, matching: find.text('Cook this')),
    );

    await _tap(tester, find.text('List'));
    expect(find.text('MARKDOWN PREVIEW'), findsOneWidget);

    await _tap(tester, find.text('Export Markdown'));
    expect(
      find.textContaining('# leftovr shopping list'),
      findsNWidgets(2), // preview + export dialog
    );
    expect(find.textContaining('rice'), findsWidgets);
  });

  test('quick entry parser understands quantity, expiry and category', () {
    final parsed = const QuickEntryParser().parse('2 milk 3d')!;
    expect(parsed.name, 'Milk');
    expect(parsed.quantity, 2);
    expect(parsed.category, ItemCategory.dairy);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    expect(
      parsed.expiry.difference(today).inDays,
      3,
    );
    expect(const QuickEntryParser().parse('   '), isNull);
  });

  test('expiry monitor reports each crossing once', () {
    final now = DateTime(2026, 1, 1);
    final entries = [
      ExpiryEntry(id: '1', name: 'Milk', expiry: now.add(const Duration(days: 2))),
    ];
    final monitor = ExpiryMonitor();

    expect(monitor.check(entries, now: now), hasLength(1));
    expect(monitor.check(entries, now: now), isEmpty);
    expect(ExpiryMonitor.report(entries, now: now), contains('USE SOON'));
  });
}
