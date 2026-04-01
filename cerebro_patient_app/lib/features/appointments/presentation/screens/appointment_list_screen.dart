import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/animated_list_item.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/toast_service.dart';
import '../providers/appointment_providers.dart';
import '../widgets/appointment_card.dart';

class AppointmentListScreen extends ConsumerStatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  ConsumerState<AppointmentListScreen> createState() =>
      _AppointmentListScreenState();
}

class _AppointmentListScreenState
    extends ConsumerState<AppointmentListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(appointmentProvider.notifier).loadMyAppointments());
  }

  Future<void> _cancelAppointment(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content:
            const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Cancel')),
        ],
      ),
    );

    if (confirmed == true) {
      final ok =
          await ref.read(appointmentProvider.notifier).cancelAppointment(id);
      if (mounted) {
        AppToast.show(
          context,
          message:
              ok ? 'Appointment cancelled' : 'Failed to cancel appointment',
          type: ok ? ToastType.success : ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appointmentProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Appointments')),
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(AppointmentState state, ThemeData theme) {
    if (state.isLoading && state.appointments.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 4,
        itemBuilder: (_, __) => const ShimmerCard(height: 140),
      );
    }
    if (state.error != null && state.appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.error!,
                style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref
                  .read(appointmentProvider.notifier)
                  .loadMyAppointments(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (state.appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_rounded,
                size: 64,
                color: theme.textTheme.bodyMedium?.color
                    ?.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('No appointments yet',
                style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(appointmentProvider.notifier).loadMyAppointments(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.appointments.length,
        itemBuilder: (ctx, i) {
          final appt = state.appointments[i];
          return AnimatedListItem(
            index: i,
            child: AppointmentCard(
              appointment: appt,
              onCancel: (appt.status == 'scheduled' ||
                      appt.status == 'pending_payment')
                  ? () => _cancelAppointment(appt.id)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
