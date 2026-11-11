import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/widgets/game_hud.dart';

/// The HUD exists so a stat row cannot overflow a 320dp phone. These tests pin
/// the two properties the old `Row(mainAxisAlignment: spaceBetween)` gave for
/// free: chips at the two edges when they fit, and no overflow when they do not.
void main() {
  Widget host(Widget child) => MaterialApp(
        home: Scaffold(body: Column(children: [child])),
      );

  Widget chip(String label, {double width = 120}) => SizedBox(
        width: width,
        height: 32,
        child: Text(label),
      );

  testWidgets('chips sit at the two edges when they fit', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(host(GameHud(children: [chip('a'), chip('b')])));

    expect(tester.takeException(), isNull);
    final a = tester.getRect(find.text('a'));
    final b = tester.getRect(find.text('b'));
    expect(a.left, 0);
    expect(b.right, 320);
  });

  testWidgets('chips wrap instead of overflowing at 320dp', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Two 200dp chips cannot share 320dp.
    await tester.pumpWidget(host(GameHud(children: [
      chip('a', width: 200),
      chip('b', width: 200),
    ])));

    expect(tester.takeException(), isNull);
    final a = tester.getRect(find.text('a'));
    final b = tester.getRect(find.text('b'));
    expect(a.top, isNot(b.top), reason: 'the second chip should be on its own run');
  });
}
