// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phonetic_guess_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PhoneticGuessNotifier)
final phoneticGuessProvider = PhoneticGuessNotifierProvider._();

final class PhoneticGuessNotifierProvider
    extends $NotifierProvider<PhoneticGuessNotifier, PhoneticGuessState> {
  PhoneticGuessNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'phoneticGuessProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$phoneticGuessNotifierHash();

  @$internal
  @override
  PhoneticGuessNotifier create() => PhoneticGuessNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhoneticGuessState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhoneticGuessState>(value),
    );
  }
}

String _$phoneticGuessNotifierHash() =>
    r'2531eef0fee593a42b211cfa6e0311aa4c4371c1';

abstract class _$PhoneticGuessNotifier extends $Notifier<PhoneticGuessState> {
  PhoneticGuessState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PhoneticGuessState, PhoneticGuessState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PhoneticGuessState, PhoneticGuessState>,
              PhoneticGuessState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
