// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'go_no_go_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GoNoGoNotifier)
final goNoGoProvider = GoNoGoNotifierProvider._();

final class GoNoGoNotifierProvider
    extends $NotifierProvider<GoNoGoNotifier, GoNoGoState> {
  GoNoGoNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goNoGoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goNoGoNotifierHash();

  @$internal
  @override
  GoNoGoNotifier create() => GoNoGoNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoNoGoState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoNoGoState>(value),
    );
  }
}

String _$goNoGoNotifierHash() => r'335742dff08fa616c9df5d7a4091b6b59690290a';

abstract class _$GoNoGoNotifier extends $Notifier<GoNoGoState> {
  GoNoGoState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<GoNoGoState, GoNoGoState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GoNoGoState, GoNoGoState>,
              GoNoGoState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
