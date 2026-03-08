import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/models.dart';
import 'crafting_engine.dart';

/// 레시피/재료 JSON 데이터 로더
class DataLoader {
  static Future<void> loadAll(CraftingEngine engine) async {
    final jsonStr = await rootBundle.loadString('assets/data/recipes.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;

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
