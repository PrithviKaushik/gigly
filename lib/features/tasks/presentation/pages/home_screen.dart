import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gigly_bottom_sheet.dart';
import '../../../../core/widgets/gigly_drawer.dart';
import '../../../../core/widgets/gigly_snackbar.dart';
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
    final countsAsync = ref.watch(filterCountsProvider);
    final filter = ref.watch(taskFilterProvider);
    final searchQuery = ref.watch(taskSearchProvider);

    final hasActiveFilter = searchQuery.isNotEmpty ||
        filter.showCompleted != null ||
        filter.priority != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Theme.of(context).colorScheme.primary,
            height: 1,
          ),
        ),
      ),
      drawer: const GiglyDrawer(),
      body: Column(
        children: [
          if (stats != null) _SummaryLine(stats: stats),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Status',
                  style: AppTextStyles.labelSm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    _buildStatusChip(
                        context, ref, countsAsync, filter, 'All', null),
                    const SizedBox(width: AppSpacing.sm),
                    _buildStatusChip(context, ref, countsAsync, filter,
                        'Pending', false),
                    const SizedBox(width: AppSpacing.sm),
                    _buildStatusChip(
                        context, ref, countsAsync, filter, 'Done', true),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Priority',
                  style: AppTextStyles.labelSm.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    _buildPriorityChip(
                        context, ref, countsAsync, filter, 'All', null),
                    const SizedBox(width: AppSpacing.sm),
                    _buildPriorityChip(context, ref, countsAsync, filter, 'Low',
                        TaskPriority.low),
                    const SizedBox(width: AppSpacing.sm),
                    _buildPriorityChip(context, ref, countsAsync, filter, 'Med',
                        TaskPriority.medium),
                    const SizedBox(width: AppSpacing.sm),
                    _buildPriorityChip(context, ref, countsAsync, filter, 'Hi',
                        TaskPriority.high),
                  ],
                ),
                if (hasActiveFilter)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        ref.read(taskFilterProvider.notifier).clearAll();
                        ref.read(taskSearchProvider.notifier).clear();
                      },
                      child: const Text('Clear filters'),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search tasks',
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) =>
                  ref.read(taskSearchProvider.notifier).search(v),
            ),
          ),
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
                  return _TaskEmptyState(
                    hasActiveFilter: hasActiveFilter,
                    isSearchActive: searchQuery.isNotEmpty,
                    searchQuery: searchQuery,
                    filter: filter,
                    onClearFilters: () {
                      ref.read(taskFilterProvider.notifier).clearAll();
                      ref.read(taskSearchProvider.notifier).clear();
                    },
                    onAddTask: () => _showTaskSheet(context, ref),
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: tasks.length,
                  itemBuilder: (_, i) {
                    final task = tasks[i];
                    final isOverdue = _isOverdue(task);
                    return Dismissible(
                      key: ValueKey(task.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Theme.of(context).colorScheme.primary,
                        alignment: Alignment.centerRight,
                        padding:
                            const EdgeInsets.only(right: AppSpacing.xl),
                        child: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 24,
                        ),
                      ),
                      confirmDismiss: (_) async {
                        await ref
                            .read(taskActionsNotifier.notifier)
                            .deleteTask(task);
                        if (!context.mounted) return false;
                        if (ref.read(taskActionsNotifier) case AsyncData()) {
                          GiglySnackbar.show(
                            context,
                            message: 'Task removed',
                            actionLabel: 'UNDO',
                            onAction: () {
                              ref
                                  .read(taskActionsNotifier.notifier)
                                  .undoDelete();
                            },
                          );
                          return true;
                        }
                        return false;
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () =>
                                _showTaskSheet(context, ref, task),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  if (isOverdue)
                                    Container(
                                      width: 2,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(left: 16),
                                    child: Checkbox(
                                      value: task.isCompleted,
                                      onChanged: (_) => ref
                                          .read(taskActionsNotifier
                                              .notifier)
                                          .toggleCompletion(task),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                                AppRadius.sm),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      child: AnimatedOpacity(
                                        duration: const Duration(
                                            milliseconds: 130),
                                        opacity: task.isCompleted
                                            ? 0.5
                                            : 1.0,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize:
                                              MainAxisSize.min,
                                          children: [
                                            Text(
                                              task.title,
                                              style: AppTextStyles.bodyLg
                                                  .copyWith(
                                                decoration: task
                                                        .isCompleted
                                                    ? TextDecoration
                                                        .lineThrough
                                                    : null,
                                                fontWeight: task
                                                        .isCompleted
                                                    ? FontWeight.w400
                                                    : FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            _TaskSubtitle(task: task),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            height: 1,
                            color: Theme.of(context)
                                .colorScheme
                                .outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                        ],
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

  bool _isOverdue(TaskEntity task) {
    if (task.isCompleted || task.dueDate == null) return false;
    final now = DateTime.now();
    final dueDay = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    return dueDay.isBefore(today);
  }

  void _showTaskSheet(BuildContext context, WidgetRef ref,
      [TaskEntity? existing]) {
    GiglyBottomSheet.show(
      context,
      child: AddEditTaskBottomSheet(existingTask: existing),
    );
  }

  Widget _buildStatusChip(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<FilterCounts> countsAsync,
    TaskFilterState filter,
    String label,
    bool? value,
  ) {
    final isSelected = filter.showCompleted == value;
    final counts = countsAsync.asData?.value;
    final count = switch (value) {
      null => counts?.statusAll,
      true => counts?.statusCompleted,
      false => counts?.statusPending,
    };
    return FilterChip(
      label: Text(
        count != null ? '$label $count' : label,
        style: TextStyle(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
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
    AsyncValue<FilterCounts> countsAsync,
    TaskFilterState filter,
    String label,
    TaskPriority? value,
  ) {
    final isSelected = filter.priority == value;
    final counts = countsAsync.asData?.value;
    final count = switch (value) {
      TaskPriority.low => counts?.priorityLow,
      TaskPriority.medium => counts?.priorityMedium,
      TaskPriority.high => counts?.priorityHigh,
      null => counts?.priorityAll,
    };
    return FilterChip(
      label: Text(
        count != null ? '$label $count' : label,
        style: TextStyle(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
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
}

class _SummaryLine extends StatelessWidget {
  final TaskStats stats;
  const _SummaryLine({required this.stats});

  @override
  Widget build(BuildContext context) {
    final overdue = stats.overdue;
    String text = '${stats.total} tasks · ${stats.pending} pending';
    if (overdue > 0) {
      text += ' · $overdue overdue';
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xs),
      child: Text(
        text,
        style: AppTextStyles.labelSm.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _TaskEmptyState extends StatelessWidget {
  final bool hasActiveFilter;
  final bool isSearchActive;
  final String searchQuery;
  final TaskFilterState filter;
  final VoidCallback onClearFilters;
  final VoidCallback onAddTask;

  const _TaskEmptyState({
    required this.hasActiveFilter,
    required this.isSearchActive,
    required this.searchQuery,
    required this.filter,
    required this.onClearFilters,
    required this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isSearchActive) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text.rich(
                TextSpan(
                  text: 'No matches for "',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  children: [
                    TextSpan(
                      text: searchQuery,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: '".'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Try a different word, or clear the search.',
                style: AppTextStyles.bodyMd.copyWith(
                  color: colorScheme.outline,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: onClearFilters,
                child: const Text('Clear search'),
              ),
            ],
          ),
        ),
      );
    }

    if (hasActiveFilter) {
      final filterDesc = _buildFilterDescription(filter);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_alt_off,
                size: 64,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Nothing fits $filterDesc right now.',
                style: AppTextStyles.bodyMd.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Try a different filter, or clear them.',
                style: AppTextStyles.bodyMd.copyWith(
                  color: colorScheme.outline,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: onClearFilters,
                child: const Text('Clear filters'),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.task_alt,
              size: 80,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Start with one thing.',
              style: AppTextStyles.headlineSm.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tasks live here. Add the first one —\neven a tiny one counts.',
              style: AppTextStyles.bodyMd.copyWith(
                color: colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onAddTask,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add a task'),
            ),
          ],
        ),
      ),
    );
  }

  String _buildFilterDescription(TaskFilterState filter) {
    final parts = <String>[];
    if (filter.showCompleted == false) {
      parts.add('Pending');
    } else if (filter.showCompleted == true) {
      parts.add('Completed');
    }
    if (filter.priority != null) {
      parts.add(filter.priority!.name[0].toUpperCase() +
          filter.priority!.name.substring(1));
    }
    return parts.join(' + ');
  }
}

class _TaskSubtitle extends StatelessWidget {
  final TaskEntity task;
  const _TaskSubtitle({required this.task});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dueDate = task.dueDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    String relativeDate = '';
    Color dateColor = colorScheme.onSurfaceVariant;
    bool isOverdue = false;

    if (dueDate != null) {
      final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
      final diff = dueDay.difference(today).inDays;

      if (diff < 0 && !task.isCompleted) {
        isOverdue = true;
        relativeDate = _formatDate(dueDate);
        dateColor = colorScheme.error;
      } else {
        if (diff == 0) {
          relativeDate = 'Today';
        } else if (diff == 1) {
          relativeDate = 'Tomorrow';
        } else {
          relativeDate = _formatDate(dueDate);
        }
      }
    }

    final priorityName = task.priority.name;
    final capitalizedPriority =
        priorityName[0].toUpperCase() + priorityName.substring(1);
    final priorityColor = switch (task.priority) {
      TaskPriority.low =>
        isDark ? AppColors.darkPriorityLow : AppColors.priorityLow,
      TaskPriority.medium =>
        isDark ? AppColors.darkPriorityMedium : AppColors.priorityMedium,
      TaskPriority.high => colorScheme.error,
    };

    if (task.isCompleted) {
      return Opacity(
        opacity: 0.5,
        child: Text(
          dueDate != null
              ? '$capitalizedPriority \u00b7 $relativeDate'
              : capitalizedPriority,
          style:
              AppTextStyles.labelSm.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    if (isOverdue) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 12, color: dateColor),
          const SizedBox(width: 4),
          Text(
            'Overdue \u00b7 $relativeDate \u00b7 $capitalizedPriority',
            style: AppTextStyles.labelSm.copyWith(color: dateColor),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: priorityColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          dueDate != null
              ? '$capitalizedPriority \u00b7 $relativeDate'
              : capitalizedPriority,
          style:
              AppTextStyles.labelSm.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
