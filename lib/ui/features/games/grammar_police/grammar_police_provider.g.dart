// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grammar_police_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GrammarPoliceNotifier)
final grammarPoliceProvider = GrammarPoliceNotifierProvider._();

final class GrammarPoliceNotifierProvider
    extends $NotifierProvider<GrammarPoliceNotifier, GrammarPoliceState> {
  GrammarPoliceNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'grammarPoliceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$grammarPoliceNotifierHash();

  @$internal
  @override
  GrammarPoliceNotifier create() => GrammarPoliceNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GrammarPoliceState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GrammarPoliceState>(value),
    );
  }
}

String _$grammarPoliceNotifierHash() =>
    r'bda127903cc33244a4681d3f435558cc931f719e';

abstract class _$GrammarPoliceNotifier extends $Notifier<GrammarPoliceState> {
  GrammarPoliceState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<GrammarPoliceState, GrammarPoliceState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GrammarPoliceState, GrammarPoliceState>,
              GrammarPoliceState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
