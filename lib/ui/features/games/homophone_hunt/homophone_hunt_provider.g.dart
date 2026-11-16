// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'homophone_hunt_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HomophoneHuntNotifier)
final homophoneHuntProvider = HomophoneHuntNotifierProvider._();

final class HomophoneHuntNotifierProvider
    extends $NotifierProvider<HomophoneHuntNotifier, HomophoneHuntState> {
  HomophoneHuntNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homophoneHuntProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homophoneHuntNotifierHash();

  @$internal
  @override
  HomophoneHuntNotifier create() => HomophoneHuntNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomophoneHuntState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomophoneHuntState>(value),
    );
  }
}

String _$homophoneHuntNotifierHash() =>
    r'272e621408feb3c08bce830b710f92cd09822fd7';

abstract class _$HomophoneHuntNotifier extends $Notifier<HomophoneHuntState> {
  HomophoneHuntState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<HomophoneHuntState, HomophoneHuntState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HomophoneHuntState, HomophoneHuntState>,
              HomophoneHuntState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
