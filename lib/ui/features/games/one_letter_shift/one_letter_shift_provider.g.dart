// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'one_letter_shift_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OneLetterShiftNotifier)
final oneLetterShiftProvider = OneLetterShiftNotifierProvider._();

final class OneLetterShiftNotifierProvider
    extends $NotifierProvider<OneLetterShiftNotifier, OneLetterShiftState> {
  OneLetterShiftNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'oneLetterShiftProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$oneLetterShiftNotifierHash();

  @$internal
  @override
  OneLetterShiftNotifier create() => OneLetterShiftNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OneLetterShiftState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OneLetterShiftState>(value),
    );
  }
}

String _$oneLetterShiftNotifierHash() =>
    r'2b4f94e8aa5e6f4822fba0b87884772decd965b2';

abstract class _$OneLetterShiftNotifier extends $Notifier<OneLetterShiftState> {
  OneLetterShiftState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<OneLetterShiftState, OneLetterShiftState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OneLetterShiftState, OneLetterShiftState>,
              OneLetterShiftState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
