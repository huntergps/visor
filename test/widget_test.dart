import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:visor/providers/visor_provider.dart';
import 'package:visor/screens/visor_screen.dart';

void main() {
  group('VisorScreen Widget Tests', () {
    testWidgets('renders VisorScreen with provider', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => VisorProvider(),
            child: const VisorScreen(),
          ),
        ),
      );

      // Verify the screen renders
      expect(find.byType(VisorScreen), findsOneWidget);
    });

    testWidgets('displays welcome product initially', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => VisorProvider(),
            child: const VisorScreen(),
          ),
        ),
      );

      await tester.pump();

      // The default product name is BIENVENIDO
      expect(find.text('BIENVENIDO'), findsOneWidget);
    });

    testWidgets('container has correct dimensions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => VisorProvider(),
            child: const VisorScreen(),
          ),
        ),
      );

      // Find the inner container
      final containers = tester.widgetList<Container>(find.byType(Container));
      final mainContainer = containers.firstWhere(
        (c) => c.constraints?.maxWidth == 1366,
        orElse: () => Container(),
      );

      expect(mainContainer.constraints?.maxWidth, 1366);
      expect(mainContainer.constraints?.maxHeight, 768);
    });
  });
}
