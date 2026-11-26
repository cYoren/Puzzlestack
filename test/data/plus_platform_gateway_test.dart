import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/data/purchase/plus_gateway.dart';

void main() {
  test('unavailable gateway never touches a platform store', () async {
    final gateway = UnavailablePlusGateway();

    expect(await gateway.price(), isNull);
    expect(await gateway.buy(), PurchaseAnswer.storeUnavailable);
    expect(await gateway.restore(), RestoreAnswer.noAnswer);
    expect(gateway.events, emitsDone);

    await gateway.completePurchase(const PurchaseEvent.canceled());
    await gateway.dispose();
  });
}
