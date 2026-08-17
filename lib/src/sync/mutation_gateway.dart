import '../local/app_database.dart';

enum SyncFailureKind { transient, validation, forbidden, conflict, unknown }

class SyncFailure implements Exception {
  const SyncFailure({required this.kind, required this.code});

  final SyncFailureKind kind;
  final String code;

  bool get isRetryable => kind == SyncFailureKind.transient;
}

abstract interface class MutationGateway {
  Future<MutationResult> execute(SyncOperation operation);
}

class MutationResult {
  const MutationResult({this.mealId, this.rowVersion});

  final String? mealId;
  final int? rowVersion;
}
