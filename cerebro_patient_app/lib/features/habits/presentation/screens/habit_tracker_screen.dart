import 'package:flutter/material.dart';
import '../../../../core/widgets/animated_list_item.dart';

class _Habit {
  String name;
  IconData icon;
  Color color;
  Set<String> completedDates;

  _Habit({
    required this.name,
    required this.icon,
    required this.color,
    Set<String>? completedDates,
  }) : completedDates = completedDates ?? {};

  bool isDoneToday() => completedDates.contains(_dateKey(DateTime.now()));

  int get streak {
    int count = 0;
    var day = DateTime.now();
    while (completedDates.contains(_dateKey(day))) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  final List<_Habit> _habits = [];

  static const _presets = [
    (name: 'Drink Water', icon: Icons.water_drop_rounded, color: Color(0xFF3B82F6)),
    (name: 'Exercise', icon: Icons.fitness_center_rounded, color: Color(0xFFEF4444)),
    (name: 'Read', icon: Icons.menu_book_rounded, color: Color(0xFFF59E0B)),
    (name: 'Meditate', icon: Icons.self_improvement_rounded, color: Color(0xFF8B5CF6)),
    (name: 'Sleep 8h', icon: Icons.bedtime_rounded, color: Color(0xFF6366F1)),
    (name: 'Walk 10k', icon: Icons.directions_walk_rounded, color: Color(0xFF10B981)),
  ];

  void _addHabit() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final nameCtrl = TextEditingController();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add a Habit',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Text('Quick picks', style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presets.map((p) {
                    return ActionChip(
                      avatar: Icon(p.icon, size: 18, color: p.color),
                      label: Text(p.name),
                      onPressed: () {
                        setState(() {
                          _habits.add(_Habit(
                              name: p.name, icon: p.icon, color: p.color));
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Or create custom',
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Habit name...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        setState(() {
                          _habits.add(_Habit(
                            name: name,
                            icon: Icons.star_rounded,
                            color: theme.colorScheme.primary,
                          ));
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleToday(int index) {
    setState(() {
      final today = _Habit._dateKey(DateTime.now());
      if (_habits[index].completedDates.contains(today)) {
        _habits[index].completedDates.remove(today);
      } else {
        _habits[index].completedDates.add(today);
      }
    });
  }

  void _deleteHabit(int index) {
    setState(() => _habits.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Habit Tracker')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabit,
        child: const Icon(Icons.add),
      ),
      body: _habits.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.trending_up_rounded,
                      size: 56,
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text('No habits yet',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Tap + to create your first habit',
                      style: theme.textTheme.bodySmall),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _habits.length,
              itemBuilder: (ctx, i) => AnimatedListItem(
                index: i,
                child: _habitCard(_habits[i], i, theme),
              ),
            ),
    );
  }

  Widget _habitCard(_Habit habit, int index, ThemeData theme) {
    final doneToday = habit.isDoneToday();

    return Dismissible(
      key: ValueKey('${habit.name}_$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteHabit(index),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: theme.colorScheme.error),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: doneToday
                ? habit.color.withValues(alpha: 0.4)
                : theme.dividerTheme.color ?? Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _toggleToday(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: doneToday
                      ? habit.color
                      : habit.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  doneToday ? Icons.check_rounded : habit.icon,
                  color: doneToday ? Colors.white : habit.color,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: doneToday
                          ? theme.textTheme.bodySmall?.color
                          : theme.textTheme.bodyLarge?.color,
                      decoration:
                          doneToday ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    doneToday ? 'Done for today!' : 'Tap to mark done',
                    style: TextStyle(
                      fontSize: 12,
                      color: doneToday
                          ? const Color(0xFF10B981)
                          : theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      size: 16, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 4),
                  Text(
                    '${habit.streak}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
