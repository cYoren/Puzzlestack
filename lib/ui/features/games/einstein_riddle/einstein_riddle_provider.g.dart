// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'einstein_riddle_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EinsteinRiddleNotifier)
final einsteinRiddleProvider = EinsteinRiddleNotifierProvider._();

final class EinsteinRiddleNotifierProvider
    extends $NotifierProvider<EinsteinRiddleNotifier, EinsteinRiddleState> {
  EinsteinRiddleNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'einsteinRiddleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$einsteinRiddleNotifierHash();

  @$internal
  @override
  EinsteinRiddleNotifier create() => EinsteinRiddleNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EinsteinRiddleState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EinsteinRiddleState>(value),
    );
  }
}

String _$einsteinRiddleNotifierHash() =>
    r'49f40c5aed9a7262f32877ffa0e061b38812d3a5';

abstract class _$EinsteinRiddleNotifier extends $Notifier<EinsteinRiddleState> {
  EinsteinRiddleState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EinsteinRiddleState, EinsteinRiddleState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EinsteinRiddleState, EinsteinRiddleState>,
              EinsteinRiddleState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
