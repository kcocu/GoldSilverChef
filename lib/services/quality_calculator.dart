import '../models/models.dart';

/// 품질 계산기
class QualityCalculator {
  /// 도구 수치로 품질 등급 계산
  static CookingResult calculate({
    required Recipe recipe,
    required int knifeValue,
    required int waterValue,
    required int fireValue,
    List<CookingResult> intermediateResults = const [],
  }) {
    // 각 도구 정확도 계산
    final knifeAcc = recipe.knife?.accuracy(knifeValue) ?? 1.0;
    final waterAcc = recipe.water?.accuracy(waterValue) ?? 1.0;
    final fireAcc = recipe.fire?.accuracy(fireValue) ?? 1.0;

    // 사용된 도구만 평균
    double totalAcc = 0;
    int toolCount = 0;
    if (recipe.usesKnife) { totalAcc += knifeAcc; toolCount++; }
    if (recipe.usesWater) { totalAcc += waterAcc; toolCount++; }
    if (recipe.usesFire) { totalAcc += fireAcc; toolCount++; }

    double overallAcc = toolCount > 0 ? totalAcc / toolCount : 1.0;

    // 중간 결과 품질 반영 (있으면 30% 반영)
    if (intermediateResults.isNotEmpty) {
      final avgIntermediate = intermediateResults
          .map((r) => r.overallAccuracy)
          .reduce((a, b) => a + b) / intermediateResults.length;
      overallAcc = overallAcc * 0.7 + avgIntermediate * 0.3;
    }

    final grade = _accuracyToGrade(overallAcc);

    return CookingResult(
      recipeId: recipe.id,
      recipeName: recipe.name,
      grade: grade,
      knifeValue: knifeValue,
      waterValue: waterValue,
      fireValue: fireValue,
      knifeAccuracy: knifeAcc,
      waterAccuracy: waterAcc,
      fireAccuracy: fireAcc,
      overallAccuracy: overallAcc,
      intermediateResults: intermediateResults,
    );
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
}
