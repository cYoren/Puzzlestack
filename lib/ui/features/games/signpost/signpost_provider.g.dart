// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signpost_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SignpostNotifier)
final signpostProvider = SignpostNotifierProvider._();

final class SignpostNotifierProvider
    extends $NotifierProvider<SignpostNotifier, SignpostState> {
  SignpostNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signpostProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signpostNotifierHash();

  @$internal
  @override
  SignpostNotifier create() => SignpostNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignpostState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignpostState>(value),
    );
  }
}

String _$signpostNotifierHash() => r'40129f46e681245669e8c1aeadbc56a530c950fe';

abstract class _$SignpostNotifier extends $Notifier<SignpostState> {
  SignpostState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SignpostState, SignpostState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SignpostState, SignpostState>,
              SignpostState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
