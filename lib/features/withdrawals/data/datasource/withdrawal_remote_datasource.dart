import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/withdrawal.dart';
import '../models/partner.dart';
import '../models/withdrawal_summary.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/paged_result.dart';

abstract class WithdrawalRemoteDataSource {
  Future<PagedResult<Withdrawal>> getWithdrawalsPage({
    required int offset,
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
    String? partnerId,
  });
  Future<WithdrawalSummary> getWithdrawalsSummary({
    DateTime? startDate,
    DateTime? endDate,
    String? partnerId,
  });
  Future<Withdrawal> getWithdrawal(String id);
  Future<Withdrawal> createWithdrawal(Withdrawal withdrawal);
  Future<Withdrawal> updateWithdrawal(Withdrawal withdrawal);
  Future<void> deleteWithdrawal(String id);
  Future<List<Partner>> getPartners();
  Future<Partner> createPartner(Partner partner);
  Future<void> deletePartner(String id);
}

class WithdrawalRemoteDataSourceImpl implements WithdrawalRemoteDataSource {
  final SupabaseClient client;

  WithdrawalRemoteDataSourceImpl(this.client);

  @override
  Future<PagedResult<Withdrawal>> getWithdrawalsPage({
    required int offset,
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
    String? partnerId,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      var query = client
          .from('withdrawals')
          .select()
          .eq('user_id', userId)
          .isFilter('deleted_at', null);

      if (partnerId != null) {
        query = query.eq('partner_id', partnerId);
      }
      if (startDate != null) {
        query = query.gte('withdrawal_date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('withdrawal_date', endDate.toIso8601String());
      }

      final response = await query
          .order('withdrawal_date', ascending: false)
          .order('id', ascending: true)
          .range(offset, offset + limit);

      final withdrawals =
          response.map((withdrawal) => Withdrawal.fromMap(withdrawal)).toList();
      final hasMore = withdrawals.length > limit;
      return PagedResult(
        items: hasMore ? withdrawals.sublist(0, limit) : withdrawals,
        hasMore: hasMore,
      );
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<WithdrawalSummary> getWithdrawalsSummary({
    DateTime? startDate,
    DateTime? endDate,
    String? partnerId,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      var query = client
          .from('withdrawals')
          .select('amount, withdrawal_date')
          .eq('user_id', userId)
          .isFilter('deleted_at', null);

      if (partnerId != null) {
        query = query.eq('partner_id', partnerId);
      }
      if (startDate != null) {
        query = query.gte('withdrawal_date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('withdrawal_date', endDate.toIso8601String());
      }

      final response = await query;

      var totalAmount = 0.0;
      var totalCount = 0;
      final monthlyData = List<double>.filled(12, 0);

      for (final row in response) {
        final amount = (row['amount'] ?? 0).toDouble();
        final date = DateTime.parse(row['withdrawal_date']);
        totalAmount += amount;
        totalCount++;
        monthlyData[date.month - 1] += amount;
      }

      return WithdrawalSummary(
        totalAmount: totalAmount,
        totalCount: totalCount,
        averageAmount: totalCount > 0 ? totalAmount / totalCount : 0,
        monthlyData: monthlyData,
      );
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<Withdrawal> getWithdrawal(String id) async {
    try {
      final response = await client
          .from('withdrawals')
          .select()
          .eq('id', id)
          .single();

      return Withdrawal.fromMap(response);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<Withdrawal> createWithdrawal(Withdrawal withdrawal) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      final withdrawalWithIds = withdrawal.copyWith(
        userId: userId,
        partnerId: withdrawal.partnerId,
      );
      final response = await client
          .from('withdrawals')
          .insert(withdrawalWithIds.toMap())
          .select()
          .single();

      return Withdrawal.fromMap(response);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<Withdrawal> updateWithdrawal(Withdrawal withdrawal) async {
    try {
      final response = await client
          .from('withdrawals')
          .update(withdrawal.toMap())
          .eq('id', withdrawal.id)
          .select()
          .single();

      return Withdrawal.fromMap(response);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<void> deleteWithdrawal(String id) async {
    try {
      await client.from('withdrawals').delete().eq('id', id);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<List<Partner>> getPartners() async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await client
          .from('partners')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response.map((partner) => Partner.fromMap(partner)).toList();
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<Partner> createPartner(Partner partner) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final data = {
        ...partner.toMap(),
        'user_id': userId,
      };

      final response = await client
          .from('partners')
          .insert(data)
          .select()
          .single();

      return Partner.fromMap(response);
    } catch (e) {
      log(e.toString());
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<void> deletePartner(String id) async {
    try {
      await client.from('partners').delete().eq('id', id);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }
}
