// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crossword_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CrosswordNotifier)
final crosswordProvider = CrosswordNotifierProvider._();

final class CrosswordNotifierProvider
    extends $NotifierProvider<CrosswordNotifier, CrosswordState> {
  CrosswordNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'crosswordProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$crosswordNotifierHash();

  @$internal
  @override
  CrosswordNotifier create() => CrosswordNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CrosswordState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CrosswordState>(value),
    );
  }
}

String _$crosswordNotifierHash() => r'9fc8a01e4414d69c256e4f7e69599d0fc32c7597';

abstract class _$CrosswordNotifier extends $Notifier<CrosswordState> {
  CrosswordState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CrosswordState, CrosswordState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CrosswordState, CrosswordState>,
              CrosswordState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
