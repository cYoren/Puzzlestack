// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grammar_sort_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GrammarSortNotifier)
final grammarSortProvider = GrammarSortNotifierProvider._();

final class GrammarSortNotifierProvider
    extends $NotifierProvider<GrammarSortNotifier, GrammarSortState> {
  GrammarSortNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'grammarSortProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$grammarSortNotifierHash();

  @$internal
  @override
  GrammarSortNotifier create() => GrammarSortNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GrammarSortState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GrammarSortState>(value),
    );
  }
}

String _$grammarSortNotifierHash() =>
    r'd02c09f05d8ec909fa615f4b4d5976be21562731';

abstract class _$GrammarSortNotifier extends $Notifier<GrammarSortState> {
  GrammarSortState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<GrammarSortState, GrammarSortState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GrammarSortState, GrammarSortState>,
              GrammarSortState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
