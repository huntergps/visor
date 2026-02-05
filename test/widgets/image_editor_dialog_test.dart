import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visor/widgets/common/image_editor_dialog.dart';

void main() {
  group('ImageEditorDialog', () {
    testWidgets('should render single screen with all controls',
        (WidgetTester tester) async {
      // Create a simple test image (1x1 red pixel)
      final Uint8List testImage = Uint8List.fromList([
        137, 80, 78, 71, 13, 10, 26, 10, // PNG signature
        0, 0, 0, 13, 73, 72, 68, 82, // IHDR chunk
        0, 0, 0, 1, 0, 0, 0, 1, 8, 2, 0, 0, 0, 144, 119, 83, 222,
        0, 0, 0, 12, 73, 68, 65, 84, 8, 153, 99, 248, 207, 192, 0, 0, 3, 1, 1, 0,
        24, 221, 141, 176,
        0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: ImageEditorDialog(imageBytes: testImage),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify AppBar
      expect(find.text('Editar imagen'), findsOneWidget);
      expect(find.text('Listo'), findsOneWidget);

      // Verify all controls are present in single screen
      expect(find.text('Rotación'), findsOneWidget);
      expect(find.text('Brillo'), findsOneWidget);
      expect(find.text('Quitar fondo'), findsOneWidget);

      // Verify sliders are present
      expect(find.byType(Slider), findsNWidgets(2)); // Rotation + Brightness

      // Verify no tabs (single screen)
      expect(find.byType(TabBar), findsNothing);
      expect(find.byType(TabBarView), findsNothing);
    });

    testWidgets('should adjust rotation slider', (WidgetTester tester) async {
      final Uint8List testImage = Uint8List.fromList([
        137, 80, 78, 71, 13, 10, 26, 10,
        0, 0, 0, 13, 73, 72, 68, 82,
        0, 0, 0, 1, 0, 0, 0, 1, 8, 2, 0, 0, 0, 144, 119, 83, 222,
        0, 0, 0, 12, 73, 68, 65, 84, 8, 153, 99, 248, 207, 192, 0, 0, 3, 1, 1, 0,
        24, 221, 141, 176,
        0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: ImageEditorDialog(imageBytes: testImage),
        ),
      );

      await tester.pumpAndSettle();

      // Find rotation slider (first slider)
      final rotationSlider = find.byType(Slider).first;
      expect(rotationSlider, findsOneWidget);

      // Verify initial value is 0
      final slider = tester.widget<Slider>(rotationSlider);
      expect(slider.value, 0.0);
      expect(slider.min, -180.0);
      expect(slider.max, 180.0);
    });

    testWidgets('should have close button that returns null',
        (WidgetTester tester) async {
      final Uint8List testImage = Uint8List.fromList([
        137, 80, 78, 71, 13, 10, 26, 10,
        0, 0, 0, 13, 73, 72, 68, 82,
        0, 0, 0, 1, 0, 0, 0, 1, 8, 2, 0, 0, 0, 144, 119, 83, 222,
        0, 0, 0, 12, 73, 68, 65, 84, 8, 153, 99, 248, 207, 192, 0, 0, 3, 1, 1, 0,
        24, 221, 141, 176,
        0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
      ]);

      Uint8List? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await Navigator.of(context).push<Uint8List>(
                      MaterialPageRoute(
                        builder: (_) => ImageEditorDialog(imageBytes: testImage),
                      ),
                    );
                  },
                  child: const Text('Open Editor'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open editor
      await tester.tap(find.text('Open Editor'));
      await tester.pumpAndSettle();

      // Tap close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Verify null is returned
      expect(result, isNull);
    });
  });
}
