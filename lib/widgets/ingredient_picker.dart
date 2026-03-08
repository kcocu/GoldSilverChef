import 'dart:math';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/crafting_engine.dart';
import '../services/ingredient_image_map.dart';

class IngredientPicker extends StatefulWidget {
  final CraftingEngine engine;
  final Function(String) onSelect;
  final bool isRandom;

  const IngredientPicker({
    super.key,
    required this.engine,
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

  @override
  Widget build(BuildContext context) {
    List<Ingredient> ingredients;
    if (widget.isRandom) {
      ingredients = _randomized;
    } else {
      ingredients = widget.engine.allIngredients;
    }

    // 필터
    if (_tierFilter >= 0) {
      ingredients = ingredients.where((i) => i.tier == _tierFilter).toList();
    }
    if (_search.isNotEmpty) {
      ingredients = ingredients.where((i) => i.name.contains(_search)).toList();
    }

    // 기본 재료를 먼저 표시
    if (!widget.isRandom) {
      ingredients.sort((a, b) {
        if (a.isBase && !b.isBase) return -1;
        if (!a.isBase && b.isBase) return 1;
        return a.tier.compareTo(b.tier);
      });
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
                    else _tierFilter = 1; // tier 1+
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
              return _IngredientTile(
                ingredient: ing,
                onTap: () => widget.onSelect(ing.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _IngredientTile extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback onTap;

  const _IngredientTile({required this.ingredient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: ingredient.isBase ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIcon(),
            const SizedBox(height: 4),
            Text(
              ingredient.name,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
