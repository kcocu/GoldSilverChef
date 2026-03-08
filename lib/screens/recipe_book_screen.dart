import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
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
    _tabController = TabController(length: 2, vsync: this);
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
                  items: ['전체', '한식', '일식', '양식', '중식', '디저트', '퓨전', '스페셜', '기본 조합', '가공 재료']
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
            trailing: IconButton(
              icon: Icon(
                isFav ? Icons.star : Icons.star_border,
                color: isFav ? Colors.amber : Colors.grey,
              ),
              onPressed: () {
                state.recipeBook.toggleFavorite(recipe.id);
                setState(() {});
              },
            ),
          ),
        );
      },
    );
  }
}
