import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../local/app_database.dart';
import 'mutation_gateway.dart';
import '../network/node_backend_client.dart';

class SupabaseMutationGateway implements MutationGateway {
  const SupabaseMutationGateway(this._client, this._backend);

  final SupabaseClient _client;

  /// Only commit-meal moved to the Node backend; apply_meal_operation is
  /// still an RPC against Postgres, so this gateway needs both.
  final NodeBackendClient _backend;

  @override
  Future<MutationResult> execute(SyncOperation operation) async {
    if (operation.operationType == 'commit') {
      return _commitAnalyzedMeal(operation);
    }
    try {
      final response = await _client.rpc(
        'apply_meal_operation',
        params: {
          'p_operation_id': operation.id,
          'p_operation_type': operation.operationType,
          'p_payload': jsonDecode(operation.payloadJson),
        },
      );
      final result = response as Map<String, dynamic>;
      return MutationResult(
        mealId: result['meal_id'] as String?,
        rowVersion: result['row_version'] as int?,
      );
    } on PostgrestException catch (error) {
      throw _classify(error);
    } catch (_) {
      throw const SyncFailure(
        kind: SyncFailureKind.transient,
        code: 'network_or_provider_unavailable',
      );
    }
  }

  Future<MutationResult> _commitAnalyzedMeal(SyncOperation operation) async {
    try {
      final response = await _backend.invoke(
        'commit-meal',
        body: jsonDecode(operation.payloadJson),
      );
      final result = response.data as Map<String, dynamic>;
      if (result['contractVersion'] != 'meal-commit.v1') {
        throw const SyncFailure(
          kind: SyncFailureKind.transient,
          code: 'invalid_commit_contract',
        );
      }
      return MutationResult(
        mealId: result['mealId'] as String?,
        rowVersion: result['rowVersion'] as int?,
      );
    } on FunctionException catch (error) {
      throw _classifyFunction(error);
    } on SyncFailure {
      rethrow;
    } catch (_) {
      throw const SyncFailure(
        kind: SyncFailureKind.transient,
        code: 'commit_network_unavailable',
      );
    }
  }

  SyncFailure _classifyFunction(FunctionException error) {
    final details = error.details;
    final envelope = details is Map ? details['error'] : null;
    final body = envelope is Map ? envelope : const {};
    final code = body['code']?.toString() ?? 'function_${error.status}';
    final kind = switch (error.status) {
      400 || 422 => SyncFailureKind.validation,
      401 || 403 => SyncFailureKind.forbidden,
      409 => SyncFailureKind.conflict,
      0 || 408 || 429 || >= 500 => SyncFailureKind.transient,
      _ => SyncFailureKind.unknown,
    };
    return SyncFailure(kind: kind, code: code);
  }

  SyncFailure _classify(PostgrestException error) {
    final code = error.code ?? 'postgrest_unknown';
    if (code == '42501' || code == 'PGRST301') {
      return SyncFailure(kind: SyncFailureKind.forbidden, code: code);
    }
    if (code == '23505' || code == '40001') {
      return SyncFailure(kind: SyncFailureKind.conflict, code: code);
    }
    if (code == '23514' || code == '22P02' || code == '22023') {
      return SyncFailure(kind: SyncFailureKind.validation, code: code);
    }
    if (code.startsWith('08') || code.startsWith('PGRST0')) {
      return SyncFailure(kind: SyncFailureKind.transient, code: code);
    }
    return SyncFailure(kind: SyncFailureKind.unknown, code: code);
  }
}
