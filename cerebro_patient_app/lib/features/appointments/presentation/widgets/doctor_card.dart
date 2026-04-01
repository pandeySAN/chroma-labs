import 'package:flutter/material.dart';
import '../../domain/entities/clinic_entity.dart';

class DoctorCard extends StatelessWidget {
  final DoctorInfo doctor;
  final String clinicName;
  final VoidCallback onBookSession;

  const DoctorCard({
    super.key,
    required this.doctor,
    required this.clinicName,
    required this.onBookSession,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor avatar
                CircleAvatar(
                  radius: 32,
                  backgroundColor: primary.withValues(alpha: 0.1),
                  backgroundImage: doctor.profilePicture != null
                      ? NetworkImage(doctor.profilePicture!)
                      : null,
                  child: doctor.profilePicture == null
                      ? Text(
                          doctor.name.isNotEmpty
                              ? doctor.name[0].toUpperCase()
                              : 'D',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),

                // Doctor info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. ${doctor.name}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${doctor.specialization}'
                        '${doctor.experienceYears > 0 ? ' (${doctor.experienceYears}+ yrs exp)' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.7),
                        ),
                      ),
                      if (doctor.languages.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          doctor.languages,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Specialization tags
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Tag(label: doctor.specialization, theme: theme),
                if (clinicName.isNotEmpty)
                  _Tag(label: clinicName, theme: theme),
              ],
            ),

            const SizedBox(height: 14),

            // Fee + Book button row
            Row(
              children: [
                if (doctor.consultationFee > 0) ...[
                  Text(
                    '₹${doctor.consultationFee.toStringAsFixed(0)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    ' per session',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.6),
                    ),
                  ),
                ] else
                  Text(
                    'Free Consultation',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade600,
                    ),
                  ),
                const Spacer(),
                OutlinedButton(
                  onPressed: onBookSession,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: const Text(
                    'Book Session',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final ThemeData theme;
  const _Tag({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
        ),
      ),
    );
  }
}
