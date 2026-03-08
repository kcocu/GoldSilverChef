import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'crafting_engine.dart';
import 'quality_calculator.dart';
import 'judging_engine.dart';
import 'recipe_book.dart';
import 'leaderboard.dart';
import 'procedural_recipe.dart';

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
  bool _isProcedural = false; // 마지막 결과가 절차적 생성인지

  // 연쇄 조합용 중간 결과
  final List<CookingResult> _intermediateResults = [];

  List<String> get selectedIngredients => List.unmodifiable(_selectedIngredients);
  int get knifeCount => _knifeCount;
  double get waterAmount => _waterAmount;
  int get fireLevel => _fireLevel;
  double get cookingTime => _cookingTime;
  CookingResult? get lastResult => _lastResult;
  JudgingResult? get lastJudging => _lastJudging;
  bool get isProcedural => _isProcedural;
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

  /// 현재 재료로 정적 레시피 매칭
  Recipe? findMatchingRecipe() {
    if (_selectedIngredients.isEmpty) return null;
    final recipes = engine.findRecipes(_selectedIngredients);
    return recipes.isNotEmpty ? recipes.first : null;
  }

  /// 조리 완료 → 정적 레시피 우선, 없으면 절차적 생성
  CookingResult cook() {
    final recipe = findMatchingRecipe();
    final fireValue = (_fireLevel * _cookingTime).round();

    if (recipe != null) {
      // 정적 레시피 매칭 성공
      _isProcedural = false;
      final result = QualityCalculator.calculate(
        recipe: recipe,
        knifeValue: _knifeCount,
        waterValue: _waterAmount.round(),
        fireValue: fireValue,
        intermediateResults: _intermediateResults,
      );
      _lastResult = result;
      recipeBook.discover(recipe.id);
      notifyListeners();
      return result;
    }

    // 절차적 생성
    _isProcedural = true;
    final ingredients = _selectedIngredients
        .map((id) => engine.getIngredient(id))
        .whereType<Ingredient>()
        .toList();

    if (ingredients.isEmpty) {
      final failedResult = CookingResult(
        recipeId: 'failed',
        recipeName: '실패한 요리',
        grade: QualityGrade.F,
        overallAccuracy: 0,
      );
      _lastResult = failedResult;
      notifyListeners();
      return failedResult;
    }

    final proc = ProceduralRecipeEngine.generate(
      ingredients: ingredients,
      knifeValue: _knifeCount,
      waterValue: _waterAmount.round(),
      fireValue: fireValue,
    );

    // 도구 정확도 계산
    final knifeRange = proc.toolRanges['knife'];
    final waterRange = proc.toolRanges['water'];
    final fireRange = proc.toolRanges['fire'];

    final knifeAcc = knifeRange?.accuracy(_knifeCount) ?? 1.0;
    final waterAcc = waterRange?.accuracy(_waterAmount.round()) ?? 1.0;
    final fireAcc = fireRange?.accuracy(fireValue) ?? 1.0;

    // 도구 평균 정확도
    double toolAcc = 0;
    int toolCount = 0;
    if (_knifeCount > 0 || knifeRange != null) { toolAcc += knifeAcc; toolCount++; }
    if (_waterAmount > 0 || waterRange != null) { toolAcc += waterAcc; toolCount++; }
    if (fireValue > 0 || fireRange != null) { toolAcc += fireAcc; toolCount++; }
    final avgToolAcc = toolCount > 0 ? toolAcc / toolCount : 0.5;

    // 궁합 보정 + 랜덤 보정
    final sanityMult = ProceduralRecipeEngine.sanityMultiplier(proc.sanityScore);
    final hash = proc.name.hashCode;
    final randomMult = ProceduralRecipeEngine.randomBonus(hash);

    // 최종 정확도
    double overallAcc = (avgToolAcc * sanityMult * randomMult).clamp(0.0, 1.0);

    // 중간 결과 반영
    if (_intermediateResults.isNotEmpty) {
      final avgIntermediate = _intermediateResults
          .map((r) => r.overallAccuracy)
          .reduce((a, b) => a + b) / _intermediateResults.length;
      overallAcc = overallAcc * 0.7 + avgIntermediate * 0.3;
    }

    final grade = _accuracyToGrade(overallAcc);

    final procId = 'proc_${hash.abs()}';
    final result = CookingResult(
      recipeId: procId,
      recipeName: proc.name,
      grade: grade,
      knifeValue: _knifeCount,
      waterValue: _waterAmount.round(),
      fireValue: fireValue,
      knifeAccuracy: knifeAcc,
      waterAccuracy: waterAcc,
      fireAccuracy: fireAcc,
      overallAccuracy: overallAcc,
      intermediateResults: _intermediateResults,
      comment: proc.comment,
    );

    // 커스텀 레시피 자동 저장
    recipeBook.saveCustomRecipe(
      id: procId,
      name: proc.name,
      ingredientIds: _selectedIngredients.toList(),
      grade: grade.label,
      category: proc.category,
    );

    _lastResult = result;
    notifyListeners();
    return result;
  }

  static QualityGrade _accuracyToGrade(double accuracy) {
    if (accuracy >= 0.98) return QualityGrade.SSPlus;
    if (accuracy >= 0.93) return QualityGrade.SS;
    if (accuracy >= 0.85) return QualityGrade.S;
    if (accuracy >= 0.75) return QualityGrade.A;
    if (accuracy >= 0.60) return QualityGrade.B;
    if (accuracy >= 0.45) return QualityGrade.C;
    if (accuracy >= 0.30) return QualityGrade.D;
    return QualityGrade.F;
  }

  /// 결과물을 재료로 전환 (연쇄 조합)
  void useResultAsIngredient() {
    if (_lastResult == null) return;

    _intermediateResults.add(_lastResult!);
    _selectedIngredients.clear();

    if (!_isProcedural) {
      // 정적 레시피: outputIngredientId 사용
      final recipe = engine.allRecipes.firstWhere(
        (r) => r.id == _lastResult!.recipeId,
        orElse: () => engine.allRecipes.first,
      );
      _selectedIngredients.add(recipe.outputIngredientId);
    } else {
      // 절차적: 원래 재료 중 첫 번째 유지 (결과물을 재료로 재사용은 정적만)
      // 절차적 결과는 "가공된" 상태로 중간 결과에만 반영
    }

    _resetTools();
    _lastResult = null;
    _isProcedural = false;
    notifyListeners();
  }

  /// 심사 요청 → 심사 후 조리대 자동 초기화
  JudgingResult? requestJudging() {
    if (_lastResult == null) return null;

    if (_isProcedural) {
      final tempRecipe = Recipe(
        id: _lastResult!.recipeId,
        name: _lastResult!.recipeName,
        inputs: const [],
        outputIngredientId: '',
        category: '절차적',
      );
      _lastJudging = JudgingEngine.judge(_lastResult!, tempRecipe);
    } else {
      final recipe = engine.allRecipes.firstWhere(
        (r) => r.id == _lastResult!.recipeId,
        orElse: () => engine.allRecipes.first,
      );
      _lastJudging = JudgingEngine.judge(_lastResult!, recipe);
    }

    // 리더보드에 자동 등록
    leaderboard.addEntry(
      dishName: _lastResult!.recipeName,
      grade: _lastResult!.grade.label,
      score: _lastJudging!.finalScore,
    );

    notifyListeners();
    return _lastJudging;
  }

  /// 심사 후 조리대 초기화 (새 요리 시작)
  void resetAfterJudging() {
    _selectedIngredients.clear();
    _intermediateResults.clear();
    _lastResult = null;
    _isProcedural = false;
    _resetTools();
    // _lastJudging은 유지 (심사 결과 화면에서 사용)
    notifyListeners();
  }

  /// 조리대 초기화
  void resetCooking() {
    _selectedIngredients.clear();
    _intermediateResults.clear();
    _lastResult = null;
    _lastJudging = null;
    _isProcedural = false;
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
