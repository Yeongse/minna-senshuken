import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minna_senshuken/core/providers/championship_providers.dart';

void main() {
  group('ChampionshipCreateState', () {
    test('should have correct default values', () {
      const state = ChampionshipCreateState();

      expect(state.isLoading, isFalse);
      expect(state.championship, isNull);
      expect(state.error, isNull);
      expect(state.validationErrors, isEmpty);
    });

    test('copyWith should preserve existing values when not specified', () {
      const state = ChampionshipCreateState(
        isLoading: true,
        validationErrors: {'title': 'error'},
      );

      final newState = state.copyWith();

      expect(newState.isLoading, isTrue);
      expect(newState.validationErrors, {'title': 'error'});
    });

    test('copyWith should update specified values', () {
      const state = ChampionshipCreateState(isLoading: true);

      final newState = state.copyWith(isLoading: false, error: 'test error');

      expect(newState.isLoading, isFalse);
      expect(newState.error, equals('test error'));
    });
  });

  group('ChampionshipCreateNotifier validation', () {
    late ProviderContainer container;
    late ChampionshipCreateNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(championshipCreateNotifierProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('should validate empty title', () async {
      final result = await notifier.create(
        title: '',
        description: 'Valid description',
        durationDays: 7,
      );

      expect(result, isFalse);
      final state = container.read(championshipCreateNotifierProvider);
      expect(state.validationErrors['title'], isNotNull);
      expect(state.validationErrors['title'], contains('入力してください'));
    });

    test('should validate title exceeding 50 characters', () async {
      final longTitle = 'a' * 51;
      final result = await notifier.create(
        title: longTitle,
        description: 'Valid description',
        durationDays: 7,
      );

      expect(result, isFalse);
      final state = container.read(championshipCreateNotifierProvider);
      expect(state.validationErrors['title'], isNotNull);
      expect(state.validationErrors['title'], contains('50文字以内'));
    });

    test('should validate empty description', () async {
      final result = await notifier.create(
        title: 'Valid Title',
        description: '',
        durationDays: 7,
      );

      expect(result, isFalse);
      final state = container.read(championshipCreateNotifierProvider);
      expect(state.validationErrors['description'], isNotNull);
    });

    test('should validate description exceeding 500 characters', () async {
      final longDescription = 'a' * 501;
      final result = await notifier.create(
        title: 'Valid Title',
        description: longDescription,
        durationDays: 7,
      );

      expect(result, isFalse);
      final state = container.read(championshipCreateNotifierProvider);
      expect(state.validationErrors['description'], isNotNull);
      expect(state.validationErrors['description'], contains('500文字以内'));
    });

    test('should validate durationDays less than 1', () async {
      final result = await notifier.create(
        title: 'Valid Title',
        description: 'Valid description',
        durationDays: 0,
      );

      expect(result, isFalse);
      final state = container.read(championshipCreateNotifierProvider);
      expect(state.validationErrors['durationDays'], isNotNull);
      expect(state.validationErrors['durationDays'], contains('1日以上'));
    });

    test('should validate durationDays greater than 14', () async {
      final result = await notifier.create(
        title: 'Valid Title',
        description: 'Valid description',
        durationDays: 15,
      );

      expect(result, isFalse);
      final state = container.read(championshipCreateNotifierProvider);
      expect(state.validationErrors['durationDays'], isNotNull);
      expect(state.validationErrors['durationDays'], contains('14日以内'));
    });

    test('should report multiple validation errors', () async {
      final result = await notifier.create(
        title: '',
        description: '',
        durationDays: 0,
      );

      expect(result, isFalse);
      final state = container.read(championshipCreateNotifierProvider);
      expect(state.validationErrors.length, equals(3));
      expect(state.validationErrors['title'], isNotNull);
      expect(state.validationErrors['description'], isNotNull);
      expect(state.validationErrors['durationDays'], isNotNull);
    });

    test('should accept valid inputs at boundary', () async {
      // 50 characters title (at boundary)
      final validTitle = 'a' * 50;
      // 500 characters description (at boundary)
      final validDescription = 'b' * 500;

      final result = await notifier.create(
        title: validTitle,
        description: validDescription,
        durationDays: 14, // at boundary
      );

      // Will fail at API call but validation should pass
      final state = container.read(championshipCreateNotifierProvider);
      expect(state.validationErrors, isEmpty);
    });

    test('reset should clear state', () {
      notifier.reset();

      final state = container.read(championshipCreateNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.championship, isNull);
      expect(state.error, isNull);
      expect(state.validationErrors, isEmpty);
    });
  });
}
