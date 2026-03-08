import 'package:flutter_test/flutter_test.dart';
import 'package:goldsilver_chef/services/recipe_book.dart';

/// BUG-1: 새 레시피 발견 여부를 정확히 판별하는지 테스트
void main() {
  group('RecipeBook.discover() 발견 여부 판별', () {
    late RecipeBook book;

    setUp(() {
      book = RecipeBook();
    });

    test('처음 발견한 레시피는 isNew=true 반환', () {
      final isNew = book.discover('recipe_001');
      expect(isNew, isTrue);
    });

    test('이미 발견한 레시피는 isNew=false 반환', () {
      book.discover('recipe_001');
      final isNew = book.discover('recipe_001');
      expect(isNew, isFalse);
    });

    test('discover 후 isDiscovered가 true', () {
      expect(book.isDiscovered('recipe_001'), isFalse);
      book.discover('recipe_001');
      expect(book.isDiscovered('recipe_001'), isTrue);
    });

    test('cook 전 discovered 스냅샷으로 새 발견 판별 시뮬레이션', () {
      // 기존에 알고 있는 레시피
      book.discover('old_recipe');

      // cook() 호출 전 스냅샷
      final knownBefore = book.discovered.toSet();

      // cook() 내부에서 새 레시피 discover 호출
      book.discover('new_recipe');

      // 스냅샷 기반 판별
      expect(knownBefore.contains('new_recipe'), isFalse); // 새 발견
      expect(knownBefore.contains('old_recipe'), isTrue);   // 기존 레시피
    });

    test('여러 레시피 발견 후 discovered 세트 정확성', () {
      book.discover('a');
      book.discover('b');
      book.discover('c');
      book.discover('a'); // 중복

      expect(book.discovered.length, equals(3));
      expect(book.discovered, containsAll(['a', 'b', 'c']));
    });
  });
}
