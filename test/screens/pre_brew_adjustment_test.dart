import 'package:drip_logger/models/brew_step.dart';
import 'package:drip_logger/models/recipe.dart';
import 'package:drip_logger/screens/pre_brew_adjustment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PreBrewAdjustmentScreen displays basic info and actions',
      (WidgetTester tester) async {
    // 1. Setup Test Data
    final recipe = Recipe(
      id: 'test_id',
      name: 'Test Recipe',
      beanWeightGrams: 15.0,
      grindSize: 'Medium',
      totalWaterAmount: 225.0,
      steps: [
        BrewStep(waterAmount: 45.0, waitTime: const Duration(seconds: 45)),
        BrewStep(waterAmount: 180.0, waitTime: const Duration(seconds: 0)),
      ],
    );

    // 2. Pump Widget
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: PreBrewAdjustmentScreen(recipe: recipe),
        ),
      ),
    );

    // 3. Verify Initial State
    // Title
    expect(find.text('Adjust Recipe'), findsOneWidget);
    // Recipe Name (in summary or pre-filled fields if exposed?
    // Current UI doesn't explicitly show name in the adjustment screen body,
    // only "Adjust Recipe" in AppBar. (Based on code review)
    // But it shows bean weight, etc.

    // Verify "Edit" and "Share" menu exists
    // The PopupMenuButton is an Icon(Icons.more_vert) usually, or in actions.
    // In the code, we used `PopupMenuButton<String>(child: ...)`?
    // No, default PopupMenuButton uses three dots icon.
    expect(find.byType(PopupMenuButton<String>), findsOneWidget);

    // 4. Open Menu
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    // 5. Verify Menu Items
    expect(find.text('Edit Original'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);

    // 6. Verify New Editable Fields
    expect(find.text('Grinder'), findsOneWidget);
    expect(find.text('Dripper'), findsOneWidget);
    expect(find.text('Filter'), findsOneWidget);
    expect(find.text('Note'), findsOneWidget);

    // Verify Steps Wait Time is editable (TextFormField handles it)
    // Initially 45s
    expect(find.text('45'), findsOneWidget);

    // Test entering text in Grinder field
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Grinder'), 'My Grinder');
    // We can verify internal state or just that it doesn't crash.
    // Since it's a stateful widget, we'd need to inspect the state or tap start (which requires mocking navigation/repo).
    // For now, ensuring widgets are present and interactable is sufficient for "basic info and actions".
  });
}
