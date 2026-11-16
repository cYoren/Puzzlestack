// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'double_n_back_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DoubleNBackNotifier)
final doubleNBackProvider = DoubleNBackNotifierProvider._();

final class DoubleNBackNotifierProvider
    extends $NotifierProvider<DoubleNBackNotifier, DoubleNBackState> {
  DoubleNBackNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'doubleNBackProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$doubleNBackNotifierHash();

  @$internal
  @override
  DoubleNBackNotifier create() => DoubleNBackNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DoubleNBackState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DoubleNBackState>(value),
    );
  }
}

String _$doubleNBackNotifierHash() =>
    r'6a7df450d8f36c4ddd511997bfd3c6c8cd267c83';

abstract class _$DoubleNBackNotifier extends $Notifier<DoubleNBackState> {
  DoubleNBackState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DoubleNBackState, DoubleNBackState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DoubleNBackState, DoubleNBackState>,
              DoubleNBackState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
