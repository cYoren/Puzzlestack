// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'symbolic_flanker_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SymbolicFlankerNotifier)
final symbolicFlankerProvider = SymbolicFlankerNotifierProvider._();

final class SymbolicFlankerNotifierProvider
    extends $NotifierProvider<SymbolicFlankerNotifier, SymbolicFlankerState> {
  SymbolicFlankerNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'symbolicFlankerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$symbolicFlankerNotifierHash();

  @$internal
  @override
  SymbolicFlankerNotifier create() => SymbolicFlankerNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SymbolicFlankerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SymbolicFlankerState>(value),
    );
  }
}

String _$symbolicFlankerNotifierHash() =>
    r'4ed69ff9870021597a6d20d6d126b4f882015015';

abstract class _$SymbolicFlankerNotifier
    extends $Notifier<SymbolicFlankerState> {
  SymbolicFlankerState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SymbolicFlankerState, SymbolicFlankerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SymbolicFlankerState, SymbolicFlankerState>,
              SymbolicFlankerState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
