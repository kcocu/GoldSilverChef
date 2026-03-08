import '../models/models.dart';

/// 조합 엔진 — 재료 조합 매칭 + 연쇄 조합 지원
class CraftingEngine {
  final Map<String, Ingredient> _ingredients = {};
  final List<Recipe> _recipes = [];

  /// 재료 데이터 로드
  void loadIngredients(List<Ingredient> ingredients) {
    _ingredients.clear();
    for (final ing in ingredients) {
      _ingredients[ing.id] = ing;
    }
  }

  /// 레시피 데이터 로드
  void loadRecipes(List<Recipe> recipes) {
    _recipes.clear();
    _recipes.addAll(recipes);
  }

  Ingredient? getIngredient(String id) => _ingredients[id];

  List<Ingredient> get allIngredients => _ingredients.values.toList();

  List<Ingredient> get baseIngredients =>
      _ingredients.values.where((i) => i.isBase).toList();

  List<Recipe> get allRecipes => List.unmodifiable(_recipes);

  /// 주어진 재료 ID 목록으로 만들 수 있는 레시피 찾기
  List<Recipe> findRecipes(List<String> ingredientIds) {
    final inputSet = ingredientIds.toSet();
    return _recipes.where((recipe) {
      final recipeInputIds = recipe.inputs.map((i) => i.ingredientId).toSet();
      return recipeInputIds.length == inputSet.length &&
          recipeInputIds.difference(inputSet).isEmpty;
    }).toList();
  }

  /// 특정 재료가 포함된 모든 레시피 찾기
  List<Recipe> findRecipesContaining(String ingredientId) {
    return _recipes.where((recipe) {
      return recipe.inputs.any((i) => i.ingredientId == ingredientId);
    }).toList();
  }

  /// 특정 결과물을 만드는 레시피 찾기
  List<Recipe> findRecipesForOutput(String outputIngredientId) {
    return _recipes.where((r) => r.outputIngredientId == outputIngredientId).toList();
  }

  /// 재료의 조합 경로 힌트 (주제 재료가 주어졌을 때)
  List<Recipe> getRecipeChain(String targetIngredientId) {
    final chain = <Recipe>[];
    _buildChain(targetIngredientId, chain, <String>{});
    return chain;
  }

  void _buildChain(String ingredientId, List<Recipe> chain, Set<String> visited) {
    if (visited.contains(ingredientId)) return;
    visited.add(ingredientId);

    final ingredient = _ingredients[ingredientId];
    if (ingredient == null || ingredient.isBase) return;

    final recipes = findRecipesForOutput(ingredientId);
    if (recipes.isEmpty) return;

    final recipe = recipes.first;
    // 먼저 하위 재료들의 체인을 구함
    for (final input in recipe.inputs) {
      _buildChain(input.ingredientId, chain, visited);
    }
    chain.add(recipe);
  }
}
