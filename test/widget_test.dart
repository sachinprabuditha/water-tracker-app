import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h2go/widgets/water_glass.dart';

void main() {
  testWidgets('WaterGlass renders and animates', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: WaterGlass(progress: 0.5))),
    ));
    expect(find.byType(WaterGlass), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('WaterGlass stays still when animations are disabled',
      (tester) async {
    await tester.pumpWidget(const MediaQuery(
      data: MediaQueryData(disableAnimations: true),
      child: MaterialApp(
        home: Scaffold(body: Center(child: WaterGlass(progress: 0.5))),
      ),
    ));
    await tester.pump(const Duration(seconds: 1));
    // With the wave loop stopped, nothing is left scheduling frames.
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
