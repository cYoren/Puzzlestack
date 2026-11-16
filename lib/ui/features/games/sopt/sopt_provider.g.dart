// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sopt_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SoptNotifier)
final soptProvider = SoptNotifierProvider._();

final class SoptNotifierProvider
    extends $NotifierProvider<SoptNotifier, SoptState> {
  SoptNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'soptProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$soptNotifierHash();

  @$internal
  @override
  SoptNotifier create() => SoptNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SoptState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SoptState>(value),
    );
  }
}

String _$soptNotifierHash() => r'e8327dd2b918260f58636cf97c8c086ce263a000';

abstract class _$SoptNotifier extends $Notifier<SoptState> {
  SoptState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SoptState, SoptState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SoptState, SoptState>,
              SoptState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
