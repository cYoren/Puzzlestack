// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_math_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(QuickMathNotifier)
final quickMathProvider = QuickMathNotifierProvider._();

final class QuickMathNotifierProvider
    extends $NotifierProvider<QuickMathNotifier, QuickMathState> {
  QuickMathNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickMathProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quickMathNotifierHash();

  @$internal
  @override
  QuickMathNotifier create() => QuickMathNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuickMathState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuickMathState>(value),
    );
  }
}

String _$quickMathNotifierHash() => r'6d4b1b73296a62cc4ca5ad968c9555ae5ef5bb8e';

abstract class _$QuickMathNotifier extends $Notifier<QuickMathState> {
  QuickMathState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<QuickMathState, QuickMathState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<QuickMathState, QuickMathState>,
              QuickMathState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
