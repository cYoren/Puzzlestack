// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hitori_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HitoriNotifier)
final hitoriProvider = HitoriNotifierProvider._();

final class HitoriNotifierProvider
    extends $NotifierProvider<HitoriNotifier, HitoriState> {
  HitoriNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hitoriProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hitoriNotifierHash();

  @$internal
  @override
  HitoriNotifier create() => HitoriNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HitoriState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HitoriState>(value),
    );
  }
}

String _$hitoriNotifierHash() => r'a9f6b22f6080ec8b375bb34ecbe834ae9d6ee5c2';

abstract class _$HitoriNotifier extends $Notifier<HitoriState> {
  HitoriState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<HitoriState, HitoriState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HitoriState, HitoriState>,
              HitoriState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
