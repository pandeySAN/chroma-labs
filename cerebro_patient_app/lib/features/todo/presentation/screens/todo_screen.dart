import 'package:flutter/material.dart';
import '../../../../core/widgets/animated_list_item.dart';

class _TodoItem {
  String title;
  bool isDone;
  _TodoItem(this.title) : isDone = false;
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final _controller = TextEditingController();
  final List<_TodoItem> _todos = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTodo() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _todos.add(_TodoItem(text)));
    _controller.clear();
  }

  void _toggle(int index) {
    setState(() => _todos[index].isDone = !_todos[index].isDone);
  }

  void _delete(int index) {
    setState(() => _todos.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final pending = _todos.where((t) => !t.isDone).toList();
    final done = _todos.where((t) => t.isDone).toList();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('To-Do List')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addTodo(),
                    decoration: InputDecoration(
                      hintText: 'Add a new task...',
                      filled: true,
                      fillColor:
                          theme.cardTheme.color ?? theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    onPressed: _addTodo,
                    icon: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _todos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.checklist_rounded,
                            size: 56,
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text('No tasks yet',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('Add your first task above',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      if (pending.isNotEmpty) ...[
                        _sectionHeader('Pending', pending.length,
                            const Color(0xFFF59E0B), theme),
                        ...pending.asMap().entries.map((e) {
                          final idx = _todos.indexOf(e.value);
                          return AnimatedListItem(
                            index: e.key,
                            child: _todoTile(e.value, idx, theme),
                          );
                        }),
                      ],
                      if (done.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _sectionHeader('Completed', done.length,
                            const Color(0xFF10B981), theme),
                        ...done.asMap().entries.map((e) {
                          final idx = _todos.indexOf(e.value);
                          return AnimatedListItem(
                            index: e.key + pending.length,
                            child: _todoTile(e.value, idx, theme),
                          );
                        }),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
      String title, int count, Color color, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ),
        ],
      ),
    );
  }

  Widget _todoTile(_TodoItem item, int index, ThemeData theme) {
    final successColor = const Color(0xFF10B981);

    return Dismissible(
      key: ValueKey('${item.title}_$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _delete(index),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_outline, color: theme.colorScheme.error),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.dividerTheme.color ?? Colors.grey.shade200,
          ),
        ),
        child: ListTile(
          leading: GestureDetector(
            onTap: () => _toggle(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: item.isDone ? successColor : Colors.transparent,
                border: Border.all(
                  color: item.isDone
                      ? successColor
                      : theme.dividerTheme.color ?? Colors.grey.shade300,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(7),
              ),
              child: item.isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          title: Text(
            item.title,
            style: TextStyle(
              fontSize: 15,
              color: item.isDone
                  ? theme.textTheme.bodySmall?.color
                  : theme.textTheme.bodyLarge?.color,
              decoration: item.isDone ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ),
    );
  }
}
