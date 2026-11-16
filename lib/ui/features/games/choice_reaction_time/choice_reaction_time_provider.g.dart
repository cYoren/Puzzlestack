// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'choice_reaction_time_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChoiceReactionTimeNotifier)
final choiceReactionTimeProvider = ChoiceReactionTimeNotifierProvider._();

final class ChoiceReactionTimeNotifierProvider
    extends
        $NotifierProvider<ChoiceReactionTimeNotifier, ChoiceReactionTimeState> {
  ChoiceReactionTimeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'choiceReactionTimeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$choiceReactionTimeNotifierHash();

  @$internal
  @override
  ChoiceReactionTimeNotifier create() => ChoiceReactionTimeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChoiceReactionTimeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChoiceReactionTimeState>(value),
    );
  }
}

String _$choiceReactionTimeNotifierHash() =>
    r'661a5cfeaa8292fd8ada15db5bdcb82aa806bd3f';

abstract class _$ChoiceReactionTimeNotifier
    extends $Notifier<ChoiceReactionTimeState> {
  ChoiceReactionTimeState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<ChoiceReactionTimeState, ChoiceReactionTimeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChoiceReactionTimeState, ChoiceReactionTimeState>,
              ChoiceReactionTimeState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
