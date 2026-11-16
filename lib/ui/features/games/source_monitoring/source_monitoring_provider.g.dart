// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'source_monitoring_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SourceMonitoringNotifier)
final sourceMonitoringProvider = SourceMonitoringNotifierProvider._();

final class SourceMonitoringNotifierProvider
    extends $NotifierProvider<SourceMonitoringNotifier, SourceMonitoringState> {
  SourceMonitoringNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sourceMonitoringProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sourceMonitoringNotifierHash();

  @$internal
  @override
  SourceMonitoringNotifier create() => SourceMonitoringNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SourceMonitoringState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SourceMonitoringState>(value),
    );
  }
}

String _$sourceMonitoringNotifierHash() =>
    r'd380155ef07b3cb3a93352bee77b8414c80d471b';

abstract class _$SourceMonitoringNotifier
    extends $Notifier<SourceMonitoringState> {
  SourceMonitoringState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SourceMonitoringState, SourceMonitoringState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SourceMonitoringState, SourceMonitoringState>,
              SourceMonitoringState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
