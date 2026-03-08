import 'dart:math';
import '../models/models.dart';

/// 절차적 레시피 생성 엔진
/// 어떤 재료 조합이든 레시피를 생성하며, 조합의 합리성에 따라 점수 보정
class ProceduralRecipeEngine {
  static final _random = Random();

  // ─── 카테고리 궁합 ───

  /// 재료 타입 간 궁합 점수 (0.0 ~ 1.0)
  /// 높을수록 자연스러운 조합
  static const _compatibilityMatrix = <String, Map<String, double>>{
    'meat': {'vegetable': 0.9, 'seasoning': 0.9, 'oil': 0.9, 'salt': 0.8, 'mushroom': 0.8, 'egg': 0.7, 'grain': 0.7, 'dairy': 0.6, 'liquid': 0.7, 'sugar': 0.2, 'fruit': 0.3, 'seafood': 0.3},
    'seafood': {'vegetable': 0.8, 'seasoning': 0.9, 'salt': 0.9, 'liquid': 0.8, 'oil': 0.7, 'mushroom': 0.7, 'grain': 0.6, 'egg': 0.6, 'dairy': 0.3, 'sugar': 0.2, 'fruit': 0.3, 'meat': 0.3},
    'vegetable': {'meat': 0.9, 'seasoning': 0.9, 'oil': 0.8, 'salt': 0.8, 'mushroom': 0.8, 'grain': 0.7, 'seafood': 0.8, 'egg': 0.7, 'dairy': 0.6, 'liquid': 0.7, 'sugar': 0.3, 'fruit': 0.5},
    'grain': {'dairy': 0.9, 'egg': 0.8, 'sugar': 0.8, 'salt': 0.7, 'oil': 0.7, 'liquid': 0.7, 'meat': 0.7, 'vegetable': 0.7, 'fruit': 0.6, 'seasoning': 0.6, 'mushroom': 0.5, 'seafood': 0.6},
    'dairy': {'grain': 0.9, 'sugar': 0.9, 'egg': 0.8, 'fruit': 0.8, 'salt': 0.5, 'oil': 0.5, 'vegetable': 0.6, 'mushroom': 0.5, 'meat': 0.6, 'seasoning': 0.3, 'seafood': 0.3, 'liquid': 0.6},
    'egg': {'grain': 0.8, 'dairy': 0.8, 'vegetable': 0.7, 'meat': 0.7, 'oil': 0.8, 'salt': 0.7, 'sugar': 0.7, 'seasoning': 0.6, 'mushroom': 0.6, 'seafood': 0.6, 'fruit': 0.5, 'liquid': 0.6},
    'fruit': {'sugar': 0.9, 'dairy': 0.8, 'grain': 0.6, 'egg': 0.5, 'liquid': 0.5, 'oil': 0.3, 'meat': 0.3, 'seafood': 0.3, 'vegetable': 0.5, 'salt': 0.2, 'seasoning': 0.2, 'mushroom': 0.2},
    'mushroom': {'meat': 0.8, 'vegetable': 0.8, 'seasoning': 0.7, 'oil': 0.7, 'salt': 0.7, 'grain': 0.5, 'liquid': 0.6, 'egg': 0.6, 'seafood': 0.7, 'dairy': 0.5, 'sugar': 0.1, 'fruit': 0.2},
    'oil': {'meat': 0.9, 'vegetable': 0.8, 'egg': 0.8, 'seafood': 0.7, 'mushroom': 0.7, 'grain': 0.7, 'seasoning': 0.7, 'salt': 0.6, 'dairy': 0.5, 'sugar': 0.3, 'fruit': 0.3, 'liquid': 0.5},
    'liquid': {'grain': 0.7, 'vegetable': 0.7, 'meat': 0.7, 'seafood': 0.8, 'salt': 0.7, 'seasoning': 0.7, 'mushroom': 0.6, 'dairy': 0.6, 'egg': 0.6, 'sugar': 0.5, 'oil': 0.5, 'fruit': 0.5},
    'sugar': {'fruit': 0.9, 'dairy': 0.9, 'grain': 0.8, 'egg': 0.7, 'liquid': 0.5, 'oil': 0.3, 'meat': 0.2, 'seafood': 0.2, 'vegetable': 0.3, 'salt': 0.3, 'seasoning': 0.2, 'mushroom': 0.1},
    'salt': {'meat': 0.8, 'seafood': 0.9, 'vegetable': 0.8, 'egg': 0.7, 'grain': 0.7, 'liquid': 0.7, 'oil': 0.6, 'mushroom': 0.7, 'seasoning': 0.7, 'dairy': 0.5, 'sugar': 0.3, 'fruit': 0.2},
    'seasoning': {'meat': 0.9, 'seafood': 0.9, 'vegetable': 0.9, 'oil': 0.7, 'mushroom': 0.7, 'salt': 0.7, 'liquid': 0.7, 'egg': 0.6, 'grain': 0.6, 'dairy': 0.3, 'sugar': 0.2, 'fruit': 0.2},
  };

  // ─── 조리법 이름 ───

  static const _cookMethodByTools = <String, List<String>>{
    'none': ['혼합', '섞음', '무침', '절임'],
    'knife': ['회', '다짐', '채썰기', '슬라이스'],
    'water': ['수프', '삶음', '우려냄', '냉국'],
    'fire': ['구이', '볶음', '로스트', '훈제'],
    'knife_water': ['전골', '칼국수', '샤브샤브', '육수'],
    'knife_fire': ['스테이크', '볶음', '철판', '꼬치'],
    'water_fire': ['탕', '찌개', '조림', '찜'],
    'knife_water_fire': ['전골', '해물탕', '카레', '스튜'],
  };

  // ─── 이상한 조합 접두어 ───

  static const _weirdPrefixes = [
    '수상한', '기묘한', '도전적인', '실험적', '파격적',
    '대담한', '황당한', '충격적', '괴상한', '모험적',
  ];

  static const _normalPrefixes = [
    '정성스런', '특제', '오늘의', '집', '엄마의',
    '셰프의', '비밀', '전통', '수제', '프리미엄',
  ];

  static const _goodPrefixes = [
    '완벽한', '황금', '명품', '전설의', '비전',
    '극상', '일품', '최고급', '환상의', '마스터',
  ];

  // ─── 재료 타입별 한글 이름 ───

  static const _categoryKorean = <String, String>{
    'meat': '고기', 'seafood': '해물', 'vegetable': '야채',
    'grain': '곡물', 'dairy': '유제품', 'egg': '알',
    'fruit': '과일', 'mushroom': '버섯', 'oil': '기름',
    'liquid': '국물', 'sugar': '달콤', 'salt': '짭짤',
    'seasoning': '양념', 'derived': '특수',
  };

  /// 절차적 레시피 생성
  /// [ingredients] 재료 목록, [engine] 재료 정보 조회용
  static ProceduralResult generate({
    required List<Ingredient> ingredients,
    required int knifeValue,
    required int waterValue,
    required int fireValue,
  }) {
    if (ingredients.isEmpty) {
      return ProceduralResult(
        name: '아무것도 아닌 것',
        sanityScore: 0,
        category: '실패',
        toolRanges: {},
      );
    }

    // 1. 재료 카테고리 분석
    final categories = _analyzeCategories(ingredients);

    // 2. 궁합 점수 계산
    final sanity = _calculateSanity(categories);

    // 3. 이름 생성 (해시 기반 결정적 랜덤)
    final hash = _ingredientHash(ingredients);
    final name = _generateName(ingredients, categories, sanity, hash, knifeValue, waterValue, fireValue);

    // 4. 도구 범위 생성
    final toolRanges = _generateToolRanges(categories, hash);

    // 5. 카테고리 결정
    final category = _determineCategory(categories, sanity);

    return ProceduralResult(
      name: name,
      sanityScore: sanity,
      category: category,
      toolRanges: toolRanges,
    );
  }

  /// 재료들의 카테고리 비율 분석
  static Map<String, int> _analyzeCategories(List<Ingredient> ingredients) {
    final counts = <String, int>{};
    for (final ing in ingredients) {
      final cat = _getBaseCategory(ing);
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
    return counts;
  }

  /// 재료의 기본 카테고리 (추상 재료는 무시)
  static String _getBaseCategory(Ingredient ing) {
    switch (ing.type) {
      case IngredientType.meat: return 'meat';
      case IngredientType.seafood: return 'seafood';
      case IngredientType.vegetable: return 'vegetable';
      case IngredientType.grain: return 'grain';
      case IngredientType.dairy: return 'dairy';
      case IngredientType.egg: return 'egg';
      case IngredientType.fruit: return 'fruit';
      case IngredientType.mushroom: return 'mushroom';
      case IngredientType.oil: return 'oil';
      case IngredientType.liquid: return 'liquid';
      case IngredientType.sugar: return 'sugar';
      case IngredientType.salt: return 'salt';
      case IngredientType.seasoning: return 'seasoning';
      default: return 'derived';
    }
  }

  /// 궁합 점수 계산 (0.0 ~ 1.0)
  static double _calculateSanity(Map<String, int> categories) {
    final cats = categories.keys.where((c) => c != 'derived').toList();
    if (cats.length <= 1) return 0.8; // 단일 카테고리 = 무난

    double totalCompat = 0;
    int pairCount = 0;
    for (int i = 0; i < cats.length; i++) {
      for (int j = i + 1; j < cats.length; j++) {
        final compat = _getCompatibility(cats[i], cats[j]);
        totalCompat += compat;
        pairCount++;
      }
    }

    if (pairCount == 0) return 0.5;
    final avgCompat = totalCompat / pairCount;

    // 재료 수가 많을수록 약간 감점 (복잡도)
    final totalIngredients = categories.values.fold(0, (a, b) => a + b);
    final complexityPenalty = (totalIngredients > 5) ? (totalIngredients - 5) * 0.03 : 0.0;

    return (avgCompat - complexityPenalty).clamp(0.0, 1.0);
  }

  static double _getCompatibility(String a, String b) {
    return _compatibilityMatrix[a]?[b] ?? _compatibilityMatrix[b]?[a] ?? 0.4;
  }

  /// 결정적 해시 (같은 재료 → 같은 결과)
  static int _ingredientHash(List<Ingredient> ingredients) {
    final ids = ingredients.map((i) => i.id).toList()..sort();
    int hash = 0;
    for (final id in ids) {
      for (int i = 0; i < id.length; i++) {
        hash = (hash * 31 + id.codeUnitAt(i)) & 0x7FFFFFFF;
      }
    }
    return hash;
  }

  /// 레시피 이름 생성
  static String _generateName(
    List<Ingredient> ingredients,
    Map<String, int> categories,
    double sanity,
    int hash,
    int knifeValue,
    int waterValue,
    int fireValue,
  ) {
    // 주재료 (가장 많은 카테고리 또는 첫 번째)
    final mainIng = ingredients.first;
    final mainName = mainIng.name;

    // 조리법 결정
    final toolKey = _getToolKey(knifeValue, waterValue, fireValue);
    final methods = _cookMethodByTools[toolKey] ?? _cookMethodByTools['none']!;
    final method = methods[hash % methods.length];

    // 접두어 (궁합에 따라)
    String prefix;
    if (sanity >= 0.7) {
      // 랜덤 좋은/보통 접두어
      final prefixes = (hash % 3 == 0) ? _goodPrefixes : _normalPrefixes;
      prefix = prefixes[hash % prefixes.length];
    } else if (sanity >= 0.4) {
      // 보통 ~ 약간 이상
      final all = [..._normalPrefixes, ..._weirdPrefixes.sublist(0, 3)];
      prefix = all[hash % all.length];
    } else {
      // 뇌절
      prefix = _weirdPrefixes[hash % _weirdPrefixes.length];
    }

    // 부재료 이름 (2번째 재료)
    String subName = '';
    if (ingredients.length >= 2) {
      final sub = ingredients[1];
      subName = ' ${sub.name}';
    }

    // 재료 3개 이상이면 "외 N종"
    final extra = ingredients.length > 2 ? ' 외${ingredients.length - 2}종' : '';

    return '$prefix $mainName$subName $method$extra';
  }

  static String _getToolKey(int knife, int water, int fire) {
    final parts = <String>[];
    if (knife > 0) parts.add('knife');
    if (water > 0) parts.add('water');
    if (fire > 0) parts.add('fire');
    return parts.isEmpty ? 'none' : parts.join('_');
  }

  /// 도구 범위 생성 (해시 기반)
  static Map<String, ToolRange> _generateToolRanges(Map<String, int> categories, int hash) {
    final ranges = <String, ToolRange>{};
    final r = Random(hash);

    // 칼: 재료 수에 비례
    final total = categories.values.fold(0, (a, b) => a + b);
    final knifeOpt = 3 + total * 2 + r.nextInt(10);
    ranges['knife'] = ToolRange(
      min: (knifeOpt * 0.5).round(),
      max: (knifeOpt * 1.8).round(),
      optimal: knifeOpt,
    );

    // 물: 수프/탕 계열이면 높음
    final hasLiquid = categories.containsKey('liquid');
    final waterBase = hasLiquid ? 40 : 15;
    final waterOpt = waterBase + r.nextInt(30);
    ranges['water'] = ToolRange(
      min: (waterOpt * 0.4).round(),
      max: (waterOpt * 1.6).round(),
      optimal: waterOpt,
    );

    // 불: 고기/해물이면 높음
    final hasMeat = categories.containsKey('meat');
    final hasSeafood = categories.containsKey('seafood');
    final fireBase = (hasMeat || hasSeafood) ? 20 : 8;
    final fireOpt = fireBase + r.nextInt(20);
    ranges['fire'] = ToolRange(
      min: (fireOpt * 0.4).round(),
      max: (fireOpt * 1.8).round(),
      optimal: fireOpt,
    );

    return ranges;
  }

  /// 카테고리 결정
  static String _determineCategory(Map<String, int> categories, double sanity) {
    if (sanity < 0.3) return '실험 요리';
    if (sanity < 0.5) return '퓨전';

    // 주요 카테고리 기반
    final mainCat = categories.entries
        .where((e) => e.key != 'derived')
        .fold<MapEntry<String, int>?>(null, (prev, e) =>
            prev == null || e.value > prev.value ? e : prev);

    if (mainCat == null) return '기타';

    switch (mainCat.key) {
      case 'meat': return categories.containsKey('grain') ? '한식' : '양식';
      case 'seafood': return '일식';
      case 'grain': return categories.containsKey('dairy') ? '양식' : '한식';
      case 'dairy': return categories.containsKey('sugar') ? '디저트' : '양식';
      case 'fruit': return '디저트';
      case 'sugar': return '디저트';
      default: return '한식';
    }
  }

  /// 궁합 점수에 따른 품질 보정 계수 (0.3 ~ 1.2)
  /// 정상 조합은 보너스, 뇌절 조합은 큰 감점
  static double sanityMultiplier(double sanity) {
    if (sanity >= 0.8) return 1.0 + (sanity - 0.8) * 1.0; // 0.8~1.0 → 1.0~1.2
    if (sanity >= 0.6) return 0.8 + (sanity - 0.6) * 1.0;  // 0.6~0.8 → 0.8~1.0
    if (sanity >= 0.4) return 0.5 + (sanity - 0.4) * 1.5;  // 0.4~0.6 → 0.5~0.8
    return 0.3 + sanity * 0.5; // 0~0.4 → 0.3~0.5
  }

  /// 랜덤 보정 (±10%)
  static double randomBonus(int hash) {
    final r = Random(hash + DateTime.now().millisecondsSinceEpoch ~/ 10000);
    return 0.9 + r.nextDouble() * 0.2; // 0.9 ~ 1.1
  }
}

/// 절차적 생성 결과
class ProceduralResult {
  final String name;
  final double sanityScore; // 0.0 ~ 1.0 (궁합 점수)
  final String category;
  final Map<String, ToolRange> toolRanges;

  const ProceduralResult({
    required this.name,
    required this.sanityScore,
    required this.category,
    required this.toolRanges,
  });
}
