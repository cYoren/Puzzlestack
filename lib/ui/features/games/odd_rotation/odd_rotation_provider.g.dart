// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'odd_rotation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OddRotationNotifier)
final oddRotationProvider = OddRotationNotifierProvider._();

final class OddRotationNotifierProvider
    extends $NotifierProvider<OddRotationNotifier, OddRotationState> {
  OddRotationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'oddRotationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$oddRotationNotifierHash();

  @$internal
  @override
  OddRotationNotifier create() => OddRotationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OddRotationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OddRotationState>(value),
    );
  }
}

String _$oddRotationNotifierHash() =>
    r'552822d695d9699308b95d7cf5d3c2f8ac8b3b90';

abstract class _$OddRotationNotifier extends $Notifier<OddRotationState> {
  OddRotationState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<OddRotationState, OddRotationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OddRotationState, OddRotationState>,
              OddRotationState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
