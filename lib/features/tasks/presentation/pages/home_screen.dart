import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gigly_bottom_sheet.dart';
import '../../../../core/widgets/gigly_dialog.dart';
import '../../../../core/widgets/gigly_drawer.dart';
import '../../../../core/widgets/gigly_snackbar.dart';
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
        GiglySnackbar.showError(context, message);
      }
    });

    final tasksAsync = ref.watch(filteredTasksProvider);
    final stats = ref.watch(taskStatsProvider).asData?.value;
    final filter = ref.watch(taskFilterProvider);
    final searchQuery = ref.watch(taskSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gigly'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      drawer: const GiglyDrawer(),
      body: Column(
        children: [
          if (stats != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TaskStatsCards(stats: stats),
          ],
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search tasks',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) =>
                  ref.read(taskSearchProvider.notifier).search(v),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: _buildSectionLabel(context, 'Status'),
                    ),
                    _buildStatusChip(context, ref, filter, 'All', null),
                    const SizedBox(width: AppSpacing.sm),
                    _buildStatusChip(context, ref, filter, 'Pending', false),
                    const SizedBox(width: AppSpacing.sm),
                    _buildStatusChip(context, ref, filter, 'Completed', true),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: _buildSectionLabel(context, 'Priority'),
                    ),
                    _buildPriorityChip(context, ref, filter, 'Any', null),
                    const SizedBox(width: AppSpacing.sm),
                    _buildPriorityChip(context, ref, filter, 'Low', TaskPriority.low),
                    const SizedBox(width: AppSpacing.sm),
                    _buildPriorityChip(
                        context, ref, filter, 'Medium', TaskPriority.medium),
                    const SizedBox(width: AppSpacing.sm),
                    _buildPriorityChip(
                        context, ref, filter, 'High', TaskPriority.high),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    switch (error) {
                      TaskFailure e => e.message,
                      _ => 'An unexpected error occurred.',
                    },
                    style: AppTextStyles.bodyMd.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (tasks) {
                if (tasks.isEmpty) {
                  final hasActiveFilter = searchQuery.isNotEmpty ||
                      filter.showCompleted != null ||
                      filter.priority != null;
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasActiveFilter
                              ? Icons.search_off
                              : Icons.checklist_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          hasActiveFilter
                              ? 'No matching tasks'
                              : 'No tasks yet',
                          style: AppTextStyles.headlineSm.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (!hasActiveFilter) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Tap + to create your first task',
                            style: AppTextStyles.bodyMd.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  itemCount: tasks.length,
                  itemBuilder: (_, i) {
                    final task = tasks[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _TaskCard(
                        task: task,
                        onToggle: () => ref
                            .read(taskActionsNotifier.notifier)
                            .toggleCompletion(task),
                        onDelete: () =>
                            _confirmDelete(context, ref, task),
                        onTap: () =>
                            _showTaskSheet(context, ref, task),
                      ),
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
    GiglyBottomSheet.show(
      context,
      child: AddEditTaskBottomSheet(existingTask: existing),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, TaskEntity task) {
    showDialog(
      context: context,
      builder: (ctx) => GiglyDialog(
        title: 'Delete task',
        message: 'Are you sure you want to delete "${task.title}"?',
        confirmLabel: 'Delete',
        confirmColor: Theme.of(context).colorScheme.error,
        onConfirm: () async {
          Navigator.of(ctx).pop();
          await ref.read(taskActionsNotifier.notifier).deleteTask(task);
          if (!context.mounted) return;
          if (ref.read(taskActionsNotifier) case AsyncData()) {
            GiglySnackbar.show(
              context,
              message: 'Task deleted',
              actionLabel: 'Undo',
              onAction: () {
                ref.read(taskActionsNotifier.notifier).undoDelete();
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context,
    WidgetRef ref,
    TaskFilterState filter,
    String label,
    bool? value,
  ) {
    final isSelected = filter.showCompleted == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? Theme.of(context).colorScheme.onPrimary
              : null,
        ),
      ),
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
    BuildContext context,
    WidgetRef ref,
    TaskFilterState filter,
    String label,
    TaskPriority? value,
  ) {
    final isSelected = filter.priority == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? Theme.of(context).colorScheme.onPrimary
              : null,
        ),
      ),
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

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: AppTextStyles.labelSm.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskEntity task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = switch (task.priority) {
      TaskPriority.high => Theme.of(context).colorScheme.error,
      TaskPriority.medium => const Color(0xFFf59e0b),
      TaskPriority.low => const Color(0xFF16a34a),
    };
    final overdue = task.dueDate != null && !task.isCompleted &&
        DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day)
            .isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(color: priorityColor),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: task.isCompleted,
                        onChanged: (_) => onToggle(),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              task.title,
                              style: AppTextStyles.bodyLg.copyWith(
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: task.isCompleted
                                    ? Theme.of(context).colorScheme.onSurfaceVariant
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            _TaskSubtitle(task: task),
                          ],
                        ),
                      ),
                      if (overdue)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.xs),
                          child: Icon(
                            Icons.error_outline,
                            size: 20,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskSubtitle extends StatelessWidget {
  final TaskEntity task;

  const _TaskSubtitle({required this.task});

  @override
  Widget build(BuildContext context) {
    final priority = task.priority.name;
    final dueDate = task.dueDate;
    final description = task.description;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    Color dateColor;
    String dateText;

    if (dueDate == null) {
      dateText = priority;
      dateColor = Theme.of(context).colorScheme.onSurfaceVariant;
    } else {
      final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
      final diff = dueDay.difference(today).inDays;

      if (diff < 0 && !task.isCompleted) {
        dateText = 'Overdue \u00b7 $priority';
        dateColor = Theme.of(context).colorScheme.error;
      } else {
        String relativeDate;
        if (diff == 0) {
          relativeDate = 'Today';
        } else if (diff == 1) {
          relativeDate = 'Tomorrow';
        } else {
          relativeDate = '${dueDate.month}/${dueDate.day}/${dueDate.year}';
        }
        dateText = '$priority \u00b7 $relativeDate';
        dateColor = Theme.of(context).colorScheme.onSurfaceVariant;
      }
    }

    final showOverdue = dueDate != null && dateColor == Theme.of(context).colorScheme.error;

    if (description.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          showOverdue
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 14,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(dateText, style: AppTextStyles.labelSm.copyWith(color: dateColor)),
                  ],
                )
              : Text(dateText, style: AppTextStyles.labelSm.copyWith(color: dateColor)),
          const SizedBox(height: 2),
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSm.copyWith(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
            ),
          ),
        ],
      );
    }

    if (showOverdue) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 14, color: dateColor),
          const SizedBox(width: 4),
          Text(dateText, style: AppTextStyles.labelSm.copyWith(color: dateColor)),
        ],
      );
    }

    return Text(dateText, style: AppTextStyles.labelSm.copyWith(color: dateColor));
  }
}
