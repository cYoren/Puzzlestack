// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'twiddle_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TwiddleNotifier)
final twiddleProvider = TwiddleNotifierProvider._();

final class TwiddleNotifierProvider
    extends $NotifierProvider<TwiddleNotifier, TwiddleState> {
  TwiddleNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'twiddleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$twiddleNotifierHash();

  @$internal
  @override
  TwiddleNotifier create() => TwiddleNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TwiddleState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TwiddleState>(value),
    );
  }
}

String _$twiddleNotifierHash() => r'dd53a8315b38752d6622ddf08e2fe6e9a8cd2f58';

abstract class _$TwiddleNotifier extends $Notifier<TwiddleState> {
  TwiddleState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TwiddleState, TwiddleState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TwiddleState, TwiddleState>,
              TwiddleState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
