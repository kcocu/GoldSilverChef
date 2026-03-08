import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/models.dart';
import 'crafting_engine.dart';

/// 레시피/재료 JSON 데이터 로더
class DataLoader {
  static Future<void> loadAll(CraftingEngine engine) async {
    final String jsonStr;
    try {
      jsonStr = await rootBundle.loadString('assets/data/recipes.json');
    } catch (e) {
      throw Exception('레시피 데이터 파일을 불러올 수 없습니다: $e');
    }

    final Map<String, dynamic> data;
    try {
      data = json.decode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('레시피 데이터 형식이 올바르지 않습니다: $e');
    }

    if (data['ingredients'] is! List) {
      throw Exception('레시피 데이터에 ingredients 목록이 없습니다.');
    }
    if (data['recipes'] is! List) {
      throw Exception('레시피 데이터에 recipes 목록이 없습니다.');
    }

    final ingredients = (data['ingredients'] as List)
        .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
        .toList();

    final recipes = (data['recipes'] as List)
        .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
        .toList();

    engine.loadIngredients(ingredients);
    engine.loadRecipes(recipes);
  }
}
