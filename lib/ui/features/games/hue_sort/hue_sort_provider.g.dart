// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hue_sort_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HueSortNotifier)
final hueSortProvider = HueSortNotifierProvider._();

final class HueSortNotifierProvider
    extends $NotifierProvider<HueSortNotifier, HueSortState> {
  HueSortNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hueSortProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hueSortNotifierHash();

  @$internal
  @override
  HueSortNotifier create() => HueSortNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HueSortState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HueSortState>(value),
    );
  }
}

String _$hueSortNotifierHash() => r'05eef726fcebae03f44ec5bd0ffde1e68a1a138c';

abstract class _$HueSortNotifier extends $Notifier<HueSortState> {
  HueSortState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<HueSortState, HueSortState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HueSortState, HueSortState>,
              HueSortState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
