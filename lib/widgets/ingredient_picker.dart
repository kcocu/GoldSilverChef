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

  Set<String> get _relatedLockedIds {
    if (_relatedLockedCache != null) return _relatedLockedCache!;
    final unlocked = _unlockedIds;
    final related = <String>{};
    for (final recipe in widget.engine.allRecipes) {
      if (unlocked.contains(recipe.outputIngredientId)) continue;
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

  /// 특정 재료가 입력으로 사용되는 레시피의 결과물 목록
  List<_HoverItem> _getHoverItems(String ingredientId) {
    final recipes = widget.engine.findRecipesContaining(ingredientId);
    final unlocked = _unlockedIds;
    final items = <_HoverItem>[];

    for (final recipe in recipes) {
      final outputIng = widget.engine.getIngredient(recipe.outputIngredientId);
      if (outputIng == null) continue;
      final isDiscovered = widget.recipeBook.isDiscovered(recipe.id);
      final allInputsKnown = recipe.inputs.every(
        (i) => unlocked.contains(i.ingredientId),
      );
      final inputNames = recipe.inputs.map((i) {
        final ing = widget.engine.getIngredient(i.ingredientId);
        return unlocked.contains(i.ingredientId) ? (ing?.name ?? '?') : '???';
      }).toList();

      items.add(_HoverItem(
        outputIngredient: outputIng,
        outputName: isDiscovered ? outputIng.name : '???',
        isDiscovered: isDiscovered,
        canMake: allInputsKnown,
        inputNames: inputNames,
        recipe: recipe,
      ));
    }

    // 만들 수 있는 것 먼저, 발견된 것 먼저
    items.sort((a, b) {
      if (a.canMake && !b.canMake) return -1;
      if (!a.canMake && b.canMake) return 1;
      if (a.isDiscovered && !b.isDiscovered) return -1;
      if (!a.isDiscovered && b.isDiscovered) return 1;
      return 0;
    });
    return items.take(30).toList();
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

    // 호버 상태면 해당 재료로 만들 수 있는 것들을 그리드로 표시
    final isHoverMode = _hoveredIngredientId != null;
    final hoverItems = isHoverMode ? _getHoverItems(_hoveredIngredientId!) : <_HoverItem>[];
    final hoveredIng = isHoverMode ? widget.engine.getIngredient(_hoveredIngredientId!) : null;

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
                  ButtonSegment(value: 2, label: Text('레시피', style: TextStyle(fontSize: 11))),
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

        // 해금 현황 or 호버 헤더
        if (isHoverMode && hoveredIng != null)
          _buildHoverHeader(hoveredIng)
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '해금 $totalUnlocked개 | 발견 가능 $totalRelated개',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),

        // 그리드: 레시피 탭, 호버 모드, 일반 재료 목록
        Expanded(
          child: _tierFilter == 2
              ? _buildCustomRecipeGrid()
              : isHoverMode
                  ? _buildHoverGrid(hoverItems)
                  : _buildNormalGrid(ingredients, unlocked),
        ),
      ],
    );
  }

  Widget _buildCustomRecipeGrid() {
    final customs = widget.recipeBook.customRecipes;
    if (customs.isEmpty) {
      return const Center(
        child: Text('저장된 커스텀 레시피가 없습니다.\n요리를 만들면 자동 저장됩니다!',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
      );
    }

    final entries = customs.entries.where((e) {
      if (_search.isEmpty) return true;
      final name = (e.value['name'] as String?) ?? '';
      return name.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    if (entries.isEmpty) {
      return const Center(
        child: Text('검색 결과가 없습니다.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final data = entry.value;
        final name = (data['name'] as String?) ?? '???';
        final grade = (data['grade'] as String?) ?? '?';
        final category = (data['category'] as String?) ?? '';
        final ingredientIds = (data['ingredients'] as List<dynamic>?)?.cast<String>() ?? [];
        final ingredientNames = ingredientIds.map((id) {
          final ing = widget.engine.getIngredient(id);
          return ing?.name ?? id;
        }).join(' + ');

        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            dense: true,
            leading: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _gradeColor(grade),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(grade, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: Text('$category | $ingredientNames', style: const TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.add_circle_outline, color: Color(0xFF2E7D32)),
            onTap: () {
              // 레시피의 재료들을 모두 추가
              for (final id in ingredientIds) {
                widget.onSelect(id);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$name 재료 ${ingredientIds.length}개 추가'), duration: const Duration(seconds: 1)),
              );
            },
          ),
        );
      },
    );
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'SS+': return const Color(0xFFFFD700);
      case 'SS': return Colors.red;
      case 'S': return Colors.orange;
      case 'A': return Colors.purple;
      case 'B': return Colors.blue;
      case 'C': return Colors.green;
      case 'D': return Colors.brown;
      default: return Colors.grey;
    }
  }

  Widget _buildHoverHeader(Ingredient ing) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Text(ing.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${ing.name} (으)로 만들 수 있는 요리',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          // 선택 버튼
          InkWell(
            onTap: () {
              setState(() => _hoveredIngredientId = null);
              widget.onSelect(ing.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('선택', style: TextStyle(fontSize: 12, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => setState(() => _hoveredIngredientId = null),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.close, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoverGrid(List<_HoverItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('관련 레시피가 없습니다.', style: TextStyle(color: Colors.grey)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 120,
        childAspectRatio: 0.7,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _HoverItemTile(
          item: item,
          onTap: () => _showRecipeDetail(context, item),
        );
      },
    );
  }

  Widget _buildNormalGrid(List<Ingredient> ingredients, Set<String> unlocked) {
    return GridView.builder(
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
              // 탭 → 호버 모드 (관련 레시피 그리드)
              setState(() => _hoveredIngredientId = ing.id);
            } else {
              _showHint(context, ing);
            }
          },
          onLongPress: isUnlocked ? () {
            // 롱프레스 → 바로 재료 선택
            widget.onSelect(ing.id);
          } : null,
        );
      },
    );
  }

  void _showRecipeDetail(BuildContext context, _HoverItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          item.isDiscovered ? item.outputName : '??? 요리',
          style: const TextStyle(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('재료:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(item.inputNames.join(' + '), style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            if (item.recipe.knife != null) ...[
              Text('🔪 칼질: ${item.recipe.knife!.min}~${item.recipe.knife!.max}회 (최적: ${item.recipe.knife!.optimal})',
                  style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 4),
            ],
            if (item.recipe.water != null) ...[
              Text('💧 물: ${item.recipe.water!.min}~${item.recipe.water!.max} (최적: ${item.recipe.water!.optimal})',
                  style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 4),
            ],
            if (item.recipe.fire != null) ...[
              Text('🔥 불: ${item.recipe.fire!.min}~${item.recipe.fire!.max} (최적: ${item.recipe.fire!.optimal})',
                  style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 4),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  item.canMake ? Icons.check_circle : Icons.warning,
                  size: 16,
                  color: item.canMake ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 6),
                Text(
                  item.canMake ? '모든 재료 보유!' : '일부 재료 미해금',
                  style: TextStyle(
                    fontSize: 13,
                    color: item.canMake ? Colors.green : Colors.orange,
                  ),
                ),
              ],
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

class _HoverItem {
  final Ingredient outputIngredient;
  final String outputName;
  final bool isDiscovered;
  final bool canMake;
  final List<String> inputNames;
  final Recipe recipe;

  const _HoverItem({
    required this.outputIngredient,
    required this.outputName,
    required this.isDiscovered,
    required this.canMake,
    required this.inputNames,
    required this.recipe,
  });
}

class _HoverItemTile extends StatelessWidget {
  final _HoverItem item;
  final VoidCallback onTap;

  const _HoverItemTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: item.isDiscovered
              ? Colors.green.shade50
              : item.canMake
                  ? Colors.orange.shade50
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: item.isDiscovered
                ? Colors.green.shade300
                : item.canMake
                    ? Colors.orange.shade300
                    : Colors.grey.shade300,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 상태 아이콘
              Icon(
                item.isDiscovered
                    ? Icons.check_circle
                    : item.canMake
                        ? Icons.help_outline
                        : Icons.lock_outline,
                size: 22,
                color: item.isDiscovered
                    ? Colors.green
                    : item.canMake
                        ? Colors.orange
                        : Colors.grey,
              ),
              const SizedBox(height: 4),
              // 이름
              Text(
                item.outputName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: item.isDiscovered ? Colors.black87 : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // 재료 요약
              Text(
                item.inputNames.join('+'),
                style: const TextStyle(fontSize: 9, color: Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IngredientTile extends StatelessWidget {
  final Ingredient ingredient;
  final bool unlocked;
  final bool isHovered;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _IngredientTile({
    required this.ingredient,
    required this.unlocked,
    this.isHovered = false,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
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
