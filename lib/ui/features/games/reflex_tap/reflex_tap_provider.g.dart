// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reflex_tap_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ReflexTapNotifier)
final reflexTapProvider = ReflexTapNotifierProvider._();

final class ReflexTapNotifierProvider
    extends $NotifierProvider<ReflexTapNotifier, ReflexTapState> {
  ReflexTapNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reflexTapProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reflexTapNotifierHash();

  @$internal
  @override
  ReflexTapNotifier create() => ReflexTapNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReflexTapState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReflexTapState>(value),
    );
  }
}

String _$reflexTapNotifierHash() => r'69be91a091f7372358ec598e13ebdac769cf363f';

abstract class _$ReflexTapNotifier extends $Notifier<ReflexTapState> {
  ReflexTapState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ReflexTapState, ReflexTapState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReflexTapState, ReflexTapState>,
              ReflexTapState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
