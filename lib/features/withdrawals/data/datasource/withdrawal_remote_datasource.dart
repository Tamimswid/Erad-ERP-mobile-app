import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/withdrawal.dart';
import '../models/partner.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/user_service.dart';

abstract class WithdrawalRemoteDataSource {
  Future<List<Withdrawal>> getWithdrawals({DateTime? startDate, DateTime? endDate, String? partnerId});
  Stream<List<Withdrawal>> watchWithdrawals({String? partnerId});
  Future<Withdrawal> getWithdrawal(String id);
  Future<Withdrawal> createWithdrawal(Withdrawal withdrawal);
  Future<Withdrawal> updateWithdrawal(Withdrawal withdrawal);
  Future<void> deleteWithdrawal(String id);
  Future<List<Partner>> getPartners();
  Stream<List<Partner>> watchPartners();
  Future<Partner> createPartner(Partner partner);
  Future<void> deletePartner(String id);
}

class WithdrawalRemoteDataSourceImpl implements WithdrawalRemoteDataSource {
  final SupabaseClient client;

  WithdrawalRemoteDataSourceImpl(this.client);

  @override
  Future<List<Withdrawal>> getWithdrawals({DateTime? startDate, DateTime? endDate, String? partnerId}) async {
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

      final response = await query.order('withdrawal_date', ascending: false);

      return response.map((withdrawal) => Withdrawal.fromMap(withdrawal)).toList();
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

  Stream<List<Withdrawal>> watchWithdrawals({String? partnerId}) async* {
    final userId = await UserService.getUserId();
    if (userId == null) throw Exception('User not logged in');

    var query = client
        .from('withdrawals')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('withdrawal_date', ascending: false);

    await for (final data in query) {
      var withdrawals = data
          .map((item) => Withdrawal.fromMap(item))
          .toList();

      // Apply partner filter if specified
      if (partnerId != null && partnerId.isNotEmpty) {
        withdrawals = withdrawals.where((w) => w.partnerId == partnerId).toList();
      }

      yield withdrawals;
    }
  }

  Stream<List<Partner>> watchPartners() async* {
    final userId = await UserService.getUserId();
    if (userId == null) throw Exception('User not logged in');

    await for (final data in client
        .from('partners')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)) {
      yield data
          .map((item) => Partner.fromMap(item))
          .toList();
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
