import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/page_transitions.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../domain/entities/clinic_entity.dart';
import '../../domain/entities/time_slot_entity.dart';
import '../providers/appointment_providers.dart';
import '../widgets/slot_grid.dart';
import 'booking_confirm_screen.dart';

class SlotPickerScreen extends ConsumerStatefulWidget {
  final ClinicEntity clinic;
  final DoctorInfo doctor;

  const SlotPickerScreen({
    super.key,
    required this.clinic,
    required this.doctor,
  });

  @override
  ConsumerState<SlotPickerScreen> createState() => _SlotPickerScreenState();
}

class _SlotPickerScreenState extends ConsumerState<SlotPickerScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadSlots);
  }

  void _loadSlots() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    ref.read(slotProvider.notifier).loadSlots(
          doctorId: widget.doctor.id,
          date: dateStr,
        );
    setState(() => _selectedTime = null);
  }

  /// Client-side filter: mark past slots as unavailable when date is today
  List<TimeSlotEntity> _filterPastSlots(List<TimeSlotEntity> slots) {
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

    if (!isToday) return slots;

    final currentMinutes = now.hour * 60 + now.minute;
    return slots.map((slot) {
      final parts = slot.time.split(':');
      if (parts.length == 2) {
        final slotMinutes =
            int.parse(parts[0]) * 60 + int.parse(parts[1]);
        if (slotMinutes <= currentMinutes) {
          return TimeSlotEntity(time: slot.time, isAvailable: false);
        }
      }
      return slot;
    }).toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadSlots();
    }
  }

  void _continue() {
    if (_selectedTime == null) return;
    context.pushFadeSlide(
      BookingConfirmScreen(
        clinic: widget.clinic,
        doctor: widget.doctor,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        time: _selectedTime!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slotState = ref.watch(slotProvider);
    final dateFormatted = DateFormat('EEE, MMM d, yyyy').format(_selectedDate);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final filteredSlots = _filterPastSlots(slotState.slots);

    return Scaffold(
      appBar: AppBar(title: const Text('Pick a Slot')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: primary.withValues(alpha: 0.1),
                  backgroundImage: widget.doctor.profilePicture != null
                      ? NetworkImage(widget.doctor.profilePicture!)
                      : null,
                  child: widget.doctor.profilePicture == null
                      ? Icon(Icons.person_rounded, color: primary)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.doctor.name,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text(widget.doctor.specialization,
                          style: theme.textTheme.bodySmall),
                      if (widget.doctor.consultationFee > 0)
                        Text(
                          '₹${widget.doctor.consultationFee.toStringAsFixed(0)} per session',
                          style: TextStyle(
                            fontSize: 12,
                            color: primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.dividerTheme.color ?? Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        color: primary, size: 20),
                    const SizedBox(width: 12),
                    Text(dateFormatted,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text('Change',
                        style: TextStyle(fontSize: 13, color: primary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Available Slots',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (slotState.isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: ShimmerCard(height: 120)),
              )
            else if (slotState.error != null)
              Center(
                child: Text(slotState.error!,
                    style: TextStyle(color: theme.colorScheme.error)),
              )
            else if (filteredSlots.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('No slots available for this date',
                      style: theme.textTheme.bodyMedium),
                ),
              )
            else
              SlotGrid(
                slots: filteredSlots,
                selectedTime: _selectedTime,
                onSlotTap: (t) => setState(() => _selectedTime = t),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedTime != null ? _continue : null,
              child: const Text('Continue'),
            ),
          ),
        ),
      ),
    );
  }
}
