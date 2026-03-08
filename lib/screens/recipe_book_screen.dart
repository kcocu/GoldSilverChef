import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_state.dart';

class RecipeBookScreen extends StatefulWidget {
  const RecipeBookScreen({super.key});

  @override
  State<RecipeBookScreen> createState() => _RecipeBookScreenState();
}

class _RecipeBookScreenState extends State<RecipeBookScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _filterCategory = '전체';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('레시피북 (${state.recipeBook.discovered.length}/${state.engine.allRecipes.length})'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: '발견한 레시피'),
            Tab(text: '즐겨찾기'),
            Tab(text: '커스텀'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 검색 + 필터
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: '레시피 검색...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _filterCategory,
                  items: ['전체', '한식', '일식', '양식', '중식', '디저트', '퓨전', '스페셜', '기본 조합', '가공 재료', '실험 요리', '절차적']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _filterCategory = v!),
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecipeList(state, favoritesOnly: false),
                _buildRecipeList(state, favoritesOnly: true),
                _buildCustomRecipeList(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeList(GameState state, {required bool favoritesOnly}) {
    var recipes = state.engine.allRecipes.where((r) {
      if (!state.recipeBook.isDiscovered(r.id)) return false;
      if (favoritesOnly && !state.recipeBook.isFavorite(r.id)) return false;
      if (_searchQuery.isNotEmpty && !r.name.contains(_searchQuery)) return false;
      if (_filterCategory != '전체' && r.category != _filterCategory) return false;
      return true;
    }).toList();

    if (recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📖', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(
              favoritesOnly ? '즐겨찾기한 레시피가 없습니다' : '발견한 레시피가 없습니다',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            if (!favoritesOnly)
              const Text('자유 경연에서 요리를 만들어보세요!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        final output = state.engine.getIngredient(recipe.outputIngredientId);
        final isFav = state.recipeBook.isFavorite(recipe.id);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Text(output?.icon ?? '🍳', style: const TextStyle(fontSize: 28)),
            title: Text(recipe.name),
            subtitle: Text(
              '${recipe.category} | 난이도 ${recipe.difficulty} | '
              '${recipe.inputs.map((i) => state.engine.getIngredient(i.ingredientId)?.name ?? '?').join(' + ')}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isFav ? Icons.star : Icons.star_border,
                    color: isFav ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () {
                    state.recipeBook.toggleFavorite(recipe.id);
                    setState(() {});
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => _confirmDelete(state, recipe.id, recipe.name),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomRecipeList(GameState state) {
    final customs = state.recipeBook.customRecipes;
    var entries = customs.entries.where((e) {
      final name = (e.value['name'] as String?) ?? '';
      if (_searchQuery.isNotEmpty && !name.contains(_searchQuery)) return false;
      if (_filterCategory != '전체') {
        final cat = (e.value['category'] as String?) ?? '';
        if (cat != _filterCategory) return false;
      }
      return true;
    }).toList();

    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🧪', style: TextStyle(fontSize: 60)),
            SizedBox(height: 16),
            Text('커스텀 레시피가 없습니다', style: TextStyle(fontSize: 16, color: Colors.grey)),
            Text('자유 경연에서 창의적인 요리를 만들어보세요!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final data = entry.value;
        final name = (data['name'] as String?) ?? '???';
        final grade = (data['grade'] as String?) ?? '?';
        final category = (data['category'] as String?) ?? '';
        final ingredientIds = (data['ingredients'] as List<dynamic>?)?.cast<String>() ?? [];
        final ingredientNames = ingredientIds.map((id) {
          final ing = state.engine.getIngredient(id);
          return ing?.name ?? id;
        }).join(' + ');
        final isFav = state.recipeBook.isFavorite(entry.key);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _customGradeColor(grade),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(grade, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            title: Text(name),
            subtitle: Text('$category | $ingredientNames', style: const TextStyle(fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(isFav ? Icons.star : Icons.star_border, color: isFav ? Colors.amber : Colors.grey),
                  onPressed: () {
                    state.recipeBook.toggleFavorite(entry.key);
                    setState(() {});
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => _confirmDelete(state, entry.key, name),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(GameState state, String recipeId, String recipeName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('레시피 삭제'),
        content: Text("'$recipeName' 레시피를 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () {
              state.recipeBook.removeDiscovered(recipeId);
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _customGradeColor(String grade) {
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
}
