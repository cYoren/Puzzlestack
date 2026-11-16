// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dual_coding_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DualCodingNotifier)
final dualCodingProvider = DualCodingNotifierProvider._();

final class DualCodingNotifierProvider
    extends $NotifierProvider<DualCodingNotifier, DualCodingState> {
  DualCodingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dualCodingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dualCodingNotifierHash();

  @$internal
  @override
  DualCodingNotifier create() => DualCodingNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DualCodingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DualCodingState>(value),
    );
  }
}

String _$dualCodingNotifierHash() =>
    r'032d2f2528b630fce9455599749da14adf318c7a';

abstract class _$DualCodingNotifier extends $Notifier<DualCodingState> {
  DualCodingState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DualCodingState, DualCodingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DualCodingState, DualCodingState>,
              DualCodingState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
