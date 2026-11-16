// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'missing_operator_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MissingOperatorNotifier)
final missingOperatorProvider = MissingOperatorNotifierProvider._();

final class MissingOperatorNotifierProvider
    extends $NotifierProvider<MissingOperatorNotifier, MissingOperatorState> {
  MissingOperatorNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'missingOperatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$missingOperatorNotifierHash();

  @$internal
  @override
  MissingOperatorNotifier create() => MissingOperatorNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MissingOperatorState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MissingOperatorState>(value),
    );
  }
}

String _$missingOperatorNotifierHash() =>
    r'ee30da6922a769be18c83e30ad87d96e30b2cded';

abstract class _$MissingOperatorNotifier
    extends $Notifier<MissingOperatorState> {
  MissingOperatorState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MissingOperatorState, MissingOperatorState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MissingOperatorState, MissingOperatorState>,
              MissingOperatorState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
