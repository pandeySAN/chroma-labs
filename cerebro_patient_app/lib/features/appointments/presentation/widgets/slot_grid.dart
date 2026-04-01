import 'package:flutter/material.dart';
import '../../domain/entities/time_slot_entity.dart';

class SlotGrid extends StatelessWidget {
  final List<TimeSlotEntity> slots;
  final String? selectedTime;
  final ValueChanged<String> onSlotTap;

  const SlotGrid({
    super.key,
    required this.slots,
    this.selectedTime,
    required this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.5,
      ),
      itemCount: slots.length,
      itemBuilder: (ctx, i) {
        final slot = slots[i];
        final isSelected = slot.time == selectedTime;
        final isBooked = !slot.isAvailable;

        return GestureDetector(
          onTap: isBooked ? null : () => onSlotTap(slot.time),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isBooked
                  ? (isDark
                      ? Colors.grey.shade900.withValues(alpha: 0.6)
                      : Colors.grey.shade200)
                  : isSelected
                      ? primary
                      : theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isBooked
                    ? (isDark ? Colors.grey.shade700 : Colors.grey.shade300)
                    : isSelected
                        ? primary
                        : theme.dividerTheme.color ?? Colors.grey.shade200,
                width: isBooked ? 1 : 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isBooked)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.block_rounded,
                      size: 13,
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                    ),
                  ),
                Text(
                  slot.time,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isBooked
                        ? (isDark ? Colors.grey.shade600 : Colors.grey.shade500)
                        : isSelected
                            ? Colors.white
                            : theme.textTheme.bodyLarge?.color,
                    decoration:
                        isBooked ? TextDecoration.lineThrough : null,
                    decorationColor:
                        isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
