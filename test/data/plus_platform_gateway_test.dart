import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/purchase/plus_gateway.dart';
import 'package:puzzle/providers/plus_providers.dart';

void main() {
  test('Linux selects a gateway that never touches a platform store', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(plusProvider.notifier).start();
    final gateway = container.read(plusGatewayProvider)();
    addTearDown(gateway.dispose);

    expect(await gateway.price(), isNull);
    expect(await gateway.buy(), PurchaseAnswer.storeUnavailable);
    expect(await gateway.restore(), RestoreAnswer.noAnswer);
    expect(gateway.events, emitsDone);

    await gateway.completePurchase(const PurchaseEvent.canceled());
  });
}
