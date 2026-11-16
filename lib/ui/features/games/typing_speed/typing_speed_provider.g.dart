// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'typing_speed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TypingSpeedNotifier)
final typingSpeedProvider = TypingSpeedNotifierProvider._();

final class TypingSpeedNotifierProvider
    extends $NotifierProvider<TypingSpeedNotifier, TypingSpeedState> {
  TypingSpeedNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'typingSpeedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$typingSpeedNotifierHash();

  @$internal
  @override
  TypingSpeedNotifier create() => TypingSpeedNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TypingSpeedState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TypingSpeedState>(value),
    );
  }
}

String _$typingSpeedNotifierHash() =>
    r'815e35e1acdc290c8660bc4d76c23c72a53b766b';

abstract class _$TypingSpeedNotifier extends $Notifier<TypingSpeedState> {
  TypingSpeedState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TypingSpeedState, TypingSpeedState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TypingSpeedState, TypingSpeedState>,
              TypingSpeedState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
