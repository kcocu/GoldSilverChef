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

  // 캐시
  Set<String>? _unlockedCache;
  Set<String>? _discoverableCache;
  List<Ingredient>? _filteredCache;
  int? _lastTierFilter;
  String? _lastSearch;

  @override
  void initState() {
    super.initState();
    if (widget.isRandom) {
      _randomized = List<Ingredient>.from(widget.engine.allIngredients)..shuffle(_random);
    }
  }

  /// 해금된 재료 ID 세트 (캐시)
  Set<String> get _unlockedIds {
    if (_unlockedCache != null) return _unlockedCache!;
    final ids = <String>{};
    for (final ing in widget.engine.allIngredients) {
      if (ing.isBase) {
        ids.add(ing.id);
      } else {
        final recipes = widget.engine.findRecipesForOutput(ing.id);
        if (recipes.any((r) => widget.recipeBook.isDiscovered(r.id))) {
          ids.add(ing.id);
        }
      }
    }
    _unlockedCache = ids;
    return ids;
  }

  /// 다음에 발견 가능한 재료 ID 세트 (캐시)
  Set<String> get _discoverableIds {
    if (_discoverableCache != null) return _discoverableCache!;
    _discoverableCache = widget.engine.findDiscoverableOutputs(_unlockedIds);
    return _discoverableCache!;
  }

  bool _isUnlocked(String id) => _unlockedIds.contains(id);

  void _invalidateCache() {
    _unlockedCache = null;
    _discoverableCache = null;
    _filteredCache = null;
  }

  @override
  void didUpdateWidget(IngredientPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // recipeBook 변경 시 캐시 무효화
    _invalidateCache();
  }

  List<Ingredient> _getFilteredIngredients() {
    // 캐시 히트 체크
    if (_filteredCache != null &&
        _lastTierFilter == _tierFilter &&
        _lastSearch == _search) {
      return _filteredCache!;
    }

    final unlocked = _unlockedIds;
    final discoverable = _discoverableIds;

    List<Ingredient> ingredients;

    if (widget.isRandom) {
      // 랜덤 모드: 해금된 것만
      ingredients = _randomized.where((i) => unlocked.contains(i.id)).toList();
    } else if (_tierFilter == 0) {
      // 기본 재료만
      ingredients = widget.engine.baseIngredients;
    } else if (_tierFilter == 1) {
      // 파생 탭: 해금된 파생 + 발견 가능한 파생(???)
      final result = <Ingredient>[];
      for (final ing in widget.engine.allIngredients) {
        if (ing.isBase) continue;
        if (unlocked.contains(ing.id) || discoverable.contains(ing.id)) {
          result.add(ing);
        }
      }
      // 해금된 것 먼저
      result.sort((a, b) {
        final aUn = unlocked.contains(a.id);
        final bUn = unlocked.contains(b.id);
        if (aUn && !bUn) return -1;
        if (!aUn && bUn) return 1;
        return a.tier.compareTo(b.tier);
      });
      ingredients = result;
    } else {
      // 전체: 기본 + 해금된 파생 + 발견 가능한 파생
      final result = <Ingredient>[];
      for (final ing in widget.engine.allIngredients) {
        if (ing.isBase || unlocked.contains(ing.id) || discoverable.contains(ing.id)) {
          result.add(ing);
        }
      }
      // 기본 먼저, 해금 먼저
      result.sort((a, b) {
        if (a.isBase && !b.isBase) return -1;
        if (!a.isBase && b.isBase) return 1;
        final aUn = unlocked.contains(a.id);
        final bUn = unlocked.contains(b.id);
        if (aUn && !bUn) return -1;
        if (!aUn && bUn) return 1;
        return a.tier.compareTo(b.tier);
      });
      ingredients = result;
    }

    // 검색 필터
    if (_search.isNotEmpty) {
      final query = _search.toLowerCase();
      ingredients = ingredients.where((i) {
        // 해금된 것만 이름 검색 가능
        if (!unlocked.contains(i.id)) return false;
        return i.name.toLowerCase().contains(query);
      }).toList();
    }

    _filteredCache = ingredients;
    _lastTierFilter = _tierFilter;
    _lastSearch = _search;
    return ingredients;
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = _getFilteredIngredients();
    final unlocked = _unlockedIds;
    final totalUnlocked = unlocked.length;
    final totalDiscoverable = _discoverableIds.length;

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
                  onChanged: (v) => setState(() {
                    _search = v;
                    _filteredCache = null;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: -1, label: Text('전체', style: TextStyle(fontSize: 11))),
                  ButtonSegment(value: 0, label: Text('기본', style: TextStyle(fontSize: 11))),
                  ButtonSegment(value: 1, label: Text('파생', style: TextStyle(fontSize: 11))),
                ],
                selected: {_tierFilter},
                onSelectionChanged: (v) {
                  setState(() {
                    _tierFilter = v.first;
                    _filteredCache = null;
                  });
                },
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),

        // 해금 현황
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '해금 $totalUnlocked개 | 발견 가능 $totalDiscoverable개',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
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
              final isUnlocked = unlocked.contains(ing.id);
              return _IngredientTile(
                ingredient: ing,
                unlocked: isUnlocked,
                onTap: () {
                  if (isUnlocked) {
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
        final known = _unlockedIds.contains(i.ingredientId);
        if (known) {
          final input = widget.engine.getIngredient(i.ingredientId);
          return input?.name ?? '???';
        }
        return '???';
      }).join(' + ');
      hintText = '$inputNames → ???';
    } else {
      hintText = '아직 발견되지 않은 재료입니다.';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, size: 20),
            SizedBox(width: 8),
            Text('미발견 재료'),
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
