import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 레시피북 — 발견한 레시피 자동 기록 + 즐겨찾기
class RecipeBook {
  static const _discoveredKey = 'recipe_book_discovered';
  static const _favoritesKey = 'recipe_book_favorites';

  final Set<String> _discovered = {};
  final Set<String> _favorites = {};

  Set<String> get discovered => Set.unmodifiable(_discovered);
  Set<String> get favorites => Set.unmodifiable(_favorites);

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

  /// 로컬 저장소에서 로드
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final discoveredJson = prefs.getString(_discoveredKey);
    final favoritesJson = prefs.getString(_favoritesKey);

    if (discoveredJson != null) {
      _discovered.addAll(List<String>.from(json.decode(discoveredJson)));
    }
    if (favoritesJson != null) {
      _favorites.addAll(List<String>.from(json.decode(favoritesJson)));
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_discoveredKey, json.encode(_discovered.toList()));
    await prefs.setString(_favoritesKey, json.encode(_favorites.toList()));
  }
}
