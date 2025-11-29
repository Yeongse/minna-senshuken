import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minna_senshuken/core/providers/user_providers.dart';

void main() {
  group('ProfileEditState', () {
    test('should have correct default values', () {
      const state = ProfileEditState();

      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });

    test('copyWith should preserve existing values when not specified', () {
      const state = ProfileEditState(
        isLoading: true,
        error: 'test error',
      );

      final newState = state.copyWith();

      expect(newState.isLoading, isTrue);
      expect(newState.error, isNull); // error is intentionally not preserved
    });

    test('copyWith should update specified values', () {
      const state = ProfileEditState(isLoading: true);

      final newState = state.copyWith(isLoading: false, isSuccess: true);

      expect(newState.isLoading, isFalse);
      expect(newState.isSuccess, isTrue);
    });
  });

  group('ProfileEditNotifier validation', () {
    late ProviderContainer container;
    late ProfileEditNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(profileEditNotifierProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('should validate empty display name', () {
      final result = notifier.validateDisplayName('');

      expect(result, isNotNull);
      expect(result, contains('表示名を入力してください'));
    });

    test('should validate null display name', () {
      final result = notifier.validateDisplayName(null);

      expect(result, isNotNull);
      expect(result, contains('表示名を入力してください'));
    });

    test('should validate display name exceeding 30 characters', () {
      final longName = 'a' * 31;
      final result = notifier.validateDisplayName(longName);

      expect(result, isNotNull);
      expect(result, contains('30文字以内'));
    });

    test('should accept valid display name at boundary (30 chars)', () {
      final validName = 'a' * 30;
      final result = notifier.validateDisplayName(validName);

      expect(result, isNull);
    });

    test('should accept valid display name', () {
      final result = notifier.validateDisplayName('テストユーザー');

      expect(result, isNull);
    });

    test('should validate bio exceeding 200 characters', () {
      final longBio = 'a' * 201;
      final result = notifier.validateBio(longBio);

      expect(result, isNotNull);
      expect(result, contains('200文字以内'));
    });

    test('should accept valid bio at boundary (200 chars)', () {
      final validBio = 'a' * 200;
      final result = notifier.validateBio(validBio);

      expect(result, isNull);
    });

    test('should accept null bio', () {
      final result = notifier.validateBio(null);

      expect(result, isNull);
    });

    test('should accept empty bio', () {
      final result = notifier.validateBio('');

      expect(result, isNull);
    });

    test('clearError should clear error state', () {
      // Set up an error state first by modifying internal state
      container.read(profileEditNotifierProvider.notifier).clearError();

      final state = container.read(profileEditNotifierProvider);
      expect(state.error, isNull);
    });
  });
}
