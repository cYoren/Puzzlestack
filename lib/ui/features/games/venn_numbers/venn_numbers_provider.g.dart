// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venn_numbers_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VennNumbersNotifier)
final vennNumbersProvider = VennNumbersNotifierProvider._();

final class VennNumbersNotifierProvider
    extends $NotifierProvider<VennNumbersNotifier, VennNumbersState> {
  VennNumbersNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vennNumbersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vennNumbersNotifierHash();

  @$internal
  @override
  VennNumbersNotifier create() => VennNumbersNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VennNumbersState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VennNumbersState>(value),
    );
  }
}

String _$vennNumbersNotifierHash() =>
    r'aabac744b8dae47815ceb831d3fe68a5360ba970';

abstract class _$VennNumbersNotifier extends $Notifier<VennNumbersState> {
  VennNumbersState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<VennNumbersState, VennNumbersState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VennNumbersState, VennNumbersState>,
              VennNumbersState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
