import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';
import '../providers/providers.dart';

class AddEditTaskBottomSheet extends ConsumerStatefulWidget {
  final TaskEntity? existingTask;

  const AddEditTaskBottomSheet({super.key, this.existingTask});

  @override
  ConsumerState<AddEditTaskBottomSheet> createState() =>
      _AddEditTaskBottomSheetState();
}

class _AddEditTaskBottomSheetState
    extends ConsumerState<AddEditTaskBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;
  TaskPriority _priority = TaskPriority.medium;

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingTask != null) {
      _titleController.text = widget.existingTask!.title;
      _descriptionController.text = widget.existingTask!.description;
      _dueDate = widget.existingTask!.dueDate;
      _priority = widget.existingTask!.priority;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(taskActionsNotifier) is AsyncLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottom = MediaQuery.of(context).padding.bottom;
    final availableHeight = MediaQuery.of(context).size.height;
    final maxSheetHeight = availableHeight * 0.9;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl + bottomInset + bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Edit Task' : 'New Task',
                style: AppTextStyles.headlineMd,
              ),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task title',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.lg),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Due date',
                    suffixIcon: const Icon(Icons.calendar_today, size: 20),
                  ),
                  child: Text(
                    _dueDate != null
                        ? '${_dueDate!.month}/${_dueDate!.day}/${_dueDate!.year}'
                        : 'Not set',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: _dueDate != null
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Priority',
                style: AppTextStyles.labelMd.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: TaskPriority.values.map((p) {
                  final selected = _priority == p;
                  final color = switch (p) {
                    TaskPriority.low => isDark ? AppColors.darkPriorityLow : AppColors.priorityLow,
                    TaskPriority.medium => isDark ? AppColors.darkPriorityMedium : AppColors.priorityMedium,
                    TaskPriority.high => Theme.of(context).colorScheme.error,
                  };
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: p == TaskPriority.low ? 0 : AppSpacing.xs,
                        right: p == TaskPriority.high ? 0 : AppSpacing.xs,
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() => _priority = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? color.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                  color: selected
                      ? color
                      : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            p.name,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelMd.copyWith(
                              color: selected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: isSaving ? null : _save,
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Save' : 'Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(taskActionsNotifier.notifier);
    if (_isEditing) {
      await notifier.updateTask(
        widget.existingTask!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dueDate: _dueDate,
          priority: _priority,
        ),
      );
    } else {
      await notifier.createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _dueDate,
        priority: _priority,
      );
    }
    if (ref.read(taskActionsNotifier) is AsyncData && mounted) {
      Navigator.of(context).pop();
    }
  }
}
