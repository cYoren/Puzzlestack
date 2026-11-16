// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'missing_vowels_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MissingVowelsNotifier)
final missingVowelsProvider = MissingVowelsNotifierProvider._();

final class MissingVowelsNotifierProvider
    extends $NotifierProvider<MissingVowelsNotifier, MissingVowelsState> {
  MissingVowelsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'missingVowelsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$missingVowelsNotifierHash();

  @$internal
  @override
  MissingVowelsNotifier create() => MissingVowelsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MissingVowelsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MissingVowelsState>(value),
    );
  }
}

String _$missingVowelsNotifierHash() =>
    r'90a9319522d30874fe6d3b35018e645fce6c1a60';

abstract class _$MissingVowelsNotifier extends $Notifier<MissingVowelsState> {
  MissingVowelsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MissingVowelsState, MissingVowelsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MissingVowelsState, MissingVowelsState>,
              MissingVowelsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
