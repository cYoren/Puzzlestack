// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'math_guess_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MathGuessNotifier)
final mathGuessProvider = MathGuessNotifierProvider._();

final class MathGuessNotifierProvider
    extends $NotifierProvider<MathGuessNotifier, MathGuessState> {
  MathGuessNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mathGuessProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mathGuessNotifierHash();

  @$internal
  @override
  MathGuessNotifier create() => MathGuessNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MathGuessState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MathGuessState>(value),
    );
  }
}

String _$mathGuessNotifierHash() => r'8cb03a12b8e496f5e8b6a5d57a68d2fb480bf9c9';

abstract class _$MathGuessNotifier extends $Notifier<MathGuessState> {
  MathGuessState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MathGuessState, MathGuessState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MathGuessState, MathGuessState>,
              MathGuessState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
