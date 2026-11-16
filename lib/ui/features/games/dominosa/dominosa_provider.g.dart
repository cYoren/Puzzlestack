// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dominosa_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DominosaNotifier)
final dominosaProvider = DominosaNotifierProvider._();

final class DominosaNotifierProvider
    extends $NotifierProvider<DominosaNotifier, DominosaState> {
  DominosaNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dominosaProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dominosaNotifierHash();

  @$internal
  @override
  DominosaNotifier create() => DominosaNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DominosaState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DominosaState>(value),
    );
  }
}

String _$dominosaNotifierHash() => r'1b33f1d1e601667ba4371e39782e5ca7e77b7b50';

abstract class _$DominosaNotifier extends $Notifier<DominosaState> {
  DominosaState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DominosaState, DominosaState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DominosaState, DominosaState>,
              DominosaState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
