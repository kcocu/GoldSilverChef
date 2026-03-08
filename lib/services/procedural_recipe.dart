import 'dart:math';
import '../models/models.dart';

/// 절차적 레시피 생성 엔진
class ProceduralRecipeEngine {
  // ─── 카테고리 궁합 ───
  static const _compat = <String, Map<String, double>>{
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
  static const _cookMethods = <String, List<String>>{
    'none': ['혼합', '섞음', '무침', '절임'],
    'knife': ['회', '다짐', '채썰기', '슬라이스', '타르타르'],
    'water': ['수프', '삶음', '우려냄', '냉국'],
    'fire': ['구이', '볶음', '로스트', '훈제'],
    'knife_water': ['전골', '칼국수', '샤브샤브', '육수'],
    'knife_fire': ['스테이크', '볶음', '철판', '꼬치'],
    'water_fire': ['탕', '찌개', '조림', '찜'],
    'knife_water_fire': ['전골', '해물탕', '카레', '스튜'],
  };

  static const _weirdPrefixes = ['수상한', '기묘한', '도전적인', '실험적', '파격적', '대담한', '황당한', '충격적', '괴상한', '모험적'];
  static const _normalPrefixes = ['정성스런', '특제', '오늘의', '집', '엄마의', '셰프의', '비밀', '전통', '수제', '프리미엄'];
  static const _goodPrefixes = ['완벽한', '황금', '명품', '전설의', '비전', '극상', '일품', '최고급', '환상의', '마스터'];

  // ─── 비밀 레시피 (검색 불가) ───
  static final _secretRecipes = <_SecretRecipe>[
    // 소금 폭탄
    _SecretRecipe(
      check: (ids) => ids.where((id) => id == 'salt').length >= 5,
      name: '소금 폭탄',
      sanity: 0.1,
      comment: '소금만 잔뜩... 혈압이 위험합니다!',
      category: '실험 요리',
    ),
    // 바닷물 요리 (소금 다수 + 물 소량)
    _SecretRecipe(
      check: (ids) {
        final saltCount = ids.where((id) => id == 'salt').length;
        final hasLiquid = ids.contains('liquid');
        return saltCount >= 3 && hasLiquid;
      },
      name: '인공 바닷물 요리',
      sanity: 0.15,
      comment: '바다의 맛을 재현했습니다... 아마도.',
      category: '실험 요리',
    ),
    // 설탕 지옥
    _SecretRecipe(
      check: (ids) => ids.where((id) => id == 'sugar').length >= 5,
      name: '설탕 지옥 디저트',
      sanity: 0.1,
      comment: '치과 의사가 울고 갑니다.',
      category: '실험 요리',
    ),
    // 무지개 가루
    _SecretRecipe(
      check: (ids) {
        final powders = ['red_powder', 'blue_powder', 'green_powder', 'purple_powder', 'yellow_powder'];
        return powders.every((p) => ids.contains(p));
      },
      name: '무지개 환상 요리',
      sanity: 0.5,
      comment: '오색 가루의 조화! 눈이 부십니다!',
      category: '스페셜',
    ),
    // 구슬 전부
    _SecretRecipe(
      check: (ids) {
        final orbs = ['fresh_orb', 'lively_orb', 'fly_orb', 'flow_orb'];
        return orbs.every((o) => ids.contains(o));
      },
      name: '사원소 융합 요리',
      sanity: 0.6,
      comment: '신선, 활발, 비행, 흐름의 기운이 하나로!',
      category: '스페셜',
    ),
    // 모래시계 + 정체모를 가루
    _SecretRecipe(
      check: (ids) => ids.contains('hourglass') && ids.contains('mystery_powder') && ids.length == 2,
      name: '시간의 미스터리',
      sanity: 0.3,
      comment: '시간과 미지의 만남... 무슨 맛일까?',
      category: '스페셜',
    ),
    // 모든 기본 재료
    _SecretRecipe(
      check: (ids) {
        final bases = ['grain', 'meat', 'seafood', 'egg', 'dairy', 'vegetable', 'fruit', 'mushroom', 'oil', 'liquid', 'sugar', 'salt', 'seasoning'];
        return bases.every((b) => ids.contains(b));
      },
      name: '만물상 카오스 요리',
      sanity: 0.05,
      comment: '세상 모든 재료를 한 솥에! 용기에 박수를!',
      category: '스페셜',
    ),
    // 고기 x 5 이상
    _SecretRecipe(
      check: (ids) => ids.where((id) => id == 'meat').length >= 5,
      name: '육식공룡의 만찬',
      sanity: 0.2,
      comment: '고기만 잔뜩... 채소도 좀 드세요.',
      category: '실험 요리',
    ),
    // 기름 x 3 이상
    _SecretRecipe(
      check: (ids) => ids.where((id) => id == 'oil').length >= 3,
      name: '기름의 바다',
      sanity: 0.1,
      comment: '건강검진이 필요합니다.',
      category: '실험 요리',
    ),
    // 용암 요리 (불 수치 극대)
    _SecretRecipe(
      check: (ids) => false, // fireValue 체크는 generate에서 별도 처리
      name: '용암 요리',
      sanity: 0.05,
      comment: '모든 것이 타버렸습니다... 재만 남았네요.',
      category: '실험 요리',
    ),
  ];

  /// 절차적 레시피 생성
  static ProceduralResult generate({
    required List<Ingredient> ingredients,
    required int knifeValue,
    required int waterValue,
    required int fireValue,
  }) {
    if (ingredients.isEmpty) {
      return const ProceduralResult(
        name: '아무것도 아닌 것',
        sanityScore: 0,
        category: '실패',
        toolRanges: {},
        comment: '재료가 없습니다.',
      );
    }

    final ids = ingredients.map((i) => i.id).toList();
    final hash = _ingredientHash(ingredients);
    final categories = _analyzeCategories(ingredients);

    // ─── 비밀 레시피 체크 ───
    for (final secret in _secretRecipes) {
      if (secret.check(ids)) {
        return ProceduralResult(
          name: secret.name,
          sanityScore: secret.sanity,
          category: secret.category,
          toolRanges: _generateToolRanges(categories, hash),
          comment: secret.comment,
          isSecret: true,
        );
      }
    }

    // ─── 극단적 도구 사용 체크 ───
    // 불 극대 → 재
    if (fireValue > 80) {
      return ProceduralResult(
        name: '까맣게 탄 ${ingredients.first.name}',
        sanityScore: 0.05,
        category: '실험 요리',
        toolRanges: _generateToolRanges(categories, hash),
        comment: '불을 너무 오래 써서 재가 되었습니다...',
        isSecret: true,
      );
    }

    // 궁합 + 이름 생성
    final sanity = _calculateSanity(categories);
    final toolKey = _getToolKey(knifeValue, waterValue, fireValue);
    final name = _generateName(ingredients, categories, sanity, hash, toolKey);
    final comment = _generateComment(ingredients, knifeValue, waterValue, fireValue, categories);
    final category = _determineCategory(categories, sanity);

    return ProceduralResult(
      name: name,
      sanityScore: sanity,
      category: category,
      toolRanges: _generateToolRanges(categories, hash),
      comment: comment,
    );
  }

  // ─── 도구 사용 코멘트 생성 ───
  static String _generateComment(
    List<Ingredient> ingredients,
    int knifeValue,
    int waterValue,
    int fireValue,
    Map<String, int> categories,
  ) {
    final comments = <String>[];
    final mainCat = _getBaseCategory(ingredients.first);

    // 칼질 코멘트
    if (knifeValue > 0) {
      if (knifeValue <= 3) {
        comments.add('가볍게 칼질했습니다.');
      } else if (knifeValue <= 10) {
        comments.add('정성스럽게 썰었습니다.');
      } else if (knifeValue <= 20) {
        comments.add('잘게 다졌습니다.');
      } else if (knifeValue <= 40) {
        comments.add('아주 곱게 채썰기했습니다.');
      } else {
        comments.add('미친듯이 칼질! 거의 가루가 되었습니다.');
      }
    }

    // 물 코멘트
    if (waterValue > 0) {
      if (waterValue <= 10) {
        comments.add('살짝 물을 뿌렸습니다.');
      } else if (waterValue <= 30) {
        comments.add('적당한 물로 촉촉하게.');
      } else if (waterValue <= 60) {
        comments.add('물이 넉넉합니다. 국물 요리!');
      } else {
        comments.add('물이 넘칩니다! 거의 수영장...');
      }
    }

    // 불 코멘트 (고기일 때 특별)
    if (fireValue > 0) {
      if (mainCat == 'meat' || mainCat == 'seafood') {
        if (fireValue <= 5) {
          comments.add('레어! 속이 빨간 상태.');
        } else if (fireValue <= 12) {
          comments.add('미디엄 레어. 완벽한 핑크빛.');
        } else if (fireValue <= 20) {
          comments.add('미디엄. 적당히 익었습니다.');
        } else if (fireValue <= 35) {
          comments.add('미디엄 웰. 거의 다 익었네요.');
        } else if (fireValue <= 50) {
          comments.add('웰던! 바삭하게 잘 구워졌습니다.');
        } else {
          comments.add('과하게 구웠습니다! 약간 탄 냄새...');
        }
      } else if (mainCat == 'vegetable' || mainCat == 'mushroom') {
        if (fireValue <= 8) {
          comments.add('살짝 볶아 아삭합니다.');
        } else if (fireValue <= 20) {
          comments.add('적당히 볶아 부드럽습니다.');
        } else if (fireValue <= 40) {
          comments.add('오래 볶아 깊은 맛이 납니다.');
        } else {
          comments.add('너무 오래 볶아 쭈글쭈글...');
        }
      } else {
        if (fireValue <= 10) {
          comments.add('약불로 천천히.');
        } else if (fireValue <= 30) {
          comments.add('중불로 적당히.');
        } else {
          comments.add('강불로 빠르게!');
        }
      }
    }

    // 도구 미사용
    if (knifeValue == 0 && waterValue == 0 && fireValue == 0) {
      comments.add('도구를 사용하지 않았습니다. 날것 그대로!');
    }

    return comments.join(' ');
  }

  static Map<String, int> _analyzeCategories(List<Ingredient> ingredients) {
    final counts = <String, int>{};
    for (final ing in ingredients) {
      final cat = _getBaseCategory(ing);
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
    return counts;
  }

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

  static double _calculateSanity(Map<String, int> categories) {
    final cats = categories.keys.where((c) => c != 'derived').toList();
    if (cats.length <= 1) return 0.8;

    double totalCompat = 0;
    int pairCount = 0;
    for (int i = 0; i < cats.length; i++) {
      for (int j = i + 1; j < cats.length; j++) {
        totalCompat += _compat[cats[i]]?[cats[j]] ?? _compat[cats[j]]?[cats[i]] ?? 0.4;
        pairCount++;
      }
    }

    if (pairCount == 0) return 0.5;
    final avgCompat = totalCompat / pairCount;
    final totalIng = categories.values.fold(0, (a, b) => a + b);
    final penalty = (totalIng > 5) ? (totalIng - 5) * 0.03 : 0.0;
    return (avgCompat - penalty).clamp(0.0, 1.0);
  }

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

  static String _getToolKey(int knife, int water, int fire) {
    final parts = <String>[];
    if (knife > 0) parts.add('knife');
    if (water > 0) parts.add('water');
    if (fire > 0) parts.add('fire');
    return parts.isEmpty ? 'none' : parts.join('_');
  }

  static String _generateName(
    List<Ingredient> ingredients,
    Map<String, int> categories,
    double sanity,
    int hash,
    String toolKey,
  ) {
    final mainName = ingredients.first.name;
    final methods = _cookMethods[toolKey] ?? _cookMethods['none']!;
    final method = methods[hash % methods.length];

    String prefix;
    if (sanity >= 0.7) {
      final prefixes = (hash % 3 == 0) ? _goodPrefixes : _normalPrefixes;
      prefix = prefixes[hash % prefixes.length];
    } else if (sanity >= 0.4) {
      final all = [..._normalPrefixes, ..._weirdPrefixes.sublist(0, 3)];
      prefix = all[hash % all.length];
    } else {
      prefix = _weirdPrefixes[hash % _weirdPrefixes.length];
    }

    String subName = '';
    if (ingredients.length >= 2) subName = ' ${ingredients[1].name}';
    final extra = ingredients.length > 2 ? ' 외${ingredients.length - 2}종' : '';

    return '$prefix $mainName$subName $method$extra';
  }

  static Map<String, ToolRange> _generateToolRanges(Map<String, int> categories, int hash) {
    final ranges = <String, ToolRange>{};
    final r = Random(hash);
    final total = categories.values.fold(0, (a, b) => a + b);

    final knifeOpt = 3 + total * 2 + r.nextInt(10);
    ranges['knife'] = ToolRange(min: (knifeOpt * 0.5).round(), max: (knifeOpt * 1.8).round(), optimal: knifeOpt);

    final hasLiquid = categories.containsKey('liquid');
    final waterOpt = (hasLiquid ? 40 : 15) + r.nextInt(30);
    ranges['water'] = ToolRange(min: (waterOpt * 0.4).round(), max: (waterOpt * 1.6).round(), optimal: waterOpt);

    final hasMeat = categories.containsKey('meat');
    final hasSeafood = categories.containsKey('seafood');
    final fireOpt = ((hasMeat || hasSeafood) ? 20 : 8) + r.nextInt(20);
    ranges['fire'] = ToolRange(min: (fireOpt * 0.4).round(), max: (fireOpt * 1.8).round(), optimal: fireOpt);

    return ranges;
  }

  static String _determineCategory(Map<String, int> categories, double sanity) {
    if (sanity < 0.3) return '실험 요리';
    if (sanity < 0.5) return '퓨전';
    final mainCat = categories.entries.where((e) => e.key != 'derived')
        .fold<MapEntry<String, int>?>(null, (prev, e) => prev == null || e.value > prev.value ? e : prev);
    if (mainCat == null) return '기타';
    switch (mainCat.key) {
      case 'meat': return categories.containsKey('grain') ? '한식' : '양식';
      case 'seafood': return '일식';
      case 'grain': return categories.containsKey('dairy') ? '양식' : '한식';
      case 'dairy': case 'fruit': case 'sugar': return '디저트';
      default: return '한식';
    }
  }

  static double sanityMultiplier(double sanity) {
    if (sanity >= 0.8) return 1.0 + (sanity - 0.8) * 1.0;
    if (sanity >= 0.6) return 0.8 + (sanity - 0.6) * 1.0;
    if (sanity >= 0.4) return 0.5 + (sanity - 0.4) * 1.5;
    return 0.3 + sanity * 0.5;
  }

  static double randomBonus(int hash) {
    final r = Random(hash + DateTime.now().millisecondsSinceEpoch ~/ 10000);
    return 0.9 + r.nextDouble() * 0.2;
  }
}

class _SecretRecipe {
  final bool Function(List<String> ingredientIds) check;
  final String name;
  final double sanity;
  final String comment;
  final String category;
  const _SecretRecipe({required this.check, required this.name, required this.sanity, required this.comment, required this.category});
}

class ProceduralResult {
  final String name;
  final double sanityScore;
  final String category;
  final Map<String, ToolRange> toolRanges;
  final String comment;
  final bool isSecret;

  const ProceduralResult({
    required this.name,
    required this.sanityScore,
    required this.category,
    required this.toolRanges,
    this.comment = '',
    this.isSecret = false,
  });
}
