// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'perspective_taking_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PerspectiveTakingNotifier)
final perspectiveTakingProvider = PerspectiveTakingNotifierProvider._();

final class PerspectiveTakingNotifierProvider
    extends
        $NotifierProvider<PerspectiveTakingNotifier, PerspectiveTakingState> {
  PerspectiveTakingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'perspectiveTakingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$perspectiveTakingNotifierHash();

  @$internal
  @override
  PerspectiveTakingNotifier create() => PerspectiveTakingNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PerspectiveTakingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PerspectiveTakingState>(value),
    );
  }
}

String _$perspectiveTakingNotifierHash() =>
    r'a385a8dfc09eb46225a6e7718495c98202c905e8';

abstract class _$PerspectiveTakingNotifier
    extends $Notifier<PerspectiveTakingState> {
  PerspectiveTakingState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<PerspectiveTakingState, PerspectiveTakingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PerspectiveTakingState, PerspectiveTakingState>,
              PerspectiveTakingState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
