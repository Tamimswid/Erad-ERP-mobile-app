import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/withdrawal_cubit.dart';
import 'empty_state_widget.dart';
import 'withdrawal_card.dart';
import 'withdrawal_details_dialog.dart';
import 'package:erad/core/constants/app_constants.dart';

class WithdrawalListWidget extends StatefulWidget {
  const WithdrawalListWidget({super.key});

  @override
  State<WithdrawalListWidget> createState() => _WithdrawalListWidgetState();
}

class _WithdrawalListWidgetState extends State<WithdrawalListWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WithdrawalCubit, WithdrawalState>(
      listener: (context, state) {
        if (state is WithdrawalSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is WithdrawalError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      builder: (context, state) {
        if (state is WithdrawalLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is WithdrawalsLoaded) {
          if (state.withdrawals.isEmpty) {
            return const EmptyStateWidget();
          }
          return ListView.builder(
            itemCount: state.withdrawals.length,
            itemBuilder: (context, index) {
              final withdrawal = state.withdrawals[index];
              return WithdrawalCard(
                withdrawal: withdrawal,
                onTap: () => WithdrawalDetailsDialog.show(context, withdrawal),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
