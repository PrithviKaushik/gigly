import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/providers.dart';
import '../../domain/entities/entities.dart';
import '../providers/providers.dart';
import 'add_edit_task_bottom_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(filteredTasksProvider);
    final filter = ref.watch(taskFilterProvider);
    final searchQuery = ref.watch(taskSearchProvider);

    ref.listen(authStateProvider, (_, next) {
      next.whenData((user) {
        if (user == null && context.mounted) {
          context.go('/login');
        }
      });
    });

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: filter.showCompleted == null,
                  onSelected: (_) =>
                      ref.read(taskFilterProvider.notifier).showAll(),
                ),
                FilterChip(
                  label: const Text('Pending'),
                  selected: filter.showCompleted == false,
                  onSelected: (_) =>
                      ref.read(taskFilterProvider.notifier).showPending(),
                ),
                FilterChip(
                  label: const Text('Completed'),
                  selected: filter.showCompleted == true,
                  onSelected: (_) =>
                      ref.read(taskFilterProvider.notifier).showCompleted(),
                ),
              ],
            ),
          ),
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('$error')),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return Center(
                    child: Text(
                      searchQuery.isNotEmpty || filter.showCompleted != null
                          ? 'No matching tasks'
                          : 'No tasks yet',
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
                      subtitle: task.dueDate != null
                          ? Text(
                              '${task.priority.name} · ${_formatDate(task.dueDate!)}')
                          : Text(task.priority.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => ref
                            .read(taskActionsNotifier.notifier)
                            .deleteTask(task.id),
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

  void _showTaskSheet(BuildContext context, WidgetRef ref,
      [TaskEntity? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddEditTaskBottomSheet(existingTask: existing),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
