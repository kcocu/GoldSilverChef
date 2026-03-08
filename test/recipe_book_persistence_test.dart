import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldsilver_chef/services/recipe_book.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// RecipeBook 데이터 무결성 테스트
/// SharedPreferences 저장/로드는 통합 테스트가 필요하므로
/// 여기서는 메모리 내 동작만 검증
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  group('RecipeBook 메모리 내 무결성', () {
    late RecipeBook book;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      book = RecipeBook();
    });

    test('discover → isDiscovered 일관성', () {
      expect(book.isDiscovered('r1'), isFalse);
      book.discover('r1');
      expect(book.isDiscovered('r1'), isTrue);
    });

    test('toggleFavorite 토글 동작', () {
      book.discover('r1');

      expect(book.isFavorite('r1'), isFalse);
      book.toggleFavorite('r1');
      expect(book.isFavorite('r1'), isTrue);
      book.toggleFavorite('r1');
      expect(book.isFavorite('r1'), isFalse);
    });

    test('removeDiscovered는 discovered + favorites + customRecipes 모두 제거', () {
      book.discover('r1');
      book.toggleFavorite('r1');
      book.saveCustomRecipe(
        id: 'r1',
        name: '테스트',
        ingredientIds: ['a', 'b'],
        grade: 'A',
        category: '한식',
      );

      expect(book.isDiscovered('r1'), isTrue);
      expect(book.isFavorite('r1'), isTrue);
      expect(book.customRecipes.containsKey('r1'), isTrue);

      book.removeDiscovered('r1');

      expect(book.isDiscovered('r1'), isFalse);
      expect(book.isFavorite('r1'), isFalse);
      expect(book.customRecipes.containsKey('r1'), isFalse);
    });

    test('saveCustomRecipe는 discovered에도 자동 추가', () {
      book.saveCustomRecipe(
        id: 'custom_1',
        name: '커스텀 요리',
        ingredientIds: ['meat', 'salt'],
        grade: 'B',
        category: '퓨전',
      );

      expect(book.isDiscovered('custom_1'), isTrue);
      expect(book.customRecipes['custom_1']!['name'], equals('커스텀 요리'));
      expect(book.customRecipes['custom_1']!['grade'], equals('B'));
    });

    test('같은 ID로 saveCustomRecipe하면 덮어쓰기', () {
      book.saveCustomRecipe(
        id: 'c1',
        name: '첫 번째',
        ingredientIds: ['a'],
        grade: 'C',
        category: '한식',
      );
      book.saveCustomRecipe(
        id: 'c1',
        name: '두 번째',
        ingredientIds: ['a', 'b'],
        grade: 'A',
        category: '양식',
      );

      expect(book.customRecipes['c1']!['name'], equals('두 번째'));
      expect(book.customRecipes['c1']!['grade'], equals('A'));
      // discovered에는 한 번만 존재
      expect(book.discovered.where((id) => id == 'c1').length, equals(1));
    });

    test('discovered/favorites/customRecipes getter는 unmodifiable', () {
      book.discover('r1');
      book.toggleFavorite('r1');
      book.saveCustomRecipe(
        id: 'c1', name: 'C', ingredientIds: [], grade: 'F', category: '',
      );

      expect(() => (book.discovered as Set<String>).add('hack'), throwsUnsupportedError);
      expect(() => (book.favorites as Set<String>).add('hack'), throwsUnsupportedError);
      expect(() => (book.customRecipes as Map).remove('c1'), throwsUnsupportedError);
    });
  });
}
