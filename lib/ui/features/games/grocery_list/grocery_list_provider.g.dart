// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grocery_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GroceryListNotifier)
final groceryListProvider = GroceryListNotifierProvider._();

final class GroceryListNotifierProvider
    extends $NotifierProvider<GroceryListNotifier, GroceryListState> {
  GroceryListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'groceryListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groceryListNotifierHash();

  @$internal
  @override
  GroceryListNotifier create() => GroceryListNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GroceryListState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GroceryListState>(value),
    );
  }
}

String _$groceryListNotifierHash() =>
    r'c0c2c1a0602791dc83f0693a8f9c21875c4d227c';

abstract class _$GroceryListNotifier extends $Notifier<GroceryListState> {
  GroceryListState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<GroceryListState, GroceryListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GroceryListState, GroceryListState>,
              GroceryListState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
