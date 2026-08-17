import '../local/app_database.dart';

enum SyncFailureKind { transient, validation, forbidden, conflict, unknown }

class SyncFailure implements Exception {
  const SyncFailure({required this.kind, required this.code});

  final SyncFailureKind kind;
  final String code;

  bool get isRetryable => kind == SyncFailureKind.transient;
}

abstract interface class MutationGateway {
  Future<void> execute(SyncOperation operation);
}
