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
  Set<String>? _relatedLockedCache;
  List<Ingredient>? _filteredCache;
  int? _lastTierFilter;
  String? _lastSearch;

  // 호버(클릭) 상태
  String? _hoveredIngredientId;

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

  /// 해금된 재료가 입력으로 사용되는 레시피의 결과물 중 미해금인 것들
  /// (해금된 재료 하나라도 포함된 레시피의 출력)
  Set<String> get _relatedLockedIds {
    if (_relatedLockedCache != null) return _relatedLockedCache!;
    final unlocked = _unlockedIds;
    final related = <String>{};
    for (final recipe in widget.engine.allRecipes) {
      if (unlocked.contains(recipe.outputIngredientId)) continue;
      // 입력 중 하나라도 해금된 재료가 있으면 표시
      final hasUnlockedInput = recipe.inputs.any(
        (input) => unlocked.contains(input.ingredientId),
      );
      if (hasUnlockedInput) {
        related.add(recipe.outputIngredientId);
      }
    }
    _relatedLockedCache = related;
    return related;
  }

  bool _isUnlocked(String id) => _unlockedIds.contains(id);

  void _invalidateCache() {
    _unlockedCache = null;
    _relatedLockedCache = null;
    _filteredCache = null;
  }

  @override
  void didUpdateWidget(IngredientPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _invalidateCache();
  }

  /// 특정 재료로 만들 수 있는 요리 목록 (해금/미해금 모두)
  List<_RelatedRecipeInfo> _getRelatedRecipes(String ingredientId) {
    final recipes = widget.engine.findRecipesContaining(ingredientId);
    final unlocked = _unlockedIds;
    final result = <_RelatedRecipeInfo>[];
    for (final recipe in recipes) {
      final outputIng = widget.engine.getIngredient(recipe.outputIngredientId);
      final isDiscovered = widget.recipeBook.isDiscovered(recipe.id);
      final allInputsKnown = recipe.inputs.every(
        (i) => unlocked.contains(i.ingredientId),
      );
      result.add(_RelatedRecipeInfo(
        recipe: recipe,
        outputName: isDiscovered ? (outputIng?.name ?? recipe.name) : '???',
        isDiscovered: isDiscovered,
        canMake: allInputsKnown,
        inputNames: recipe.inputs.map((i) {
          final ing = widget.engine.getIngredient(i.ingredientId);
          final known = unlocked.contains(i.ingredientId);
          return known ? (ing?.name ?? '?') : '???';
        }).toList(),
      ));
    }
    // 발견된 것 먼저, 만들 수 있는 것 먼저
    result.sort((a, b) {
      if (a.isDiscovered && !b.isDiscovered) return -1;
      if (!a.isDiscovered && b.isDiscovered) return 1;
      if (a.canMake && !b.canMake) return -1;
      if (!a.canMake && b.canMake) return 1;
      return 0;
    });
    return result.take(20).toList(); // 최대 20개
  }

  List<Ingredient> _getFilteredIngredients() {
    if (_filteredCache != null &&
        _lastTierFilter == _tierFilter &&
        _lastSearch == _search) {
      return _filteredCache!;
    }

    final unlocked = _unlockedIds;
    final relatedLocked = _relatedLockedIds;

    List<Ingredient> ingredients;

    if (widget.isRandom) {
      ingredients = _randomized.where((i) => unlocked.contains(i.id)).toList();
    } else if (_tierFilter == 0) {
      ingredients = widget.engine.baseIngredients;
    } else if (_tierFilter == 1) {
      // 파생: 해금된 파생 + 관련 미해금
      final result = <Ingredient>[];
      for (final ing in widget.engine.allIngredients) {
        if (ing.isBase) continue;
        if (unlocked.contains(ing.id) || relatedLocked.contains(ing.id)) {
          result.add(ing);
        }
      }
      result.sort((a, b) {
        final aUn = unlocked.contains(a.id);
        final bUn = unlocked.contains(b.id);
        if (aUn && !bUn) return -1;
        if (!aUn && bUn) return 1;
        return a.tier.compareTo(b.tier);
      });
      ingredients = result;
    } else {
      // 전체: 기본 + 해금된 파생 + 관련 미해금
      final result = <Ingredient>[];
      for (final ing in widget.engine.allIngredients) {
        if (ing.isBase || unlocked.contains(ing.id) || relatedLocked.contains(ing.id)) {
          result.add(ing);
        }
      }
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

    if (_search.isNotEmpty) {
      final query = _search.toLowerCase();
      ingredients = ingredients.where((i) {
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
    final totalRelated = _relatedLockedIds.length;

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
                    _hoveredIngredientId = null;
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
            '해금 $totalUnlocked개 | 발견 가능 $totalRelated개',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),

        // 호버된 재료의 관련 레시피 패널
        if (_hoveredIngredientId != null) _buildRelatedPanel(),

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
              final isHovered = _hoveredIngredientId == ing.id;
              return _IngredientTile(
                ingredient: ing,
                unlocked: isUnlocked,
                isHovered: isHovered,
                onTap: () {
                  if (isUnlocked) {
                    if (_hoveredIngredientId == ing.id) {
                      // 이미 호버 중이면 → 재료 선택
                      setState(() => _hoveredIngredientId = null);
                      widget.onSelect(ing.id);
                    } else {
                      // 첫 탭 → 호버(관련 레시피 표시)
                      setState(() => _hoveredIngredientId = ing.id);
                    }
                  } else {
                    // 미해금: 힌트
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

  /// 호버된 재료의 관련 레시피 패널
  Widget _buildRelatedPanel() {
    final ing = widget.engine.getIngredient(_hoveredIngredientId!);
    if (ing == null) return const SizedBox.shrink();

    final related = _getRelatedRecipes(ing.id);

    return Container(
      constraints: const BoxConstraints(maxHeight: 160),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                Text(ing.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  '${ing.name} (으)로 만들 수 있는 요리',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                // 선택 버튼
                GestureDetector(
                  onTap: () {
                    setState(() => _hoveredIngredientId = null);
                    widget.onSelect(ing.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('선택', style: TextStyle(fontSize: 11, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => setState(() => _hoveredIngredientId = null),
                  child: const Icon(Icons.close, size: 16),
                ),
              ],
            ),
          ),
          // 레시피 목록
          Flexible(
            child: related.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('아직 관련 레시피가 없습니다.', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    itemCount: related.length,
                    itemBuilder: (context, index) {
                      final info = related[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              info.isDiscovered ? Icons.check_circle : Icons.help_outline,
                              size: 14,
                              color: info.isDiscovered
                                  ? Colors.green
                                  : info.canMake ? Colors.orange : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${info.inputNames.join(" + ")} → ${info.outputName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: info.isDiscovered ? Colors.black87 : Colors.grey.shade700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
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

class _RelatedRecipeInfo {
  final Recipe recipe;
  final String outputName;
  final bool isDiscovered;
  final bool canMake;
  final List<String> inputNames;

  const _RelatedRecipeInfo({
    required this.recipe,
    required this.outputName,
    required this.isDiscovered,
    required this.canMake,
    required this.inputNames,
  });
}

class _IngredientTile extends StatelessWidget {
  final Ingredient ingredient;
  final bool unlocked;
  final bool isHovered;
  final VoidCallback onTap;

  const _IngredientTile({
    required this.ingredient,
    required this.unlocked,
    this.isHovered = false,
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
              : isHovered
                  ? Colors.blue.shade50
                  : ingredient.isBase
                      ? const Color(0xFFE8F5E9)
                      : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isHovered
                ? Colors.blue.shade400
                : !unlocked
                    ? Colors.grey.shade400
                    : Colors.grey.shade300,
            width: isHovered ? 2 : 1,
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
