// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'symmetry_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SymmetryNotifier)
final symmetryProvider = SymmetryNotifierProvider._();

final class SymmetryNotifierProvider
    extends $NotifierProvider<SymmetryNotifier, SymmetryState> {
  SymmetryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'symmetryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$symmetryNotifierHash();

  @$internal
  @override
  SymmetryNotifier create() => SymmetryNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SymmetryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SymmetryState>(value),
    );
  }
}

String _$symmetryNotifierHash() => r'a231e9ec8c21f2a2a08fa1a70513942fb9510d77';

abstract class _$SymmetryNotifier extends $Notifier<SymmetryState> {
  SymmetryState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SymmetryState, SymmetryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SymmetryState, SymmetryState>,
              SymmetryState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
