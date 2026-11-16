// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collatz_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CollatzNotifier)
final collatzProvider = CollatzNotifierProvider._();

final class CollatzNotifierProvider
    extends $NotifierProvider<CollatzNotifier, CollatzState> {
  CollatzNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'collatzProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$collatzNotifierHash();

  @$internal
  @override
  CollatzNotifier create() => CollatzNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CollatzState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CollatzState>(value),
    );
  }
}

String _$collatzNotifierHash() => r'0415a97deb1ab7429e8ba64ee8619d27463c7fd5';

abstract class _$CollatzNotifier extends $Notifier<CollatzState> {
  CollatzState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CollatzState, CollatzState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CollatzState, CollatzState>,
              CollatzState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
