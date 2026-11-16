// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'syllable_stack_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SyllableStackNotifier)
final syllableStackProvider = SyllableStackNotifierProvider._();

final class SyllableStackNotifierProvider
    extends $NotifierProvider<SyllableStackNotifier, SyllableStackState> {
  SyllableStackNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syllableStackProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syllableStackNotifierHash();

  @$internal
  @override
  SyllableStackNotifier create() => SyllableStackNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyllableStackState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyllableStackState>(value),
    );
  }
}

String _$syllableStackNotifierHash() =>
    r'ee920a851802fb939d35259b8aebd60911d03aaa';

abstract class _$SyllableStackNotifier extends $Notifier<SyllableStackState> {
  SyllableStackState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SyllableStackState, SyllableStackState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SyllableStackState, SyllableStackState>,
              SyllableStackState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
