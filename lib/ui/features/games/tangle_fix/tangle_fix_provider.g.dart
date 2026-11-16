// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tangle_fix_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TangleFixNotifier)
final tangleFixProvider = TangleFixNotifierProvider._();

final class TangleFixNotifierProvider
    extends $NotifierProvider<TangleFixNotifier, TangleFixState> {
  TangleFixNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tangleFixProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tangleFixNotifierHash();

  @$internal
  @override
  TangleFixNotifier create() => TangleFixNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TangleFixState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TangleFixState>(value),
    );
  }
}

String _$tangleFixNotifierHash() => r'44d2ec4f582eca69b285e4256b2145bb8a7330ce';

abstract class _$TangleFixNotifier extends $Notifier<TangleFixState> {
  TangleFixState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TangleFixState, TangleFixState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TangleFixState, TangleFixState>,
              TangleFixState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
