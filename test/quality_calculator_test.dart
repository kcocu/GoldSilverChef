import 'package:flutter_test/flutter_test.dart';
import 'package:goldsilver_chef/models/models.dart';
import 'package:goldsilver_chef/services/quality_calculator.dart';

/// QualityCalculator 경계값 테스트 (accuracy 0, 1, 중간값)
void main() {
  const testRecipe = Recipe(
    id: 'test',
    name: '테스트 요리',
    inputs: [RecipeInput(ingredientId: 'meat')],
    outputIngredientId: 'cooked_meat',
    knife: ToolRange(min: 3, max: 10, optimal: 7),
    water: ToolRange(min: 10, max: 30, optimal: 20),
    fire: ToolRange(min: 5, max: 15, optimal: 10),
    difficulty: 5,
  );

  group('QualityCalculator.calculate', () {
    test('최적값 입력 시 높은 등급', () {
      final result = QualityCalculator.calculate(
        recipe: testRecipe,
        knifeValue: 7,
        waterValue: 20,
        fireValue: 10,
      );
      expect(result.overallAccuracy, equals(1.0));
      expect(result.grade, equals(QualityGrade.SSPlus));
    });

    test('범위 밖 입력 시 정확도 0 → F등급', () {
      final result = QualityCalculator.calculate(
        recipe: testRecipe,
        knifeValue: 0,  // 범위 밖
        waterValue: 0,  // 범위 밖
        fireValue: 0,   // 범위 밖
      );
      expect(result.knifeAccuracy, equals(0.0));
      expect(result.waterAccuracy, equals(0.0));
      expect(result.fireAccuracy, equals(0.0));
      expect(result.overallAccuracy, equals(0.0));
      expect(result.grade, equals(QualityGrade.F));
    });

    test('도구 미사용 레시피는 정확도 1.0', () {
      const noToolRecipe = Recipe(
        id: 'simple',
        name: '간단 요리',
        inputs: [RecipeInput(ingredientId: 'grain')],
        outputIngredientId: 'cooked_grain',
        // knife, water, fire 모두 null
      );
      final result = QualityCalculator.calculate(
        recipe: noToolRecipe,
        knifeValue: 0,
        waterValue: 0,
        fireValue: 0,
      );
      expect(result.overallAccuracy, equals(1.0));
      expect(result.grade, equals(QualityGrade.SSPlus));
    });

    test('중간 결과가 최종 정확도에 30% 반영', () {
      final intermediates = [
        CookingResult(
          recipeId: 'prev',
          recipeName: '이전 요리',
          grade: QualityGrade.A,
          overallAccuracy: 0.5,
        ),
      ];

      final withIntermediate = QualityCalculator.calculate(
        recipe: testRecipe,
        knifeValue: 7,
        waterValue: 20,
        fireValue: 10,
        intermediateResults: intermediates,
      );

      final withoutIntermediate = QualityCalculator.calculate(
        recipe: testRecipe,
        knifeValue: 7,
        waterValue: 20,
        fireValue: 10,
      );

      // 중간 결과 0.5 반영 → 최종 정확도가 낮아져야 함
      expect(withIntermediate.overallAccuracy, lessThan(withoutIntermediate.overallAccuracy));
      // 1.0 * 0.7 + 0.5 * 0.3 = 0.85
      expect(withIntermediate.overallAccuracy, closeTo(0.85, 0.01));
    });

    test('부분적으로 도구 사용 시 사용된 도구만 평균', () {
      const partialRecipe = Recipe(
        id: 'partial',
        name: '칼만 쓰는 요리',
        inputs: [RecipeInput(ingredientId: 'meat')],
        outputIngredientId: 'sliced_meat',
        knife: ToolRange(min: 3, max: 10, optimal: 7),
        // water, fire는 null
      );
      final result = QualityCalculator.calculate(
        recipe: partialRecipe,
        knifeValue: 7,
        waterValue: 50,  // 이 값은 무시됨
        fireValue: 100,  // 이 값도 무시됨
      );
      // 칼질만 최적값이므로 정확도 1.0
      expect(result.overallAccuracy, equals(1.0));
    });
  });

  group('등급 경계값', () {
    test('모든 등급 경계 테스트', () {
      // 정확도 → 등급 매핑을 도구 없는 레시피로 간접 확인
      // QualityCalculator 내부의 _accuracyToGrade가 private이므로
      // 다양한 정확도에서 결과 등급 확인
      const recipe = Recipe(
        id: 'r',
        name: 'R',
        inputs: [RecipeInput(ingredientId: 'x')],
        outputIngredientId: 'y',
        knife: ToolRange(min: 0, max: 100, optimal: 50),
      );

      // 최적값(50) → accuracy 1.0 → SS+
      final best = QualityCalculator.calculate(recipe: recipe, knifeValue: 50, waterValue: 0, fireValue: 0);
      expect(best.grade, equals(QualityGrade.SSPlus));

      // 범위 밖 → accuracy 0.0 → F
      final worst = QualityCalculator.calculate(recipe: recipe, knifeValue: 200, waterValue: 0, fireValue: 0);
      expect(worst.grade, equals(QualityGrade.F));
    });
  });
}
