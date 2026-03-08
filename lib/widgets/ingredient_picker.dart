import 'dart:math';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/crafting_engine.dart';
import '../services/ingredient_image_map.dart';
import '../services/recipe_book.dart';

class IngredientPicker extends StatefulWidget {
  final CraftingEngine engine;
  final RecipeBook recipeBook;
  final Function(String) onSelect;
  final bool isRandom;

  const IngredientPicker({
    super.key,
    required this.engine,
    required this.recipeBook,
    required this.onSelect,
    this.isRandom = false,
  });

  @override
  State<IngredientPicker> createState() => _IngredientPickerState();
}

class _IngredientPickerState extends State<IngredientPicker> {
  String _search = '';
  int _tierFilter = -1; // -1 = 전체
  late List<Ingredient> _randomized;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    if (widget.isRandom) {
      _randomized = List<Ingredient>.from(widget.engine.allIngredients)..shuffle(_random);
    }
  }

  /// 해금된 재료인지 확인 (기본 재료 or 레시피북에 발견된 재료)
  bool _isUnlocked(Ingredient ing) {
    if (ing.isBase) return true;
    // 이 재료를 결과물로 만드는 레시피가 발견되었는지 확인
    final recipes = widget.engine.findRecipesForOutput(ing.id);
    return recipes.any((r) => widget.recipeBook.isDiscovered(r.id));
  }

  @override
  Widget build(BuildContext context) {
    List<Ingredient> ingredients;
    if (widget.isRandom) {
      ingredients = _randomized;
    } else {
      ingredients = widget.engine.allIngredients;
    }

    // 기본 재료 + 해금된 파생만 표시 (미해금 파생도 잠금 상태로 표시)
    if (_tierFilter >= 0) {
      if (_tierFilter == 0) {
        ingredients = ingredients.where((i) => i.isBase).toList();
      } else {
        ingredients = ingredients.where((i) => !i.isBase && i.tier >= 1).toList();
      }
    }
    if (_search.isNotEmpty) {
      ingredients = ingredients.where((i) => i.name.contains(_search)).toList();
    }

    // 기본 재료 먼저, 해금된 것 먼저
    if (!widget.isRandom) {
      ingredients.sort((a, b) {
        if (a.isBase && !b.isBase) return -1;
        if (!a.isBase && b.isBase) return 1;
        final aUnlocked = _isUnlocked(a);
        final bUnlocked = _isUnlocked(b);
        if (aUnlocked && !bUnlocked) return -1;
        if (!aUnlocked && bUnlocked) return 1;
        return a.tier.compareTo(b.tier);
      });
    }

    // 파생 탭에서는 기본 + 해금 파생 + 일부 미해금(힌트용) 만 표시
    // 미해금이 너무 많으면 해금된 것 기준 주변만
    if (_tierFilter == 1) {
      final unlocked = ingredients.where((i) => _isUnlocked(i)).toList();
      final locked = ingredients.where((i) => !_isUnlocked(i)).take(50).toList();
      ingredients = [...unlocked, ...locked];
    }

    return Column(
      children: [
        // 검색 + 필터
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: '재료 검색...',
                    prefixIcon: Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(width: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: -1, label: Text('전체', style: TextStyle(fontSize: 11))),
                  ButtonSegment(value: 0, label: Text('기본', style: TextStyle(fontSize: 11))),
                  ButtonSegment(value: 1, label: Text('파생', style: TextStyle(fontSize: 11))),
                ],
                selected: {_tierFilter == -1 ? -1 : (_tierFilter == 0 ? 0 : 1)},
                onSelectionChanged: (v) {
                  setState(() {
                    final val = v.first;
                    if (val == -1) _tierFilter = -1;
                    else if (val == 0) _tierFilter = 0;
                    else _tierFilter = 1;
                  });
                },
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),

        // 재료 그리드
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 100,
              childAspectRatio: 0.85,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: ingredients.length,
            itemBuilder: (context, index) {
              final ing = ingredients[index];
              final unlocked = _isUnlocked(ing);
              return _IngredientTile(
                ingredient: ing,
                unlocked: unlocked,
                onTap: () {
                  if (unlocked) {
                    widget.onSelect(ing.id);
                  } else {
                    _showHint(context, ing);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// 미해금 재료 클릭 시 힌트 표시
  void _showHint(BuildContext context, Ingredient ing) {
    final recipes = widget.engine.findRecipesForOutput(ing.id);
    String hintText;
    if (recipes.isNotEmpty) {
      final recipe = recipes.first;
      final inputNames = recipe.inputs.map((i) {
        final input = widget.engine.getIngredient(i.ingredientId);
        final known = input != null && _isUnlocked(input);
        return known ? input.name : '???';
      }).join(' + ');
      hintText = '$inputNames → ${ing.name}';
    } else {
      hintText = '아직 발견되지 않은 재료입니다.';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock, size: 20),
            const SizedBox(width: 8),
            Text(ing.name),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('힌트:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(hintText, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 12),
            const Text(
              '이 재료를 만드는 레시피를 발견하면 사용할 수 있습니다!',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

class _IngredientTile extends StatelessWidget {
  final Ingredient ingredient;
  final bool unlocked;
  final VoidCallback onTap;

  const _IngredientTile({
    required this.ingredient,
    required this.unlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: !unlocked
              ? Colors.grey.shade200
              : ingredient.isBase
                  ? const Color(0xFFE8F5E9)
                  : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: !unlocked ? Colors.grey.shade400 : Colors.grey.shade300,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (unlocked) _buildIcon()
                  else const Icon(Icons.lock, size: 28, color: Colors.grey),
                  const SizedBox(height: 4),
                  Text(
                    unlocked ? ingredient.name : '???',
                    style: TextStyle(
                      fontSize: 11,
                      color: unlocked ? Colors.black : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!unlocked)
              Positioned(
                right: 4,
                top: 4,
                child: Icon(Icons.lightbulb_outline, size: 14, color: Colors.amber.shade700),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final imagePath = IngredientImageMap.getImagePath(ingredient.id);
    if (imagePath != null) {
      return Image.asset(
        imagePath,
        width: 32,
        height: 32,
        errorBuilder: (_, __, ___) =>
            Text(ingredient.icon, style: const TextStyle(fontSize: 28)),
      );
    }
    return Text(ingredient.icon, style: const TextStyle(fontSize: 28));
  }
}
