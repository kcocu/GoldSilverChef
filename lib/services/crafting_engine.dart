import '../models/models.dart';

/// 조합 엔진 — 재료 조합 매칭 + 연쇄 조합 지원
class CraftingEngine {
  final Map<String, Ingredient> _ingredients = {};
  final List<Recipe> _recipes = [];

  // 성능 최적화: outputIngredientId → Recipe 목록 인덱스
  final Map<String, List<Recipe>> _recipesByOutput = {};
  // 성능 최적화: 입력 재료 세트 해시 → Recipe 목록 인덱스
  final Map<String, List<Recipe>> _recipesByInputSet = {};

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
    _buildIndices();
  }

  void _buildIndices() {
    _recipesByOutput.clear();
    _recipesByInputSet.clear();
    for (final recipe in _recipes) {
      _recipesByOutput.putIfAbsent(recipe.outputIngredientId, () => []).add(recipe);
      final key = _inputSetKey(recipe.inputs.map((i) => i.ingredientId).toList());
      _recipesByInputSet.putIfAbsent(key, () => []).add(recipe);
    }
  }

  static String _inputSetKey(List<String> ids) {
    final sorted = List<String>.from(ids)..sort();
    return sorted.join('|');
  }

  Ingredient? getIngredient(String id) => _ingredients[id];

  List<Ingredient> get allIngredients => _ingredients.values.toList();

  List<Ingredient> get baseIngredients =>
      _ingredients.values.where((i) => i.isBase).toList();

  List<Recipe> get allRecipes => List.unmodifiable(_recipes);

  /// 주어진 재료 ID 목록으로 만들 수 있는 레시피 찾기
  List<Recipe> findRecipes(List<String> ingredientIds) {
    final key = _inputSetKey(ingredientIds);
    return _recipesByInputSet[key] ?? [];
  }

  /// 특정 재료가 포함된 모든 레시피 찾기
  List<Recipe> findRecipesContaining(String ingredientId) {
    return _recipes.where((recipe) {
      return recipe.inputs.any((i) => i.ingredientId == ingredientId);
    }).toList();
  }

  /// 특정 결과물을 만드는 레시피 찾기 (인덱스 사용, O(1))
  List<Recipe> findRecipesForOutput(String outputIngredientId) {
    return _recipesByOutput[outputIngredientId] ?? [];
  }

  /// 해금된 재료 세트로 다음에 발견 가능한 재료 ID 목록 구하기
  /// (모든 입력 재료가 unlockedIds에 포함된 레시피의 출력물)
  Set<String> findDiscoverableOutputs(Set<String> unlockedIds) {
    final discoverable = <String>{};
    for (final recipe in _recipes) {
      if (unlockedIds.contains(recipe.outputIngredientId)) continue;
      final allInputsUnlocked = recipe.inputs.every(
        (input) => unlockedIds.contains(input.ingredientId),
      );
      if (allInputsUnlocked) {
        discoverable.add(recipe.outputIngredientId);
      }
    }
    return discoverable;
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
    for (final input in recipe.inputs) {
      _buildChain(input.ingredientId, chain, visited);
    }
    chain.add(recipe);
  }
}
