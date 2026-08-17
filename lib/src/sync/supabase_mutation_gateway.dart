import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../local/app_database.dart';
import 'mutation_gateway.dart';

class SupabaseMutationGateway implements MutationGateway {
  const SupabaseMutationGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<void> execute(SyncOperation operation) async {
    try {
      await _client.rpc(
        'apply_meal_operation',
        params: {
          'p_operation_id': operation.id,
          'p_operation_type': operation.operationType,
          'p_payload': jsonDecode(operation.payloadJson),
        },
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
