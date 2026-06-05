import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/providers.dart';
import '../providers/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksStreamProvider);

    ref.listen(authStateProvider, (_, next) {
      next.whenData((user) {
        if (user == null && context.mounted) {
          context.go('/login');
        }
      });
    });

    return Scaffold(
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (tasks) => tasks.isEmpty
            ? const Center(child: Text('No tasks'))
            : ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (_, i) => Text(tasks[i].title),
              ),
      ),
    );
  }
}
