import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldsilver_chef/models/models.dart';
import 'package:goldsilver_chef/services/crafting_engine.dart';
import 'package:goldsilver_chef/services/game_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// BUG-2: 빈 allRecipes에서 requestJudging, useResultAsIngredient 크래시 안 함
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  group('빈 allRecipes에서 크래시 방지', () {
    late GameState state;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      state = GameState();
      // 엔진에 최소 재료만 로드, 레시피 없음
      state.engine.loadIngredients([
        const Ingredient(id: 'meat', name: '고기', type: IngredientType.meat, isBase: true),
      ]);
      state.engine.loadRecipes([]); // 빈 레시피 목록
    });

    test('빈 레시피 상태에서 findMatchingRecipe는 null 반환', () {
      state.addIngredient('meat');
      expect(state.findMatchingRecipe(), isNull);
    });

    test('빈 레시피 상태에서 cook은 절차적 레시피 생성', () {
      state.addIngredient('meat');
      final result = state.cook();
      // 절차적 생성이므로 failed가 아님
      expect(result.recipeId, isNot(equals('failed')));
      expect(result.recipeName, isNotEmpty);
    });

    test('requestJudging에서 레시피 못 찾아도 크래시 안 함', () {
      state.addIngredient('meat');
      state.cook();

      // isProcedural=true이므로 tempRecipe 경로 → 크래시 없음
      final judging = state.requestJudging();
      expect(judging, isNotNull);
      expect(judging!.finalScore.isFinite, isTrue);
    });

    test('정적 레시피 결과가 있지만 allRecipes가 비어있을 때 useResultAsIngredient 크래시 안 함', () {
      // 레시피가 있는 상태에서 cook
      state.engine.loadRecipes([
        const Recipe(
          id: 'r1',
          name: '테스트요리',
          inputs: [RecipeInput(ingredientId: 'meat')],
          outputIngredientId: 'cooked_meat',
        ),
      ]);
      state.addIngredient('meat');
      state.cook();

      // 이제 레시피를 비우고 useResultAsIngredient 호출
      state.engine.loadRecipes([]);
      // 크래시 없이 실행되어야 함
      state.useResultAsIngredient();
      // recipe를 못 찾으므로 selectedIngredients에 아무것도 추가 안 됨
      expect(state.selectedIngredients, isEmpty);
    });
  });
}
