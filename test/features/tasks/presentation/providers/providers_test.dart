import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

import 'package:gigly/features/tasks/domain/entities/entities.dart';
import 'package:gigly/features/tasks/presentation/providers/providers.dart';

void main() {
  group('TaskFilterNotifier', () {
    test('initial state has no filters', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(taskFilterProvider);
      expect(state.showCompleted, isNull);
      expect(state.priority, isNull);
    });

    test('showCompleted sets showCompleted to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(taskFilterProvider.notifier).showCompleted();
      final state = container.read(taskFilterProvider);

      expect(state.showCompleted, isTrue);
    });

    test('showPending sets showCompleted to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(taskFilterProvider.notifier).showPending();
      final state = container.read(taskFilterProvider);

      expect(state.showCompleted, isFalse);
    });

    test('showAll resets showCompleted to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(taskFilterProvider.notifier);
      notifier.showCompleted();
      notifier.showAll();
      final state = container.read(taskFilterProvider);

      expect(state.showCompleted, isNull);
      expect(state.priority, isNull);
    });

    test('filterByPriority sets priority', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(taskFilterProvider.notifier).filterByPriority(TaskPriority.high);
      final state = container.read(taskFilterProvider);

      expect(state.priority, TaskPriority.high);
    });

    test('filterByPriority preserves prior value when called with null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(taskFilterProvider.notifier);
      notifier.filterByPriority(TaskPriority.low);
      notifier.filterByPriority(null);
      final state = container.read(taskFilterProvider);

      expect(state.priority, TaskPriority.low);
    });
  });

  group('TaskSearchNotifier', () {
    test('initial state is empty string', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(taskSearchProvider), '');
    });

    test('search updates the query', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(taskSearchProvider.notifier).search('groceries');
      expect(container.read(taskSearchProvider), 'groceries');
    });

    test('clear resets to empty string', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(taskSearchProvider.notifier);
      notifier.search('work');
      notifier.clear();
      expect(container.read(taskSearchProvider), '');
    });
  });
}
