import 'dart:developer';

import 'package:erad/core/errors/failures.dart';
import 'package:erad/core/services/user_service.dart';
import 'package:erad/features/comparison_points/data/models/comparison_point_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComparisonPointRemoteDataSource {
  final SupabaseClient supabaseClient;

  ComparisonPointRemoteDataSource(this.supabaseClient);

  Future<String> _requireUserId() async {
    final userId = await UserService.getUserId();
    if (userId == null || userId.isEmpty) {
      throw const AuthFailure('User not authenticated');
    }
    return userId;
  }

  String _partyColumn(ComparisonPartyType partyType) =>
      partyType == ComparisonPartyType.customer ? 'customer_id' : 'supplier_id';

  Future<List<ComparisonPointModel>> getPoints({
    required ComparisonPartyType partyType,
    required String partyId,
  }) async {
    try {
      final userId = await _requireUserId();
      final response = await supabaseClient
          .from('view_comparison_points')
          .select('*')
          .eq('user_id', userId)
          .eq('party_type', partyType.value)
          .eq(_partyColumn(partyType), partyId)
          .order('sequence_no', ascending: true);

      return (response as List)
          .map(
            (row) => ComparisonPointModel.fromMap(row as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      log(e.toString());
      throw exceptionToFailure(e);
    }
  }

  Future<List<Map<String, dynamic>>> getPointInvoices(String pointId) async {
    try {
      final userId = await _requireUserId();
      final response = await supabaseClient
          .from('view_comparison_point_invoices')
          .select('*')
          .eq('user_id', userId)
          .eq('point_id', pointId)
          .order('invoice_date', ascending: true)
          .order('invoice_created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      log(e.toString());
      throw exceptionToFailure(e);
    }
  }

  Future<List<Map<String, dynamic>>> getPointPayments(String pointId) async {
    try {
      final userId = await _requireUserId();
      final response = await supabaseClient
          .from('view_comparison_point_payments')
          .select('*')
          .eq('user_id', userId)
          .eq('point_id', pointId)
          .order('payment_date', ascending: true)
          .order('payment_created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      log(e.toString());
      throw exceptionToFailure(e);
    }
  }

  Future<List<Map<String, dynamic>>> getUnassignedInvoices({
    required ComparisonPartyType partyType,
    required String partyId,
  }) async {
    try {
      final userId = await _requireUserId();
      final response = await supabaseClient
          .from('view_unassigned_debt_invoices')
          .select('*')
          .eq('user_id', userId)
          .eq('party_type', partyType.value)
          .eq('party_id', partyId)
          .order('created_at', ascending: true)
          .order('invoice_id', ascending: true);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      log(e.toString());
      throw exceptionToFailure(e);
    }
  }

  Future<void> ensureStartPoint({
    required ComparisonPartyType partyType,
    required String partyId,
  }) async {
    try {
      await _requireUserId();
      await supabaseClient.rpc(
        'ensure_debt_comparison_start_point',
        params: {'p_party_type': partyType.value, 'p_party_id': partyId},
      );
    } catch (e) {
      log(e.toString());
      throw exceptionToFailure(e);
    }
  }

  Future<String> createPoint({
    required ComparisonPartyType partyType,
    required String partyId,
    required String anchorInvoiceId,
    String? label,
    String? notes,
  }) async {
    try {
      await _requireUserId();
      final response = await supabaseClient.rpc(
        'create_debt_comparison_point',
        params: {
          'p_party_type': partyType.value,
          'p_party_id': partyId,
          'p_anchor_invoice_id': anchorInvoiceId,
          'p_label': label,
          'p_notes': notes,
        },
      );
      return response as String;
    } on PostgrestException catch (e) {
      log(e.toString());
      throw ServerFailure(e.message);
    } catch (e) {
      log(e.toString());
      throw exceptionToFailure(e);
    }
  }
}
