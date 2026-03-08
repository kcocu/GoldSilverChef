import 'package:flutter_test/flutter_test.dart';
import 'package:goldsilver_chef/models/models.dart';

/// BUG-3: 잘못된 JSON에서 모델 파싱 안전성
/// DataLoader 자체는 rootBundle이 필요하므로 모델 레벨에서 테스트
void main() {
  group('Ingredient.fromJson 안전성', () {
    test('정상 JSON 파싱', () {
      final ing = Ingredient.fromJson({
        'id': 'meat',
        'name': '고기',
        'type': 'meat',
        'icon': '🥩',
        'isBase': true,
        'tier': 0,
      });
      expect(ing.id, equals('meat'));
      expect(ing.type, equals(IngredientType.meat));
      expect(ing.isBase, isTrue);
    });

    test('잘못된 type 문자열은 derived로 폴백', () {
      final ing = Ingredient.fromJson({
        'id': 'unknown',
        'name': '미지의 재료',
        'type': 'invalid_type_name',
      });
      expect(ing.type, equals(IngredientType.derived));
    });

    test('누락된 선택 필드는 기본값 사용', () {
      final ing = Ingredient.fromJson({
        'id': 'test',
        'name': '테스트',
        'type': 'grain',
      });
      expect(ing.icon, equals('🧂'));
      expect(ing.isBase, isFalse);
      expect(ing.tier, equals(0));
      expect(ing.description, isNull);
    });
  });

  group('Recipe.fromJson 안전성', () {
    test('정상 Recipe JSON 파싱', () {
      final recipe = Recipe.fromJson({
        'id': 'r1',
        'name': '테스트 요리',
        'inputs': [
          {'ingredientId': 'meat'},
          {'ingredientId': 'salt'},
        ],
        'outputIngredientId': 'salted_meat',
        'knife': {'min': 1, 'max': 10, 'optimal': 5},
        'difficulty': 3,
        'tier': 1,
        'category': '한식',
      });
      expect(recipe.id, equals('r1'));
      expect(recipe.inputs.length, equals(2));
      expect(recipe.knife, isNotNull);
      expect(recipe.knife!.optimal, equals(5));
      expect(recipe.difficulty, equals(3));
    });

    test('선택 필드 누락 시 기본값', () {
      final recipe = Recipe.fromJson({
        'id': 'r2',
        'name': '간단 요리',
        'inputs': [{'ingredientId': 'grain'}],
        'outputIngredientId': 'cooked_grain',
      });
      expect(recipe.knife, isNull);
      expect(recipe.water, isNull);
      expect(recipe.fire, isNull);
      expect(recipe.difficulty, equals(1));
      expect(recipe.tier, equals(0));
      expect(recipe.category, equals('기타'));
    });
  });

  group('ToolRange 정확도 계산', () {
    test('최적값에서 정확도 1.0', () {
      const range = ToolRange(min: 0, max: 10, optimal: 5);
      expect(range.accuracy(5), equals(1.0));
    });

    test('범위 밖에서 정확도 0.0', () {
      const range = ToolRange(min: 2, max: 10, optimal: 5);
      expect(range.accuracy(0), equals(0.0));
      expect(range.accuracy(11), equals(0.0));
    });

    test('min==max==optimal이면 정확도 1.0', () {
      const range = ToolRange(min: 5, max: 5, optimal: 5);
      expect(range.accuracy(5), equals(1.0));
    });

    test('경계값에서 정확도 계산', () {
      const range = ToolRange(min: 0, max: 10, optimal: 5);
      final acc = range.accuracy(0);
      expect(acc, greaterThanOrEqualTo(0.0));
      expect(acc, lessThanOrEqualTo(1.0));
    });
  });
}
