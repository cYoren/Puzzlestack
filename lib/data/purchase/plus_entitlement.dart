import 'package:flutter/foundation.dart';

/// The product this app sells. One non-consumable, the same on both stores.
const String plusProductId = 'puzzlestack_plus';

/// The one place in the app that says whether this device owns Plus.
///
/// Every reader — the pick gate, the sheet, settings — asks this row and only
/// this row. There is no second flag, no trial shortcut and no clock: what Plus
/// unlocks is stated once, here, and a row that says `false` means exactly one
/// thing.
@immutable
class PlusEntitlement {
  /// Nothing bought, on this device or on this account.
  const PlusEntitlement.free()
      : ownsPlus = false,
        productId = null,
        since = null,
        verifiedAt = null;

  /// The store confirmed the purchase. [verifiedAt] is the last time the store
  /// said so; null means the receipt is local and has not been re-checked yet.
  const PlusEntitlement.owned({
    this.productId = plusProductId,
    required this.since,
    this.verifiedAt,
  }) : ownsPlus = true;

  final bool ownsPlus;
  final String? productId;
  final DateTime? since;
  final DateTime? verifiedAt;

  /// The store confirmed, at [at], that this account still owns the product.
  PlusEntitlement verifiedAtTime(DateTime at) => PlusEntitlement.owned(
        productId: productId ?? plusProductId,
        since: since ?? at,
        verifiedAt: at,
      );

  Map<String, dynamic> toJson() => {
        'owns': ownsPlus,
        'product': productId,
        'since': since?.toIso8601String(),
        'verified': verifiedAt?.toIso8601String(),
      };

  /// Reads a stored row. Anything that is not a clean owned row reads as free,
  /// because a corrupt row must never be a reason to hand out a paid feature.
  static PlusEntitlement fromJson(Object? raw) {
    if (raw is! Map) return const PlusEntitlement.free();
    if (raw['owns'] != true) return const PlusEntitlement.free();
    final Object? product = raw['product'];
    if (product is! String || product != plusProductId) {
      return const PlusEntitlement.free();
    }
    final DateTime? since = _date(raw['since']);
    if (since == null) return const PlusEntitlement.free();
    return PlusEntitlement.owned(
      productId: product,
      since: since,
      verifiedAt: _date(raw['verified']),
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }

  @override
  bool operator ==(Object other) =>
      other is PlusEntitlement &&
      other.ownsPlus == ownsPlus &&
      other.productId == productId &&
      other.since == since &&
      other.verifiedAt == verifiedAt;

  @override
  int get hashCode => Object.hash(ownsPlus, productId, since, verifiedAt);
}
