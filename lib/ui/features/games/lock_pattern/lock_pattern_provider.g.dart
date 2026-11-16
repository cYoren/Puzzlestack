// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lock_pattern_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LockPatternNotifier)
final lockPatternProvider = LockPatternNotifierProvider._();

final class LockPatternNotifierProvider
    extends $NotifierProvider<LockPatternNotifier, LockPatternState> {
  LockPatternNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lockPatternProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lockPatternNotifierHash();

  @$internal
  @override
  LockPatternNotifier create() => LockPatternNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LockPatternState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LockPatternState>(value),
    );
  }
}

String _$lockPatternNotifierHash() =>
    r'b49047caba79fd09691ff19089c9950c97980b51';

abstract class _$LockPatternNotifier extends $Notifier<LockPatternState> {
  LockPatternState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LockPatternState, LockPatternState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LockPatternState, LockPatternState>,
              LockPatternState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
