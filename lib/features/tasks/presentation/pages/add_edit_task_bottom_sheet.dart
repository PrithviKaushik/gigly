import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/entities.dart';

class AddEditTaskBottomSheet extends ConsumerStatefulWidget {
  final TaskEntity? existingTask;

  const AddEditTaskBottomSheet({super.key, this.existingTask});

  @override
  ConsumerState<AddEditTaskBottomSheet> createState() =>
      _AddEditTaskBottomSheetState();
}

class _AddEditTaskBottomSheetState
    extends ConsumerState<AddEditTaskBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
