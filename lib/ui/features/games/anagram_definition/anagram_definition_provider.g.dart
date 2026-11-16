// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anagram_definition_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AnagramDefinitionNotifier)
final anagramDefinitionProvider = AnagramDefinitionNotifierProvider._();

final class AnagramDefinitionNotifierProvider
    extends
        $NotifierProvider<AnagramDefinitionNotifier, AnagramDefinitionState> {
  AnagramDefinitionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'anagramDefinitionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$anagramDefinitionNotifierHash();

  @$internal
  @override
  AnagramDefinitionNotifier create() => AnagramDefinitionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnagramDefinitionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnagramDefinitionState>(value),
    );
  }
}

String _$anagramDefinitionNotifierHash() =>
    r'd792a79d7658a6335a0633ab4a00bf461a8e6a4c';

abstract class _$AnagramDefinitionNotifier
    extends $Notifier<AnagramDefinitionState> {
  AnagramDefinitionState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AnagramDefinitionState, AnagramDefinitionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AnagramDefinitionState, AnagramDefinitionState>,
              AnagramDefinitionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
