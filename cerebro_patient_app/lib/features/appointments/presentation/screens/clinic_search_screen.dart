import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/animated_list_item.dart';
import '../../../../core/widgets/page_transitions.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../domain/entities/clinic_entity.dart';
import '../providers/appointment_providers.dart';
import '../widgets/doctor_card.dart';
import 'slot_picker_screen.dart';

class ClinicSearchScreen extends ConsumerStatefulWidget {
  const ClinicSearchScreen({super.key});

  @override
  ConsumerState<ClinicSearchScreen> createState() => _ClinicSearchScreenState();
}

class _ClinicSearchScreenState extends ConsumerState<ClinicSearchScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(clinicSearchProvider.notifier).search(''));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBookSession(ClinicEntity clinic, DoctorInfo doctor) {
    context.pushFadeSlide(
      SlotPickerScreen(clinic: clinic, doctor: doctor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(clinicSearchProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Find a Doctor')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              onChanged: (v) =>
                  ref.read(clinicSearchProvider.notifier).search(v),
              decoration: InputDecoration(
                hintText: 'Search by doctor, clinic, or specialty...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(searchState, theme)),
        ],
      ),
    );
  }

  Widget _buildBody(ClinicSearchState state, ThemeData theme) {
    if (state.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: ShimmerCard(height: 180),
        ),
      );
    }
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.error!,
                style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref
                  .read(clinicSearchProvider.notifier)
                  .search(_controller.text),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Flatten clinics into doctor entries
    final List<_DoctorEntry> entries = [];
    for (final clinic in state.clinics) {
      for (final doctor in clinic.doctors) {
        entries.add(_DoctorEntry(clinic: clinic, doctor: doctor));
      }
    }

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56, color: theme.disabledColor),
            const SizedBox(height: 12),
            Text('No doctors found', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text('Try a different search term',
                style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: entries.length,
      padding: const EdgeInsets.only(bottom: 16),
      itemBuilder: (ctx, i) {
        final entry = entries[i];
        return AnimatedListItem(
          index: i,
          child: DoctorCard(
            doctor: entry.doctor,
            clinicName: entry.clinic.name,
            onBookSession: () =>
                _onBookSession(entry.clinic, entry.doctor),
          ),
        );
      },
    );
  }
}

class _DoctorEntry {
  final ClinicEntity clinic;
  final DoctorInfo doctor;
  const _DoctorEntry({required this.clinic, required this.doctor});
}
