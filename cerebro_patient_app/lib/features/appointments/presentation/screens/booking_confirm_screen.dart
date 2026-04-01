import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/toast_service.dart';
import '../../domain/entities/clinic_entity.dart';
import '../providers/appointment_providers.dart';
import '../../../payment/presentation/screens/booking_confirm_screen.dart'
    as payment;

class BookingConfirmScreen extends ConsumerStatefulWidget {
  final ClinicEntity clinic;
  final DoctorInfo doctor;
  final String date;
  final String time;

  const BookingConfirmScreen({
    super.key,
    required this.clinic,
    required this.doctor,
    required this.date,
    required this.time,
  });

  @override
  ConsumerState<BookingConfirmScreen> createState() =>
      _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends ConsumerState<BookingConfirmScreen> {
  final _notesController = TextEditingController();
  bool _isBooking = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _isBooking = true);
    try {
      final appointment =
          await ref.read(appointmentProvider.notifier).bookAppointment(
                doctorId: widget.doctor.id,
                clinicId: widget.clinic.id,
                date: widget.date,
                time: widget.time,
                notes: _notesController.text.trim(),
                consultationFee: widget.doctor.consultationFee,
              );
      if (!mounted) return;
      setState(() => _isBooking = false);

      if (appointment != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                payment.BookingConfirmScreen(appointment: appointment),
          ),
        );
      } else {
        final err = ref.read(appointmentProvider).error;
        if (mounted) {
          AppToast.show(context,
              message: err ?? 'Booking failed. Please try again.',
              type: ToastType.error);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBooking = false);
      AppToast.show(context,
          message: 'Something went wrong: ${e.toString()}',
          type: ToastType.error);
    }
  }

  Widget _row(IconData icon, String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final fee = widget.doctor.consultationFee;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Booking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor card
            GlassCard(
              blur: 10,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: primary.withValues(alpha: 0.1),
                    backgroundImage: widget.doctor.profilePicture != null
                        ? NetworkImage(widget.doctor.profilePicture!)
                        : null,
                    child: widget.doctor.profilePicture == null
                        ? Text(
                            widget.doctor.name.isNotEmpty
                                ? widget.doctor.name[0].toUpperCase()
                                : 'D',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. ${widget.doctor.name}',
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.doctor.specialization,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: primary),
                        ),
                        if (widget.doctor.experienceYears > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${widget.doctor.experienceYears}+ years experience',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Appointment details
            GlassCard(
              blur: 10,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Appointment Details',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const Divider(height: 24),
                  _row(Icons.business_rounded, 'Clinic', widget.clinic.name,
                      theme),
                  _row(Icons.calendar_today_rounded, 'Date', widget.date,
                      theme),
                  _row(Icons.access_time_rounded, 'Time', widget.time, theme),
                  if (widget.doctor.languages.isNotEmpty)
                    _row(Icons.language_rounded, 'Language',
                        widget.doctor.languages, theme),
                  if (fee > 0)
                    _row(Icons.currency_rupee_rounded, 'Fee',
                        '₹${fee.toStringAsFixed(0)}', theme),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Notes (optional)',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Any symptoms or notes for the doctor...',
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isBooking ? null : _confirm,
              child: _isBooking
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(fee > 0
                      ? 'Confirm & Proceed to Payment'
                      : 'Confirm Booking'),
            ),
          ),
        ),
      ),
    );
  }
}
