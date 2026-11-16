// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'symmetry_span_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SymmetrySpanNotifier)
final symmetrySpanProvider = SymmetrySpanNotifierProvider._();

final class SymmetrySpanNotifierProvider
    extends $NotifierProvider<SymmetrySpanNotifier, SymmetrySpanState> {
  SymmetrySpanNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'symmetrySpanProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$symmetrySpanNotifierHash();

  @$internal
  @override
  SymmetrySpanNotifier create() => SymmetrySpanNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SymmetrySpanState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SymmetrySpanState>(value),
    );
  }
}

String _$symmetrySpanNotifierHash() =>
    r'087f8806191328755fe7749e6b06b78db4279555';

abstract class _$SymmetrySpanNotifier extends $Notifier<SymmetrySpanState> {
  SymmetrySpanState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SymmetrySpanState, SymmetrySpanState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SymmetrySpanState, SymmetrySpanState>,
              SymmetrySpanState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
