// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reverse_stroop_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ReverseStroopNotifier)
final reverseStroopProvider = ReverseStroopNotifierProvider._();

final class ReverseStroopNotifierProvider
    extends $NotifierProvider<ReverseStroopNotifier, ReverseStroopState> {
  ReverseStroopNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reverseStroopProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reverseStroopNotifierHash();

  @$internal
  @override
  ReverseStroopNotifier create() => ReverseStroopNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReverseStroopState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReverseStroopState>(value),
    );
  }
}

String _$reverseStroopNotifierHash() =>
    r'd91087fff2db72549c2a67654635deaf6fb3dffb';

abstract class _$ReverseStroopNotifier extends $Notifier<ReverseStroopState> {
  ReverseStroopState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ReverseStroopState, ReverseStroopState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReverseStroopState, ReverseStroopState>,
              ReverseStroopState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
