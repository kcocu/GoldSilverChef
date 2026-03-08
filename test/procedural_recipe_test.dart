import 'package:flutter_test/flutter_test.dart';
import 'package:goldsilver_chef/models/models.dart';
import 'package:goldsilver_chef/services/procedural_recipe.dart';

/// 절차적 레시피 엔진 테스트 — 비밀 레시피 트리거 + 코멘트 생성
void main() {
  group('ProceduralRecipeEngine 기본 동작', () {
    test('빈 재료 목록 → 실패 결과', () {
      final result = ProceduralRecipeEngine.generate(
        ingredients: [],
        knifeValue: 0,
        waterValue: 0,
        fireValue: 0,
      );
      expect(result.name, equals('아무것도 아닌 것'));
      expect(result.sanityScore, equals(0));
      expect(result.category, equals('실패'));
    });

    test('단일 재료로 절차적 레시피 생성', () {
      final result = ProceduralRecipeEngine.generate(
        ingredients: [
          const Ingredient(id: 'meat', name: '고기', type: IngredientType.meat, isBase: true),
        ],
        knifeValue: 5,
        waterValue: 0,
        fireValue: 10,
      );
      expect(result.name, isNotEmpty);
      expect(result.sanityScore, greaterThan(0));
      expect(result.toolRanges, isNotEmpty);
    });

    test('궁합 좋은 조합은 높은 sanityScore', () {
      final good = ProceduralRecipeEngine.generate(
        ingredients: [
          const Ingredient(id: 'meat', name: '고기', type: IngredientType.meat),
          const Ingredient(id: 'vegetable', name: '채소', type: IngredientType.vegetable),
          const Ingredient(id: 'seasoning', name: '양념', type: IngredientType.seasoning),
        ],
        knifeValue: 5,
        waterValue: 10,
        fireValue: 15,
      );

      final bad = ProceduralRecipeEngine.generate(
        ingredients: [
          const Ingredient(id: 'sugar', name: '설탕', type: IngredientType.sugar),
          const Ingredient(id: 'seafood', name: '수산물', type: IngredientType.seafood),
          const Ingredient(id: 'mushroom', name: '버섯', type: IngredientType.mushroom),
        ],
        knifeValue: 5,
        waterValue: 10,
        fireValue: 15,
      );

      expect(good.sanityScore, greaterThan(bad.sanityScore));
    });
  });

  group('비밀 레시피 트리거', () {
    test('소금 5개 이상 → 소금 폭탄', () {
      final result = ProceduralRecipeEngine.generate(
        ingredients: List.generate(5, (_) =>
          const Ingredient(id: 'salt', name: '소금', type: IngredientType.salt, isBase: true)),
        knifeValue: 0,
        waterValue: 0,
        fireValue: 0,
      );
      expect(result.name, equals('소금 폭탄'));
      expect(result.isSecret, isTrue);
      expect(result.comment, contains('혈압'));
    });

    test('설탕 5개 이상 → 설탕 지옥 디저트', () {
      final result = ProceduralRecipeEngine.generate(
        ingredients: List.generate(5, (_) =>
          const Ingredient(id: 'sugar', name: '설탕', type: IngredientType.sugar, isBase: true)),
        knifeValue: 0,
        waterValue: 0,
        fireValue: 0,
      );
      expect(result.name, equals('설탕 지옥 디저트'));
      expect(result.isSecret, isTrue);
    });

    test('소금 3개 + 물 → 인공 바닷물 요리', () {
      final ingredients = [
        ...List.generate(3, (_) =>
          const Ingredient(id: 'salt', name: '소금', type: IngredientType.salt, isBase: true)),
        const Ingredient(id: 'liquid', name: '물', type: IngredientType.liquid, isBase: true),
      ];
      final result = ProceduralRecipeEngine.generate(
        ingredients: ingredients,
        knifeValue: 0,
        waterValue: 10,
        fireValue: 0,
      );
      expect(result.name, equals('인공 바닷물 요리'));
      expect(result.isSecret, isTrue);
    });

    test('고기 5개 이상 → 육식공룡의 만찬', () {
      final result = ProceduralRecipeEngine.generate(
        ingredients: List.generate(5, (_) =>
          const Ingredient(id: 'meat', name: '고기', type: IngredientType.meat, isBase: true)),
        knifeValue: 0,
        waterValue: 0,
        fireValue: 0,
      );
      expect(result.name, equals('육식공룡의 만찬'));
      expect(result.isSecret, isTrue);
    });

    test('기름 3개 이상 → 기름의 바다', () {
      final result = ProceduralRecipeEngine.generate(
        ingredients: List.generate(3, (_) =>
          const Ingredient(id: 'oil', name: '기름', type: IngredientType.oil, isBase: true)),
        knifeValue: 0,
        waterValue: 0,
        fireValue: 0,
      );
      expect(result.name, equals('기름의 바다'));
      expect(result.isSecret, isTrue);
    });

    test('불 극대 (fireValue > 80) → 까맣게 탄', () {
      final result = ProceduralRecipeEngine.generate(
        ingredients: [
          const Ingredient(id: 'meat', name: '고기', type: IngredientType.meat, isBase: true),
        ],
        knifeValue: 0,
        waterValue: 0,
        fireValue: 100,
      );
      expect(result.name, contains('까맣게 탄'));
      expect(result.isSecret, isTrue);
      expect(result.comment, contains('재'));
    });
  });

  group('도구 코멘트 생성', () {
    test('칼질만 사용 시 칼질 코멘트', () {
      final result = ProceduralRecipeEngine.generate(
        ingredients: [
          const Ingredient(id: 'meat', name: '고기', type: IngredientType.meat, isBase: true),
        ],
        knifeValue: 10,
        waterValue: 0,
        fireValue: 0,
      );
      expect(result.comment, isNotEmpty);
      expect(result.comment, contains('썰'));
    });

    test('고기 + 불 → 레어/미디엄/웰던 관련 코멘트', () {
      // 약한 불 → 레어
      final rare = ProceduralRecipeEngine.generate(
        ingredients: [
          const Ingredient(id: 'meat', name: '고기', type: IngredientType.meat, isBase: true),
        ],
        knifeValue: 0,
        waterValue: 0,
        fireValue: 3,
      );
      expect(rare.comment, contains('레어'));

      // 강한 불 → 웰던
      final wellDone = ProceduralRecipeEngine.generate(
        ingredients: [
          const Ingredient(id: 'meat', name: '고기', type: IngredientType.meat, isBase: true),
        ],
        knifeValue: 0,
        waterValue: 0,
        fireValue: 45,
      );
      expect(wellDone.comment, contains('웰던'));
    });

    test('도구 미사용 시 날것 코멘트', () {
      final result = ProceduralRecipeEngine.generate(
        ingredients: [
          const Ingredient(id: 'vegetable', name: '채소', type: IngredientType.vegetable, isBase: true),
        ],
        knifeValue: 0,
        waterValue: 0,
        fireValue: 0,
      );
      expect(result.comment, contains('날것'));
    });
  });

  group('sanityMultiplier 계산', () {
    test('높은 궁합 → 1.0 이상', () {
      expect(ProceduralRecipeEngine.sanityMultiplier(0.9), greaterThanOrEqualTo(1.0));
    });

    test('낮은 궁합 → 1.0 미만', () {
      expect(ProceduralRecipeEngine.sanityMultiplier(0.3), lessThan(1.0));
    });

    test('0 궁합 → 최소값', () {
      final mult = ProceduralRecipeEngine.sanityMultiplier(0.0);
      expect(mult, greaterThan(0));
      expect(mult, lessThan(0.5));
    });
  });
}
