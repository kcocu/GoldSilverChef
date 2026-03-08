import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'crafting_engine.dart';
import 'quality_calculator.dart';
import 'judging_engine.dart';
import 'recipe_book.dart';
import 'leaderboard.dart';

/// 게임 전체 상태 관리
class GameState extends ChangeNotifier {
  final CraftingEngine engine = CraftingEngine();
  final Leaderboard leaderboard = Leaderboard();
  final RecipeBook recipeBook = RecipeBook();

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  // 조리대 상태
  final List<String> _selectedIngredients = [];
  int _knifeCount = 0;
  double _waterAmount = 0;
  int _fireLevel = 0; // 0=꺼짐, 1,2,3
  double _cookingTime = 0;
  CookingResult? _lastResult;
  JudgingResult? _lastJudging;

  // 연쇄 조합용 중간 결과
  final List<CookingResult> _intermediateResults = [];

  List<String> get selectedIngredients => List.unmodifiable(_selectedIngredients);
  int get knifeCount => _knifeCount;
  double get waterAmount => _waterAmount;
  int get fireLevel => _fireLevel;
  double get cookingTime => _cookingTime;
  CookingResult? get lastResult => _lastResult;
  JudgingResult? get lastJudging => _lastJudging;
  List<CookingResult> get intermediateResults => List.unmodifiable(_intermediateResults);

  void markLoaded() {
    _isLoaded = true;
    notifyListeners();
  }

  // ─── 재료 선택 ───

  void addIngredient(String ingredientId) {
    _selectedIngredients.add(ingredientId);
    notifyListeners();
  }

  void removeIngredient(int index) {
    if (index < _selectedIngredients.length) {
      _selectedIngredients.removeAt(index);
      notifyListeners();
    }
  }

  void clearIngredients() {
    _selectedIngredients.clear();
    notifyListeners();
  }

  // ─── 도구 조작 ───

  void chop() {
    _knifeCount++;
    notifyListeners();
  }

  void setWaterAmount(double amount) {
    _waterAmount = amount.clamp(0, 100);
    notifyListeners();
  }

  void setFireLevel(int level) {
    _fireLevel = level.clamp(0, 3);
    notifyListeners();
  }

  void addCookingTime(double seconds) {
    _cookingTime += seconds;
    notifyListeners();
  }

  // ─── 조리 실행 ───

  /// 현재 재료로 조합 시도
  Recipe? findMatchingRecipe() {
    if (_selectedIngredients.isEmpty) return null;
    final recipes = engine.findRecipes(_selectedIngredients);
    return recipes.isNotEmpty ? recipes.first : null;
  }

  /// 조리 완료 → 결과 계산
  CookingResult? cook() {
    final recipe = findMatchingRecipe();
    if (recipe == null) return null;

    final fireValue = (_fireLevel * _cookingTime).round();
    final result = QualityCalculator.calculate(
      recipe: recipe,
      knifeValue: _knifeCount,
      waterValue: _waterAmount.round(),
      fireValue: fireValue,
      intermediateResults: _intermediateResults,
    );

    _lastResult = result;

    // 레시피북에 등록
    final isNew = recipeBook.discover(recipe.id);

    notifyListeners();
    return result;
  }

  /// 결과물을 재료로 전환 (연쇄 조합)
  void useResultAsIngredient() {
    if (_lastResult == null) return;
    final recipe = engine.allRecipes.firstWhere((r) => r.id == _lastResult!.recipeId);
    _intermediateResults.add(_lastResult!);
    _selectedIngredients.clear();
    _selectedIngredients.add(recipe.outputIngredientId);
    _resetTools();
    _lastResult = null;
    notifyListeners();
  }

  /// 심사 요청
  JudgingResult? requestJudging() {
    if (_lastResult == null) return null;
    final recipe = engine.allRecipes.firstWhere((r) => r.id == _lastResult!.recipeId);
    _lastJudging = JudgingEngine.judge(_lastResult!, recipe);

    // 리더보드에 자동 등록
    leaderboard.addEntry(
      dishName: _lastResult!.recipeName,
      grade: _lastResult!.grade.label,
      score: _lastJudging!.finalScore,
    );

    notifyListeners();
    return _lastJudging;
  }

  /// 조리대 초기화
  void resetCooking() {
    _selectedIngredients.clear();
    _intermediateResults.clear();
    _lastResult = null;
    _lastJudging = null;
    _resetTools();
    notifyListeners();
  }

  void _resetTools() {
    _knifeCount = 0;
    _waterAmount = 0;
    _fireLevel = 0;
    _cookingTime = 0;
  }
}
