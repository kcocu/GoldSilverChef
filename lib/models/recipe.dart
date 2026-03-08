/// 품질 등급
enum QualityGrade {
  F, D, C, B, A, S, SS, SSPlus;

  String get label {
    switch (this) {
      case QualityGrade.F: return 'F';
      case QualityGrade.D: return 'D';
      case QualityGrade.C: return 'C';
      case QualityGrade.B: return 'B';
      case QualityGrade.A: return 'A';
      case QualityGrade.S: return 'S';
      case QualityGrade.SS: return 'SS';
      case QualityGrade.SSPlus: return 'SS+';
    }
  }

  int get scoreMultiplier {
    switch (this) {
      case QualityGrade.F: return 1;
      case QualityGrade.D: return 2;
      case QualityGrade.C: return 3;
      case QualityGrade.B: return 5;
      case QualityGrade.A: return 8;
      case QualityGrade.S: return 13;
      case QualityGrade.SS: return 21;
      case QualityGrade.SSPlus: return 34;
    }
  }
}

/// 도구 수치 범위
class ToolRange {
  final int min;
  final int max;
  final int optimal; // 최적값

  const ToolRange({
    required this.min,
    required this.max,
    required this.optimal,
  });

  /// 입력값의 정확도 (0.0 ~ 1.0)
  double accuracy(int value) {
    if (value < min || value > max) return 0.0;
    final distance = (value - optimal).abs();
    final maxDistance = (max - min) / 2;
    if (maxDistance == 0) return 1.0;
    return (1.0 - (distance / maxDistance)).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {'min': min, 'max': max, 'optimal': optimal};

  factory ToolRange.fromJson(Map<String, dynamic> json) => ToolRange(
    min: json['min'],
    max: json['max'],
    optimal: json['optimal'],
  );
}

/// 레시피 입력 재료
class RecipeInput {
  final String ingredientId;
  final int? amount; // 그램 수 (null이면 개수 1)

  const RecipeInput({required this.ingredientId, this.amount});

  Map<String, dynamic> toJson() => {
    'ingredientId': ingredientId,
    if (amount != null) 'amount': amount,
  };

  factory RecipeInput.fromJson(Map<String, dynamic> json) => RecipeInput(
    ingredientId: json['ingredientId'],
    amount: json['amount'],
  );
}

/// 레시피
class Recipe {
  final String id;
  final String name;
  final List<RecipeInput> inputs;
  final String outputIngredientId; // 결과물 재료 ID
  final ToolRange? knife;  // 칼질 횟수 범위
  final ToolRange? water;  // 물 양 범위
  final ToolRange? fire;   // 불 수치 범위 (단계 x 시간)
  final int difficulty;    // 난이도 1~10
  final int tier;          // 요리 단계 (0=기본 조합, 1~N=연쇄)
  final String category;   // 요리 분류 (한식, 양식, 중식, 일식, 디저트 등)
  final String? description;

  const Recipe({
    required this.id,
    required this.name,
    required this.inputs,
    required this.outputIngredientId,
    this.knife,
    this.water,
    this.fire,
    this.difficulty = 1,
    this.tier = 0,
    this.category = '기타',
    this.description,
  });

  /// 도구 사용 여부
  bool get usesKnife => knife != null;
  bool get usesWater => water != null;
  bool get usesFire => fire != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'inputs': inputs.map((e) => e.toJson()).toList(),
    'outputIngredientId': outputIngredientId,
    if (knife != null) 'knife': knife!.toJson(),
    if (water != null) 'water': water!.toJson(),
    if (fire != null) 'fire': fire!.toJson(),
    'difficulty': difficulty,
    'tier': tier,
    'category': category,
    if (description != null) 'description': description,
  };

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
    id: json['id'],
    name: json['name'],
    inputs: (json['inputs'] as List).map((e) => RecipeInput.fromJson(e)).toList(),
    outputIngredientId: json['outputIngredientId'],
    knife: json['knife'] != null ? ToolRange.fromJson(json['knife']) : null,
    water: json['water'] != null ? ToolRange.fromJson(json['water']) : null,
    fire: json['fire'] != null ? ToolRange.fromJson(json['fire']) : null,
    difficulty: json['difficulty'] ?? 1,
    tier: json['tier'] ?? 0,
    category: json['category'] ?? '기타',
    description: json['description'],
  );
}
