// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stop_signal_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(StopSignalNotifier)
final stopSignalProvider = StopSignalNotifierProvider._();

final class StopSignalNotifierProvider
    extends $NotifierProvider<StopSignalNotifier, StopSignalState> {
  StopSignalNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stopSignalProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stopSignalNotifierHash();

  @$internal
  @override
  StopSignalNotifier create() => StopSignalNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StopSignalState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StopSignalState>(value),
    );
  }
}

String _$stopSignalNotifierHash() =>
    r'4276b0d605fe1542308816736971fb980f499a1c';

abstract class _$StopSignalNotifier extends $Notifier<StopSignalState> {
  StopSignalState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<StopSignalState, StopSignalState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<StopSignalState, StopSignalState>,
              StopSignalState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
