// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'abcd_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AbcdNotifier)
final abcdProvider = AbcdNotifierProvider._();

final class AbcdNotifierProvider
    extends $NotifierProvider<AbcdNotifier, AbcdState> {
  AbcdNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'abcdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$abcdNotifierHash();

  @$internal
  @override
  AbcdNotifier create() => AbcdNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AbcdState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AbcdState>(value),
    );
  }
}

String _$abcdNotifierHash() => r'a3062447e6dfa0e61f6f84293c9978aa5c98783e';

abstract class _$AbcdNotifier extends $Notifier<AbcdState> {
  AbcdState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AbcdState, AbcdState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AbcdState, AbcdState>,
              AbcdState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
