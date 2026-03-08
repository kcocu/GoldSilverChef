import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 레시피북 — 발견한 레시피 자동 기록 + 즐겨찾기 + 커스텀 레시피 저장
class RecipeBook {
  static const _discoveredKey = 'recipe_book_discovered';
  static const _favoritesKey = 'recipe_book_favorites';
  static const _customRecipesKey = 'recipe_book_custom';

  final Set<String> _discovered = {};
  final Set<String> _favorites = {};
  // 커스텀 레시피: 절차적 생성 요리 저장 {id: {name, ingredients, grade, category}}
  final Map<String, Map<String, dynamic>> _customRecipes = {};

  Set<String> get discovered => Set.unmodifiable(_discovered);
  Set<String> get favorites => Set.unmodifiable(_favorites);
  Map<String, Map<String, dynamic>> get customRecipes => Map.unmodifiable(_customRecipes);

  bool isDiscovered(String recipeId) => _discovered.contains(recipeId);
  bool isFavorite(String recipeId) => _favorites.contains(recipeId);

  /// 레시피 발견 등록
  bool discover(String recipeId) {
    final isNew = _discovered.add(recipeId);
    if (isNew) _save();
    return isNew;
  }

  /// 즐겨찾기 토글
  bool toggleFavorite(String recipeId) {
    if (_favorites.contains(recipeId)) {
      _favorites.remove(recipeId);
    } else {
      _favorites.add(recipeId);
    }
    _save();
    return _favorites.contains(recipeId);
  }

  /// 레시피 삭제 (발견 목록에서)
  void removeDiscovered(String recipeId) {
    _discovered.remove(recipeId);
    _favorites.remove(recipeId);
    _customRecipes.remove(recipeId);
    _save();
  }

  /// 커스텀 레시피 저장 (절차적 생성 요리)
  void saveCustomRecipe({
    required String id,
    required String name,
    required List<String> ingredientIds,
    required String grade,
    required String category,
  }) {
    _customRecipes[id] = {
      'name': name,
      'ingredients': ingredientIds,
      'grade': grade,
      'category': category,
    };
    _discovered.add(id);
    _save();
  }

  /// 로컬 저장소에서 로드
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final discoveredJson = prefs.getString(_discoveredKey);
    final favoritesJson = prefs.getString(_favoritesKey);
    final customJson = prefs.getString(_customRecipesKey);

    if (discoveredJson != null) {
      _discovered.addAll(List<String>.from(json.decode(discoveredJson)));
    }
    if (favoritesJson != null) {
      _favorites.addAll(List<String>.from(json.decode(favoritesJson)));
    }
    if (customJson != null) {
      final map = json.decode(customJson) as Map<String, dynamic>;
      for (final entry in map.entries) {
        _customRecipes[entry.key] = Map<String, dynamic>.from(entry.value);
      }
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_discoveredKey, json.encode(_discovered.toList()));
      await prefs.setString(_favoritesKey, json.encode(_favorites.toList()));
      await prefs.setString(_customRecipesKey, json.encode(_customRecipes));
    } catch (e) {
      debugPrint('RecipeBook 저장 실패: $e');
    }
  }
}
