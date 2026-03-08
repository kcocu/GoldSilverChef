import '../models/models.dart';

/// 심사 엔진
class JudgingEngine {
  /// 심사 실행
  static JudgingResult judge(CookingResult result, Recipe recipe) {
    final scores = Judge.all.map((judge) => _scoreForJudge(judge, result, recipe)).toList();
    final finalScore = scores.map((s) => s.totalScore).reduce((a, b) => a + b) / scores.length;

    return JudgingResult(
      cookingResult: result,
      scores: scores,
      finalScore: finalScore,
    );
  }

  static JudgeScore _scoreForJudge(Judge judge, CookingResult result, Recipe recipe) {
    // 맛: 레시피 난이도 x 품질
    final taste = _calcTaste(result, recipe);
    // 완성도: 도구 수치 정확도
    final completion = _calcCompletion(result);
    // 창의성: 조합 단계 수 + 난이도
    final creativity = _calcCreativity(result, recipe);
    // 비주얼: 품질 등급 + 재료 다양성
    final visual = _calcVisual(result, recipe);
    // 등급 점수
    final gradeScore = _calcGradeScore(result);

    final total = taste * judge.tasteWeight +
        completion * judge.completionWeight +
        creativity * judge.creativityWeight +
        visual * judge.visualWeight +
        gradeScore * judge.gradeWeight;

    final comment = _generateComment(judge, total, result.grade);

    return JudgeScore(
      judgeName: judge.name,
      taste: taste,
      completion: completion,
      creativity: creativity,
      visual: visual,
      gradeScore: gradeScore,
      totalScore: total,
      comment: comment,
    );
  }

  static double _calcTaste(CookingResult result, Recipe recipe) {
    return result.overallAccuracy * recipe.difficulty * 10;
  }

  static double _calcCompletion(CookingResult result) {
    return result.overallAccuracy * 100;
  }

  static double _calcCreativity(CookingResult result, Recipe recipe) {
    final tierBonus = recipe.tier * 15.0;
    final difficultyBonus = recipe.difficulty * 5.0;
    final intermediateBonus = result.intermediateResults.length * 10.0;
    return (tierBonus + difficultyBonus + intermediateBonus).clamp(0, 100);
  }

  static double _calcVisual(CookingResult result, Recipe recipe) {
    final gradeBonus = result.grade.scoreMultiplier * 3.0;
    final accuracyBonus = result.overallAccuracy * 50;
    return (gradeBonus + accuracyBonus).clamp(0, 100);
  }

  static double _calcGradeScore(CookingResult result) {
    return result.grade.scoreMultiplier * 3.0;
  }

  static String _generateComment(Judge judge, double score, QualityGrade grade) {
    if (judge.id == 'dolphin') {
      return _dolphinComment(score, grade);
    } else {
      return _blackSugarComment(score, grade);
    }
  }

  static String _dolphinComment(double score, QualityGrade grade) {
    if (score >= 80) return '완벽한 완성도! 흠잡을 데가 없군요.';
    if (score >= 60) return '좋은 요리입니다. 조금 더 정교하면 완벽하겠어요.';
    if (score >= 40) return '기본기는 있지만 완성도가 아쉽습니다.';
    if (score >= 20) return '좀 더 연습이 필요해 보입니다.';
    return '기초부터 다시 시작하세요...';
  }

  static String _blackSugarComment(double score, QualityGrade grade) {
    if (score >= 80) return '와! 창의적이고 아름다운 요리! 감동이에요!';
    if (score >= 60) return '흥미로운 시도예요! 비주얼이 좀 더 좋으면 완벽!';
    if (score >= 40) return '아이디어는 좋은데 표현이 아쉬워요.';
    if (score >= 20) return '좀 더 과감한 시도가 필요해요.';
    return '음... 이건 요리인가요?';
  }
}
