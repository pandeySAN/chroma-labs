import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/appointment_entity.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentEntity appointment;
  final VoidCallback? onCancel;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onCancel,
  });

  _StatusStyle get _statusStyle {
    switch (appointment.status) {
      case 'scheduled':
        return _StatusStyle(
          color: const Color(0xFF3B82F6),
          icon: Icons.event_available_rounded,
          label: 'Scheduled',
        );
      case 'confirmed':
        return _StatusStyle(
          color: const Color(0xFF10B981),
          icon: Icons.verified_rounded,
          label: 'Confirmed',
        );
      case 'in_progress':
        return _StatusStyle(
          color: const Color(0xFFF59E0B),
          icon: Icons.play_circle_rounded,
          label: 'In Progress',
        );
      case 'completed':
        return _StatusStyle(
          color: const Color(0xFF10B981),
          icon: Icons.check_circle_rounded,
          label: 'Completed',
        );
      case 'pending_payment':
        return _StatusStyle(
          color: const Color(0xFFF59E0B),
          icon: Icons.hourglass_top_rounded,
          label: 'Pending Payment',
        );
      case 'cancelled':
        return _StatusStyle(
          color: const Color(0xFFEF4444),
          icon: Icons.cancel_rounded,
          label: 'Cancelled',
        );
      default:
        return _StatusStyle(
          color: const Color(0xFF94A3B8),
          icon: Icons.help_outline_rounded,
          label: appointment.statusDisplay,
        );
    }
  }

  bool get _hasVideoLink =>
      appointment.videoCallLink != null &&
      appointment.videoCallLink!.isNotEmpty;

  bool get _canJoinCall =>
      _hasVideoLink &&
      (appointment.status == 'scheduled' ||
          appointment.status == 'in_progress' ||
          appointment.status == 'confirmed');

  bool get _canCancel =>
      appointment.status == 'scheduled' ||
      appointment.status == 'pending_payment';

  String get _formattedDate {
    try {
      return DateFormat('EEE, d MMM yyyy')
          .format(DateTime.parse(appointment.date));
    } catch (_) {
      return appointment.date;
    }
  }

  String get _formattedTime {
    try {
      final parts = appointment.time.split(':');
      if (parts.length >= 2) {
        final dt = DateTime(0, 0, 0, int.parse(parts[0]), int.parse(parts[1]));
        return DateFormat('h:mm a').format(dt);
      }
    } catch (_) {}
    return appointment.time;
  }

  Future<void> _joinVideoCall(BuildContext context) async {
    final uri = Uri.parse(appointment.videoCallLink!);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open video call link')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final ss = _statusStyle;
    final fee = appointment.consultationFee;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ───────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.person_rounded, color: primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. ${appointment.doctorName}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        appointment.doctorSpecialization,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: ss.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(ss.icon, size: 12, color: ss.color),
                      const SizedBox(width: 4),
                      Text(
                        ss.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: ss.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(
                height: 1,
                color: isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200),
            const SizedBox(height: 12),

            // ── Details row ──────────────────────────────────────
            Row(
              children: [
                _InfoChip(
                  icon: Icons.calendar_today_rounded,
                  text: _formattedDate,
                  theme: theme,
                ),
                const SizedBox(width: 10),
                _InfoChip(
                  icon: Icons.access_time_rounded,
                  text: _formattedTime,
                  theme: theme,
                ),
              ],
            ),
            if (appointment.clinicName.isNotEmpty) ...[
              const SizedBox(height: 8),
              _InfoChip(
                icon: Icons.local_hospital_rounded,
                text: appointment.clinicName,
                theme: theme,
              ),
            ],

            // ── Fee badge ────────────────────────────────────────
            if (fee > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.currency_rupee_rounded,
                        size: 13, color: primary),
                    Text(
                      '${fee.toStringAsFixed(0)} consultation fee',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Pending payment notice ───────────────────────────
            if (appointment.status == 'pending_payment') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFFBD38D), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 16, color: Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Payment pending — slot is reserved for 15 min.',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF92400E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Video call button ────────────────────────────────
            if (_canJoinCall) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _joinVideoCall(context),
                  icon: const Icon(Icons.video_call_rounded, size: 20),
                  label: const Text('Join Video Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B8A9),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],

            // ── Cancel button ────────────────────────────────────
            if (_canCancel && onCancel != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Cancel'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusStyle {
  final Color color;
  final IconData icon;
  final String label;
  const _StatusStyle(
      {required this.color, required this.icon, required this.label});
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final ThemeData theme;
  const _InfoChip(
      {required this.icon, required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 13,
              color: isDark
                  ? Colors.grey.shade400
                  : Colors.grey.shade600),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.grey.shade300
                  : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
