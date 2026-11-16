// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ascent_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AscentNotifier)
final ascentProvider = AscentNotifierProvider._();

final class AscentNotifierProvider
    extends $NotifierProvider<AscentNotifier, AscentState> {
  AscentNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ascentProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ascentNotifierHash();

  @$internal
  @override
  AscentNotifier create() => AscentNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AscentState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AscentState>(value),
    );
  }
}

String _$ascentNotifierHash() => r'fc229e17025b3358f1832cd9c2ac3a64440cab6a';

abstract class _$AscentNotifier extends $Notifier<AscentState> {
  AscentState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AscentState, AscentState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AscentState, AscentState>,
              AscentState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
