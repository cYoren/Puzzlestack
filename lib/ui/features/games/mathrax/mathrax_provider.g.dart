// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mathrax_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MathraxNotifier)
final mathraxProvider = MathraxNotifierProvider._();

final class MathraxNotifierProvider
    extends $NotifierProvider<MathraxNotifier, MathraxState> {
  MathraxNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mathraxProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mathraxNotifierHash();

  @$internal
  @override
  MathraxNotifier create() => MathraxNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MathraxState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MathraxState>(value),
    );
  }
}

String _$mathraxNotifierHash() => r'dc298fc75587ae1f5fea65bc1d51da57ee2ab1e1';

abstract class _$MathraxNotifier extends $Notifier<MathraxState> {
  MathraxState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MathraxState, MathraxState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MathraxState, MathraxState>,
              MathraxState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
