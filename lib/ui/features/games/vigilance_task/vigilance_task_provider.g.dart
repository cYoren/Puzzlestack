// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vigilance_task_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VigilanceNotifier)
final vigilanceProvider = VigilanceNotifierProvider._();

final class VigilanceNotifierProvider
    extends $NotifierProvider<VigilanceNotifier, VigilanceState> {
  VigilanceNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vigilanceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vigilanceNotifierHash();

  @$internal
  @override
  VigilanceNotifier create() => VigilanceNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VigilanceState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VigilanceState>(value),
    );
  }
}

String _$vigilanceNotifierHash() => r'57c165955f885e060b7ee31ed85668725d954535';

abstract class _$VigilanceNotifier extends $Notifier<VigilanceState> {
  VigilanceState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<VigilanceState, VigilanceState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VigilanceState, VigilanceState>,
              VigilanceState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
