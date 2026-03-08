import 'recipe.dart';

/// 조리 결과
class CookingResult {
  final String recipeId;
  final String recipeName;
  final QualityGrade grade;
  final int knifeValue;
  final int waterValue;
  final int fireValue;
  final double knifeAccuracy;
  final double waterAccuracy;
  final double fireAccuracy;
  final double overallAccuracy;
  final List<CookingResult> intermediateResults; // 중간 조리 결과들
  final DateTime cookedAt;

  CookingResult({
    required this.recipeId,
    required this.recipeName,
    required this.grade,
    this.knifeValue = 0,
    this.waterValue = 0,
    this.fireValue = 0,
    this.knifeAccuracy = 1.0,
    this.waterAccuracy = 1.0,
    this.fireAccuracy = 1.0,
    this.overallAccuracy = 1.0,
    this.intermediateResults = const [],
    DateTime? cookedAt,
  }) : cookedAt = cookedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'recipeId': recipeId,
    'recipeName': recipeName,
    'grade': grade.name,
    'knifeValue': knifeValue,
    'waterValue': waterValue,
    'fireValue': fireValue,
    'knifeAccuracy': knifeAccuracy,
    'waterAccuracy': waterAccuracy,
    'fireAccuracy': fireAccuracy,
    'overallAccuracy': overallAccuracy,
    'cookedAt': cookedAt.toIso8601String(),
  };
}

/// 심사 점수
class JudgeScore {
  final String judgeName;
  final double taste;       // 맛
  final double completion;  // 완성도
  final double creativity;  // 창의성
  final double visual;      // 비주얼
  final double gradeScore;  // 등급 점수
  final double totalScore;  // 총점
  final String comment;     // 코멘트

  const JudgeScore({
    required this.judgeName,
    required this.taste,
    this.completion = 0,
    this.creativity = 0,
    this.visual = 0,
    required this.gradeScore,
    required this.totalScore,
    required this.comment,
  });
}

/// 최종 심사 결과
class JudgingResult {
  final CookingResult cookingResult;
  final List<JudgeScore> scores;
  final double finalScore;

  const JudgingResult({
    required this.cookingResult,
    required this.scores,
    required this.finalScore,
  });
}
