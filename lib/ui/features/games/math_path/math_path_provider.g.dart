// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'math_path_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MathPathNotifier)
final mathPathProvider = MathPathNotifierProvider._();

final class MathPathNotifierProvider
    extends $NotifierProvider<MathPathNotifier, MathPathState> {
  MathPathNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mathPathProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mathPathNotifierHash();

  @$internal
  @override
  MathPathNotifier create() => MathPathNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MathPathState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MathPathState>(value),
    );
  }
}

String _$mathPathNotifierHash() => r'5a9163d6bb443bd052c1752007c292c6dd5937e8';

abstract class _$MathPathNotifier extends $Notifier<MathPathState> {
  MathPathState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MathPathState, MathPathState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MathPathState, MathPathState>,
              MathPathState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
