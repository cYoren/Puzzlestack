// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'boats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BoatsNotifier)
final boatsProvider = BoatsNotifierProvider._();

final class BoatsNotifierProvider
    extends $NotifierProvider<BoatsNotifier, BoatsState> {
  BoatsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'boatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$boatsNotifierHash();

  @$internal
  @override
  BoatsNotifier create() => BoatsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BoatsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BoatsState>(value),
    );
  }
}

String _$boatsNotifierHash() => r'ff92d2c1e8e2584f5128c8e0f2a81b781efcd96a';

abstract class _$BoatsNotifier extends $Notifier<BoatsState> {
  BoatsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BoatsState, BoatsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BoatsState, BoatsState>,
              BoatsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
