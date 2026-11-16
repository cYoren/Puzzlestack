// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verbal_analogies_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VerbalAnalogiesNotifier)
final verbalAnalogiesProvider = VerbalAnalogiesNotifierProvider._();

final class VerbalAnalogiesNotifierProvider
    extends $NotifierProvider<VerbalAnalogiesNotifier, VerbalAnalogiesState> {
  VerbalAnalogiesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'verbalAnalogiesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$verbalAnalogiesNotifierHash();

  @$internal
  @override
  VerbalAnalogiesNotifier create() => VerbalAnalogiesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VerbalAnalogiesState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VerbalAnalogiesState>(value),
    );
  }
}

String _$verbalAnalogiesNotifierHash() =>
    r'2ba751886752c0953a9fa7369ff9631853ee3d06';

abstract class _$VerbalAnalogiesNotifier
    extends $Notifier<VerbalAnalogiesState> {
  VerbalAnalogiesState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<VerbalAnalogiesState, VerbalAnalogiesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VerbalAnalogiesState, VerbalAnalogiesState>,
              VerbalAnalogiesState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
