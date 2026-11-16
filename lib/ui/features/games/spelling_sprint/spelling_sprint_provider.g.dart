// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spelling_sprint_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SpellingSprintNotifier)
final spellingSprintProvider = SpellingSprintNotifierProvider._();

final class SpellingSprintNotifierProvider
    extends $NotifierProvider<SpellingSprintNotifier, SpellingSprintState> {
  SpellingSprintNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'spellingSprintProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$spellingSprintNotifierHash();

  @$internal
  @override
  SpellingSprintNotifier create() => SpellingSprintNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SpellingSprintState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SpellingSprintState>(value),
    );
  }
}

String _$spellingSprintNotifierHash() =>
    r'22b69e9f6f9ca331c6cdbf8f7e99796a4ea5eab1';

abstract class _$SpellingSprintNotifier extends $Notifier<SpellingSprintState> {
  SpellingSprintState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SpellingSprintState, SpellingSprintState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SpellingSprintState, SpellingSprintState>,
              SpellingSprintState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
