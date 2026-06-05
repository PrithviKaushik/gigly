import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/errors.dart';
import '../../../auth/presentation/providers/providers.dart';
import '../../../dashboard/presentation/widgets/widgets.dart';
import '../../domain/entities/entities.dart';
import '../providers/providers.dart';
import 'add_edit_task_bottom_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(taskActionsNotifier, (_, next) {
      if (next is AsyncError) {
        final message = switch (next.error) {
          TaskFailure e => e.message,
          _ => 'An unexpected error occurred.',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });

    final tasksAsync = ref.watch(filteredTasksProvider);
    final stats = ref.watch(taskStatsProvider).asData?.value;
    final filter = ref.watch(taskFilterProvider);
    final searchQuery = ref.watch(taskSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (stats != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TaskStatsCards(stats: stats),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) =>
                  ref.read(taskSearchProvider.notifier).search(v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusChip(ref, filter, 'All', null),
                  const SizedBox(width: 8),
                  _buildStatusChip(ref, filter, 'Pending', false),
                  const SizedBox(width: 8),
                  _buildStatusChip(ref, filter, 'Completed', true),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPriorityChip(ref, filter, 'Any', null),
                  const SizedBox(width: 8),
                  _buildPriorityChip(
                      ref, filter, 'Low', TaskPriority.low),
                  const SizedBox(width: 8),
                  _buildPriorityChip(
                      ref, filter, 'Medium', TaskPriority.medium),
                  const SizedBox(width: 8),
                  _buildPriorityChip(
                      ref, filter, 'High', TaskPriority.high),
                ],
              ),
            ),
          ),
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  switch (error) {
                    TaskFailure e => e.message,
                    _ => 'An unexpected error occurred.',
                  },
                ),
              ),
              data: (tasks) {
                if (tasks.isEmpty) {
                  final hasActiveFilter = searchQuery.isNotEmpty ||
                      filter.showCompleted != null ||
                      filter.priority != null;
                  return Center(
                    child: Text(
                      hasActiveFilter ? 'No matching tasks' : 'No tasks yet',
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (_, i) {
                    final task = tasks[i];
                    return ListTile(
                      leading: Checkbox(
                        value: task.isCompleted,
                        onChanged: (_) => ref
                            .read(taskActionsNotifier.notifier)
                            .toggleCompletion(task),
                      ),
                      title: Text(task.title),
                      subtitle: _buildTaskSubtitle(context, task),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmDelete(context, ref, task),
                      ),
                      onTap: () => _showTaskSheet(context, ref, task),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskSubtitle(BuildContext context, TaskEntity task) {
    final theme = Theme.of(context);
    final priority = task.priority.name;
    final dueDate = task.dueDate;

    if (dueDate == null) return Text(priority);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = dueDay.difference(today).inDays;

    String dateText;
    TextStyle? dateStyle;
    if (diff < 0 && !task.isCompleted) {
      dateText = 'Overdue';
      dateStyle = TextStyle(color: theme.colorScheme.error);
    } else if (diff == 0) {
      dateText = 'Today';
    } else if (diff == 1) {
      dateText = 'Tomorrow';
    } else {
      dateText = '${dueDate.month}/${dueDate.day}/${dueDate.year}';
    }

    return Text(
      '$priority \u00b7 $dateText',
      style: dateStyle != null
          ? theme.textTheme.bodySmall?.copyWith(color: dateStyle.color)
          : theme.textTheme.bodySmall,
    );
  }

  void _showTaskSheet(BuildContext context, WidgetRef ref,
      [TaskEntity? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddEditTaskBottomSheet(existingTask: existing),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, TaskEntity task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(taskActionsNotifier.notifier).deleteTask(task);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Task deleted'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        ref.read(taskActionsNotifier.notifier).undoDelete();
                      },
                    ),
                  ),
                );
              } catch (_) {}
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    WidgetRef ref,
    TaskFilterState filter,
    String label,
    bool? value,
  ) {
    final isSelected = filter.showCompleted == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        final notifier = ref.read(taskFilterProvider.notifier);
        if (value == null) {
          notifier.showAll();
        } else if (value) {
          notifier.showCompleted();
        } else {
          notifier.showPending();
        }
      },
    );
  }

  Widget _buildPriorityChip(
    WidgetRef ref,
    TaskFilterState filter,
    String label,
    TaskPriority? value,
  ) {
    final isSelected = filter.priority == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        final notifier = ref.read(taskFilterProvider.notifier);
        if (value == null) {
          notifier.clearPriority();
        } else {
          notifier.filterByPriority(value);
        }
      },
    );
  }
}
