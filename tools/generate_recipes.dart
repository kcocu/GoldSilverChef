// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// 10,000종 레시피 + 재료 자동 생성기
/// 실행: dart run tools/generate_recipes.dart

final _rand = Random(42); // 시드 고정으로 재현 가능

// ─── 기본 24종 재료 ───
final baseIngredients = <Map<String, dynamic>>[
  {'id': 'grain', 'name': '곡물', 'type': 'grain', 'icon': '🌾', 'isBase': true, 'tier': 0},
  {'id': 'meat', 'name': '육류', 'type': 'meat', 'icon': '🥩', 'isBase': true, 'tier': 0},
  {'id': 'seafood', 'name': '수산물', 'type': 'seafood', 'icon': '🐟', 'isBase': true, 'tier': 0},
  {'id': 'egg', 'name': '알', 'type': 'egg', 'icon': '🥚', 'isBase': true, 'tier': 0},
  {'id': 'dairy', 'name': '유제품', 'type': 'dairy', 'icon': '🥛', 'isBase': true, 'tier': 0},
  {'id': 'vegetable', 'name': '채소', 'type': 'vegetable', 'icon': '🥬', 'isBase': true, 'tier': 0},
  {'id': 'fruit', 'name': '과일', 'type': 'fruit', 'icon': '🍎', 'isBase': true, 'tier': 0},
  {'id': 'mushroom', 'name': '버섯', 'type': 'mushroom', 'icon': '🍄', 'isBase': true, 'tier': 0},
  {'id': 'oil', 'name': '기름', 'type': 'oil', 'icon': '🫒', 'isBase': true, 'tier': 0},
  {'id': 'liquid', 'name': '액체', 'type': 'liquid', 'icon': '💧', 'isBase': true, 'tier': 0},
  {'id': 'sugar', 'name': '설탕', 'type': 'sugar', 'icon': '🍬', 'isBase': true, 'tier': 0},
  {'id': 'salt', 'name': '소금', 'type': 'salt', 'icon': '🧂', 'isBase': true, 'tier': 0},
  {'id': 'seasoning', 'name': '양념', 'type': 'seasoning', 'icon': '🌶️', 'isBase': true, 'tier': 0},
  {'id': 'red_powder', 'name': '빨간가루', 'type': 'redPowder', 'icon': '🔴', 'isBase': true, 'tier': 0},
  {'id': 'blue_powder', 'name': '파란가루', 'type': 'bluePowder', 'icon': '🔵', 'isBase': true, 'tier': 0},
  {'id': 'green_powder', 'name': '초록가루', 'type': 'greenPowder', 'icon': '🟢', 'isBase': true, 'tier': 0},
  {'id': 'purple_powder', 'name': '보라가루', 'type': 'purplePowder', 'icon': '🟣', 'isBase': true, 'tier': 0},
  {'id': 'yellow_powder', 'name': '노란가루', 'type': 'yellowPowder', 'icon': '🟡', 'isBase': true, 'tier': 0},
  {'id': 'hourglass', 'name': '모래시계', 'type': 'hourglass', 'icon': '⏳', 'isBase': true, 'tier': 0},
  {'id': 'fresh_orb', 'name': '신선한 구슬', 'type': 'freshOrb', 'icon': '🟩', 'isBase': true, 'tier': 0},
  {'id': 'lively_orb', 'name': '활발한 구슬', 'type': 'livelyOrb', 'icon': '🟧', 'isBase': true, 'tier': 0},
  {'id': 'fly_orb', 'name': '날아라 구슬', 'type': 'flyOrb', 'icon': '🟦', 'isBase': true, 'tier': 0},
  {'id': 'flow_orb', 'name': '흘러라 구슬', 'type': 'flowOrb', 'icon': '🟪', 'isBase': true, 'tier': 0},
  {'id': 'mystery_powder', 'name': '정체모를 가루', 'type': 'mysteryPowder', 'icon': '❓', 'isBase': true, 'tier': 0},
];

// ─── 파생 재료 정의 (tier 1~3) ───

// tier 1: 기본 재료 + 가루/구슬 조합
final tier1Derivations = <_Derivation>[
  // 육류 파생
  _Derivation('beef', '소고기', '🥩', ['meat', 'red_powder'], 1),
  _Derivation('chicken', '닭고기', '🍗', ['meat', 'yellow_powder'], 1),
  _Derivation('pork', '돼지고기', '🥓', ['meat', 'green_powder'], 1),
  _Derivation('lamb', '양고기', '🐑', ['meat', 'purple_powder'], 1),
  _Derivation('duck', '오리고기', '🦆', ['meat', 'blue_powder'], 1),
  _Derivation('venison', '사슴고기', '🦌', ['meat', 'mystery_powder'], 1),
  _Derivation('organ_meat', '내장', '🫀', ['meat', 'lively_orb'], 1),
  _Derivation('bone', '뼈', '🦴', ['meat', 'hourglass'], 1),

  // 수산물 파생
  _Derivation('salmon', '연어', '🐟', ['seafood', 'red_powder'], 1),
  _Derivation('tuna', '참치', '🐟', ['seafood', 'blue_powder'], 1),
  _Derivation('cod', '대구', '🐟', ['seafood', 'green_powder'], 1),
  _Derivation('mackerel', '고등어', '🐟', ['seafood', 'yellow_powder'], 1),
  _Derivation('shrimp', '새우', '🦐', ['seafood', 'lively_orb'], 1),
  _Derivation('crab', '게', '🦀', ['seafood', 'fresh_orb'], 1),
  _Derivation('lobster', '랍스터', '🦞', ['seafood', 'fly_orb'], 1),
  _Derivation('squid', '오징어', '🦑', ['seafood', 'flow_orb'], 1),
  _Derivation('octopus', '문어', '🐙', ['seafood', 'purple_powder'], 1),
  _Derivation('clam', '조개', '🐚', ['seafood', 'mystery_powder'], 1),
  _Derivation('seaweed', '해조류', '🌿', ['seafood', 'hourglass'], 1),
  _Derivation('roe', '어란', '🟠', ['egg', 'seafood'], 1),

  // 곡물 파생
  _Derivation('rice', '쌀', '🍚', ['grain', 'fresh_orb'], 1),
  _Derivation('wheat_flour', '밀가루', '🌾', ['grain', 'yellow_powder'], 1),
  _Derivation('noodle_dough', '면 반죽', '🍜', ['grain', 'flow_orb'], 1),
  _Derivation('corn', '옥수수', '🌽', ['grain', 'lively_orb'], 1),
  _Derivation('potato', '감자', '🥔', ['grain', 'purple_powder'], 1),
  _Derivation('bean', '콩', '🫘', ['grain', 'green_powder'], 1),
  _Derivation('oat', '귀리', '🌾', ['grain', 'blue_powder'], 1),
  _Derivation('barley', '보리', '🌾', ['grain', 'red_powder'], 1),

  // 채소 파생
  _Derivation('cabbage', '배추', '🥬', ['vegetable', 'green_powder'], 1),
  _Derivation('lettuce', '상추', '🥬', ['vegetable', 'fresh_orb'], 1),
  _Derivation('spinach', '시금치', '🥬', ['vegetable', 'lively_orb'], 1),
  _Derivation('carrot', '당근', '🥕', ['vegetable', 'red_powder'], 1),
  _Derivation('radish', '무', '🥬', ['vegetable', 'blue_powder'], 1),
  _Derivation('onion', '양파', '🧅', ['vegetable', 'yellow_powder'], 1),
  _Derivation('garlic', '마늘', '🧄', ['vegetable', 'purple_powder'], 1),
  _Derivation('tomato', '토마토', '🍅', ['vegetable', 'fly_orb'], 1),
  _Derivation('pumpkin', '호박', '🎃', ['vegetable', 'flow_orb'], 1),
  _Derivation('eggplant', '가지', '🍆', ['vegetable', 'mystery_powder'], 1),
  _Derivation('pepper', '고추', '🌶️', ['vegetable', 'hourglass'], 1),
  _Derivation('cucumber', '오이', '🥒', ['vegetable', 'green_powder', 'fresh_orb'], 1),
  _Derivation('green_onion', '파', '🧅', ['vegetable', 'green_powder', 'lively_orb'], 1),

  // 과일 파생
  _Derivation('apple', '사과', '🍎', ['fruit', 'red_powder'], 1),
  _Derivation('lemon', '레몬', '🍋', ['fruit', 'yellow_powder'], 1),
  _Derivation('orange', '오렌지', '🍊', ['fruit', 'lively_orb'], 1),
  _Derivation('grape', '포도', '🍇', ['fruit', 'purple_powder'], 1),
  _Derivation('banana', '바나나', '🍌', ['fruit', 'flow_orb'], 1),
  _Derivation('strawberry', '딸기', '🍓', ['fruit', 'fresh_orb'], 1),
  _Derivation('mango', '망고', '🥭', ['fruit', 'fly_orb'], 1),
  _Derivation('coconut', '코코넛', '🥥', ['fruit', 'mystery_powder'], 1),
  _Derivation('pineapple', '파인애플', '🍍', ['fruit', 'blue_powder'], 1),
  _Derivation('peach', '복숭아', '🍑', ['fruit', 'green_powder'], 1),
  _Derivation('watermelon', '수박', '🍉', ['fruit', 'hourglass'], 1),

  // 유제품 파생
  _Derivation('butter', '버터', '🧈', ['dairy', 'yellow_powder'], 1),
  _Derivation('cheese', '치즈', '🧀', ['dairy', 'hourglass'], 1),
  _Derivation('cream', '크림', '🥛', ['dairy', 'fresh_orb'], 1),
  _Derivation('yogurt', '요거트', '🥛', ['dairy', 'lively_orb'], 1),

  // 기름 파생
  _Derivation('olive_oil', '올리브유', '🫒', ['oil', 'green_powder'], 1),
  _Derivation('sesame_oil', '참기름', '🫒', ['oil', 'yellow_powder'], 1),
  _Derivation('coconut_oil', '코코넛오일', '🫒', ['oil', 'mystery_powder'], 1),

  // 액체 파생
  _Derivation('wine', '와인', '🍷', ['liquid', 'purple_powder', 'hourglass'], 1),
  _Derivation('beer', '맥주', '🍺', ['liquid', 'yellow_powder', 'hourglass'], 1),
  _Derivation('vinegar', '식초', '🫙', ['liquid', 'hourglass'], 1),
  _Derivation('soy_sauce', '간장', '🫙', ['liquid', 'red_powder', 'hourglass'], 1),
  _Derivation('sea_water', '바닷물', '🌊', ['liquid', 'liquid', 'salt'], 1),

  // 양념 파생
  _Derivation('soy_paste', '된장', '🫙', ['seasoning', 'hourglass', 'green_powder'], 1),
  _Derivation('hot_paste', '고추장', '🫙', ['seasoning', 'hourglass', 'red_powder'], 1),
  _Derivation('curry_powder', '카레가루', '🟡', ['seasoning', 'yellow_powder', 'lively_orb'], 1),
  _Derivation('pepper_ground', '후추', '⚫', ['seasoning', 'purple_powder'], 1),
  _Derivation('cinnamon', '계피', '🟤', ['seasoning', 'red_powder', 'hourglass'], 1),
  _Derivation('herb', '허브', '🌿', ['seasoning', 'green_powder', 'fresh_orb'], 1),
  _Derivation('vanilla', '바닐라', '🤍', ['seasoning', 'mystery_powder', 'fresh_orb'], 1),
  _Derivation('saffron', '사프란', '🟡', ['seasoning', 'mystery_powder', 'hourglass'], 1),

  // 구슬/가루 특수 조합
  _Derivation('honey', '꿀', '🍯', ['fresh_orb', 'lively_orb'], 1),
  _Derivation('maple_syrup', '메이플시럽', '🍁', ['flow_orb', 'hourglass'], 1),
  _Derivation('yeast', '효모', '🟤', ['mystery_powder', 'lively_orb'], 1),
  _Derivation('gelatin', '젤라틴', '🟡', ['mystery_powder', 'flow_orb'], 1),

  // 버섯 파생
  _Derivation('shiitake', '표고버섯', '🍄', ['mushroom', 'red_powder'], 1),
  _Derivation('oyster_mushroom', '느타리버섯', '🍄', ['mushroom', 'blue_powder'], 1),
  _Derivation('enoki', '팽이버섯', '🍄', ['mushroom', 'fresh_orb'], 1),
  _Derivation('truffle', '트러플', '🍄', ['mushroom', 'mystery_powder', 'hourglass'], 1),
  _Derivation('matsutake', '송이버섯', '🍄', ['mushroom', 'purple_powder', 'hourglass'], 1),

  // 설탕 파생
  _Derivation('brown_sugar', '흑설탕', '🟫', ['sugar', 'hourglass'], 1),
  _Derivation('candy', '사탕', '🍭', ['sugar', 'lively_orb'], 1),
  _Derivation('caramel', '카라멜', '🟤', ['sugar', 'red_powder'], 1),

  // 알 파생
  _Derivation('chicken_egg', '달걀', '🥚', ['egg', 'yellow_powder'], 1),
  _Derivation('quail_egg', '메추리알', '🥚', ['egg', 'green_powder'], 1),
  _Derivation('duck_egg', '오리알', '🥚', ['egg', 'blue_powder'], 1),

  // 곤충 (특수)
  _Derivation('insect', '식용곤충', '🦗', ['mystery_powder', 'lively_orb', 'green_powder'], 1),
  _Derivation('edible_flower', '식용꽃', '🌸', ['mystery_powder', 'fresh_orb', 'red_powder'], 1),
  _Derivation('gold_leaf', '금박', '✨', ['mystery_powder', 'hourglass', 'yellow_powder'], 1),
  _Derivation('nut', '견과류', '🥜', ['fruit', 'hourglass', 'lively_orb'], 1),
  _Derivation('chocolate', '초콜릿', '🍫', ['fruit', 'hourglass', 'mystery_powder'], 1),
  _Derivation('tea_leaf', '찻잎', '🍃', ['vegetable', 'hourglass', 'fresh_orb'], 1),
];

// tier 2: 가공 재료 (도구 사용)
final tier2Derivations = <_Derivation>[
  // 가공육
  _Derivation('ground_beef', '소고기 다짐', '🥩', ['beef'], 2, knife: [20, 40, 30]),
  _Derivation('sliced_pork', '돼지고기 슬라이스', '🥓', ['pork'], 2, knife: [5, 15, 10]),
  _Derivation('chicken_breast', '닭가슴살', '🍗', ['chicken'], 2, knife: [3, 10, 6]),
  _Derivation('lamb_chop', '양갈비', '🐑', ['lamb'], 2, knife: [5, 12, 8]),
  _Derivation('duck_breast', '오리가슴살', '🦆', ['duck'], 2, knife: [3, 10, 6]),

  // 가공 수산물
  _Derivation('salmon_fillet', '연어 필렛', '🐟', ['salmon'], 2, knife: [3, 8, 5]),
  _Derivation('tuna_sashimi', '참치회', '🐟', ['tuna'], 2, knife: [10, 25, 18]),
  _Derivation('shrimp_peeled', '껍질 벗긴 새우', '🦐', ['shrimp'], 2, knife: [5, 12, 8]),
  _Derivation('squid_rings', '오징어링', '🦑', ['squid'], 2, knife: [8, 15, 12]),
  _Derivation('fish_cake_paste', '어묵 반죽', '🐟', ['cod', 'wheat_flour', 'egg'], 2, knife: [15, 30, 22]),

  // 밥/면
  _Derivation('cooked_rice', '밥', '🍚', ['rice'], 2, water: [60, 80, 70], fire: [4, 8, 6]),
  _Derivation('noodle', '면', '🍜', ['noodle_dough'], 2, knife: [10, 20, 15], water: [30, 50, 40]),
  _Derivation('bread_dough', '빵 반죽', '🍞', ['wheat_flour', 'yeast'], 2, water: [40, 60, 50]),
  _Derivation('pasta_dough', '파스타 반죽', '🍝', ['wheat_flour', 'chicken_egg', 'olive_oil'], 2, water: [20, 35, 28]),
  _Derivation('dumpling_skin', '만두피', '🥟', ['wheat_flour'], 2, water: [35, 50, 42], knife: [5, 10, 7]),

  // 소스/양념 가공
  _Derivation('mayo', '마요네즈', '🥫', ['chicken_egg', 'oil', 'vinegar'], 2),
  _Derivation('ketchup', '케첩', '🥫', ['tomato', 'vinegar', 'sugar'], 2, fire: [2, 5, 3]),
  _Derivation('steak_sauce', '스테이크 소스', '🥫', ['soy_sauce', 'butter', 'garlic'], 2, fire: [3, 6, 4]),
  _Derivation('teriyaki_sauce', '데리야끼 소스', '🥫', ['soy_sauce', 'sugar', 'vinegar'], 2, fire: [2, 5, 3]),
  _Derivation('cream_sauce', '크림소스', '🥫', ['cream', 'butter', 'onion'], 2, fire: [2, 5, 3]),
  _Derivation('tomato_sauce', '토마토소스', '🥫', ['tomato', 'garlic', 'olive_oil'], 2, fire: [3, 7, 5]),
  _Derivation('pesto', '페스토', '🥫', ['herb', 'garlic', 'olive_oil', 'nut'], 2),
  _Derivation('salsa', '살사', '🥫', ['tomato', 'onion', 'pepper'], 2, knife: [10, 20, 15]),
  _Derivation('wasabi', '와사비', '🟢', ['radish', 'green_powder', 'lively_orb'], 2),
  _Derivation('ginger', '생강', '🫚', ['vegetable', 'lively_orb', 'yellow_powder'], 2),
  _Derivation('dressing', '드레싱', '🥫', ['olive_oil', 'vinegar', 'honey'], 2),
  _Derivation('chili_oil', '고추기름', '🌶️', ['oil', 'pepper'], 2, fire: [2, 5, 3]),
  _Derivation('garlic_butter', '마늘버터', '🧈', ['butter', 'garlic'], 2, fire: [1, 3, 2]),
  _Derivation('balsamic', '발사믹', '🫙', ['vinegar', 'grape', 'hourglass'], 2),

  // 두부/콩 가공
  _Derivation('tofu', '두부', '🟫', ['bean', 'sea_water'], 2, fire: [3, 6, 4]),
  _Derivation('soy_milk', '두유', '🥛', ['bean'], 2, water: [50, 70, 60], fire: [3, 6, 4]),

  // 치즈 파생
  _Derivation('mozzarella', '모짜렐라', '🧀', ['cheese', 'fresh_orb'], 2),
  _Derivation('parmesan', '파르메산', '🧀', ['cheese', 'hourglass'], 2),
  _Derivation('cream_cheese', '크림치즈', '🧀', ['cheese', 'cream'], 2),

  // 빵류
  _Derivation('bread', '빵', '🍞', ['bread_dough'], 2, fire: [4, 8, 6]),
  _Derivation('tortilla', '또띠아', '🫓', ['wheat_flour'], 2, fire: [3, 6, 5], water: [25, 40, 32]),

  // 기타 가공
  _Derivation('broth', '육수', '🍲', ['bone'], 2, water: [70, 90, 80], fire: [4, 9, 7]),
  _Derivation('fish_broth', '해물 육수', '🍲', ['seaweed', 'clam'], 2, water: [70, 90, 80], fire: [4, 9, 7]),
  _Derivation('dashi', '다시', '🍲', ['seaweed', 'shiitake'], 2, water: [60, 80, 70], fire: [3, 7, 5]),
  _Derivation('coconut_milk', '코코넛밀크', '🥥', ['coconut'], 2, water: [40, 60, 50]),
  _Derivation('whipped_cream', '휘핑크림', '🍰', ['cream', 'sugar'], 2),
  _Derivation('chocolate_sauce', '초콜릿소스', '🍫', ['chocolate', 'cream'], 2, fire: [1, 4, 2]),
  _Derivation('jam', '잼', '🫙', ['strawberry', 'sugar'], 2, fire: [2, 5, 3]),
  _Derivation('lemon_juice', '레몬즙', '🍋', ['lemon'], 2, knife: [3, 8, 5]),
  _Derivation('pickled_veg', '절임채소', '🥒', ['cucumber', 'vinegar', 'salt'], 2),
  _Derivation('kimchi', '김치', '🥬', ['cabbage', 'hot_paste', 'garlic', 'salt'], 2, knife: [10, 20, 15]),
  _Derivation('fermented_bean', '청국장', '🫘', ['bean', 'hourglass', 'salt'], 2),
  _Derivation('miso', '미소', '🫙', ['bean', 'hourglass', 'salt', 'rice'], 2),
  _Derivation('rice_wine', '막걸리', '🍶', ['rice', 'yeast', 'hourglass'], 2),
  _Derivation('sake', '사케', '🍶', ['rice', 'yeast', 'hourglass', 'fresh_orb'], 2),
  _Derivation('tea', '차', '🍵', ['tea_leaf'], 2, water: [60, 80, 70], fire: [2, 5, 3]),
  _Derivation('coffee_bean', '커피원두', '☕', ['bean', 'red_powder', 'hourglass'], 2),
  _Derivation('coffee', '커피', '☕', ['coffee_bean'], 2, water: [50, 70, 60], fire: [3, 6, 5]),
];

// ─── 요리 카테고리별 정의 ───
// 각 카테고리에서 수백 종의 요리를 생성

class _RecipeTemplate {
  final String namePrefix;
  final String category;
  final List<List<String>> inputCombos; // 가능한 입력 조합들
  final List<String> cookingMethods; // 조리법 접두/접미
  final int baseDifficulty;
  final int tier;

  _RecipeTemplate(this.namePrefix, this.category, this.inputCombos,
      this.cookingMethods, this.baseDifficulty, this.tier);
}

class _Derivation {
  final String id;
  final String name;
  final String icon;
  final List<String> inputIds;
  final int tier;
  final List<int>? knife; // [min, max, optimal]
  final List<int>? water;
  final List<int>? fire;

  _Derivation(this.id, this.name, this.icon, this.inputIds, this.tier,
      {this.knife, this.water, this.fire});
}

// 한식 요리 이름 생성
final koreanDishes = [
  '김치찌개', '된장찌개', '부대찌개', '순두부찌개', '비빔밥', '돌솥비빔밥',
  '불고기', '갈비찜', '잡채', '떡볶이', '김밥', '해물파전', '감자전', '김치전',
  '삼겹살구이', '족발', '보쌈', '닭갈비', '찜닭', '삼계탕', '설렁탕', '갈비탕',
  '냉면', '칼국수', '수제비', '잔치국수', '비빔국수', '막국수',
  '제육볶음', '오징어볶음', '낙지볶음', '두부조림', '고등어조림', '멸치볶음',
  '나물무침', '잡곡밥', '오이소박이', '깍두기', '동치미', '식혜',
  '호떡', '붕어빵', '계란빵', '인절미', '떡갈비', '육회',
  '장어구이', '조개구이', '해물탕', '매운탕', '꽃게탕', '대구탕',
  '미역국', '계란국', '콩나물국', '무국', '떡국', '만두국',
  '만두', '왕만두', '군만두', '물만두', '편육', '수육',
  '닭볶음탕', '감자조림', '연근조림', '우엉조림', '어묵탕',
  '순대', '곱창볶음', '대패삼겹살', '치즈닭갈비', '양념치킨',
  '간장게장', '양념게장', '회덮밥', '알밥', '전복죽', '호박죽',
  '팥빙수', '미숫가루', '수정과', '약과', '한과',
];

final japaneseDishes = [
  '초밥', '사시미', '라멘', '우동', '소바', '돈카츠', '가츠동',
  '오야코동', '규동', '텐동', '텐뿌라', '야키토리', '타코야끼',
  '오코노미야끼', '카레라이스', '오므라이스', '고로케', '에비후라이',
  '미소시루', '스키야키', '샤부샤부', '나베', '차완무시', '에다마메',
  '교자', '유부초밥', '치라시스시', '카이센동', '장어덮밥',
  '마파두부', '야키소바', '야키우동', '냉야키소바',
  '모찌', '다이후쿠', '도라야끼', '타이야끼', '카스테라',
  '말차라떼', '말차아이스크림', '안미츠', '양갱', '센베이',
  '참치마요동', '연어동', '새우동', '문어초밥', '가리비초밥',
  '계란초밥', '장어초밥', '토로초밥', '아나고초밥', '오뎅',
];

final westernDishes = [
  '스테이크', '비프스튜', '햄버거', '파스타', '피자', '리조또',
  '라자냐', '그라탱', '크림스프', '미네스트로네', '프렌치토스트',
  '팬케이크', '와플', '오믈렛', '에그베네딕트', '시저샐러드',
  '카프레제', '브루스케타', '카르파초', '타르타르',
  '로스트치킨', '로스트비프', '비프웰링턴', '양갈비스테이크',
  '연어스테이크', '랍스터구이', '새우그라탱', '클램차우더',
  '피시앤칩스', '부야베스', '빠에야', '나시고렝',
  '봉골레', '카르보나라', '아라비아따', '뇨끼', '라비올리',
  '티라미수', '판나코타', '크렘브륄레', '마카롱', '에끌레어',
  '크루아상', '슈크림', '밀푀유', '타르트', '무스케이크',
  '브라우니', '쿠키', '머핀', '스콘', '치즈케이크',
  '아이스크림', '소르베', '젤라또', '와인소스', '크림리듀스',
  '감바스', '뱅쇼', '상그리아', '핫초코', '아포가토',
];

final chineseDishes = [
  '짜장면', '짬뽕', '탕수육', '볶음밥', '마파두부', '깐풍기',
  '깐쇼새우', '유린기', '팔보채', '동파육', '꿔바로우',
  '라조기', '궁보계정', '만두', '소롱포', '딤섬',
  '마라탕', '훠궈', '양꼬치', '베이징덕', '부추잡채',
  '잡탕밥', '해물볶음면', '계란볶음밥', '새우볶음밥',
  '깐풍새우', '칠리새우', '어향가지', '마라샹궈',
  '크림새우', '비빔쫄면', '게살볶음밥', '양장피',
  '춘권', '우육면', '단단면', '반반', '유니짜장',
  '차돌짬뽕', '해물짬뽕', '삼선짬뽕', '간짜장',
  '송이덮밥', '전가복', '군만두', '물만두', '찐만두',
];

final dessertDishes = [
  '초콜릿케이크', '딸기케이크', '치즈케이크', '당근케이크', '레드벨벳케이크',
  '바닐라아이스크림', '초콜릿아이스크림', '딸기아이스크림', '망고아이스크림',
  '크레페', '수플레', '푸딩', '젤리', '타르트', '파이',
  '마카롱', '쿠키', '브라우니', '머핀', '도넛',
  '와플', '팬케이크', '프렌치토스트', '베이글', '시나몬롤',
  '카라멜푸딩', '과일타르트', '레몬타르트', '초콜릿타르트',
  '몽블랑', '오페라케이크', '자허토르테', '블랙포레스트',
  '바클라바', '떡', '약과', '강정', '유과',
  '찰떡아이스', '호떡', '팥빵', '크림빵', '소보로빵',
  '롤케이크', '생크림케이크', '바나나스플릿', '선데이',
  '밀크셰이크', '스무디', '프라푸치노', '버블티',
  '마들렌', '피낭시에', '캐놀리', '프로피테롤', '클라푸티',
];

final fusionDishes = [
  '김치볶음밥피자', '불고기버거', '김치파스타', '고추장스테이크',
  '된장크림파스타', '매콤로제파스타', '떡카르보나라', '김치그라탱',
  '와사비스테이크', '간장버터연어', '고추냉이크림소스', '유자드레싱샐러드',
  '김치치즈볼', '떡볶이그라탱', '매운크림리조또', '고추장나시고렝',
  '불고기타코', '비빔밥보울', '김치퀘사디아', '갈비슬라이더',
  '고추장윙', '김치프라이드라이스', '된장리조또', '매콤크림우동',
  '참깨드레싱파스타', '와사비마요새우', '유자소르베', '말차크레페',
  '떡와플', '인절미토스트', '흑임자라떼', '고구마라떼',
  '매운해물리조또', '갈비찜파스타', '김치볶음우동', '제육파스타',
  '간장새우파스타', '크림떡볶이', '치즈떡갈비', '매콤치즈퐁듀',
  '고구마무스', '유자마카롱', '흑임자마카롱', '말차티라미수',
  '인절미빙수', '매실스무디', '쌍화차라떼', '대추라떼',
  '김치볶음밥오믈렛', '불고기피자', '고추장프라이드치킨',
];

final specialDishes = [
  '트러플리조또', '캐비어카나페', '푸아그라', '금박스시',
  '랍스터테르미도르', '오마카세초밥', '와규스테이크', '송이전골',
  '전복스테이크', '킹크랩구이', '훈제연어카나페', '블랙트러플파스타',
  '사프란리조또', '백트러플오일파스타', '푸아그라버거',
  '캐비어블리니', '금박디저트', '트러플프라이', '랍스터비스크',
  '분자요리스프', '액체올리브', '구름빵', '거품수프',
  '꽃잎젤리', '황금카레', '무지개롤', '용과스무디',
  '매화주', '국화차디저트', '라벤더쿠키', '장미젤라또',
  '벌꿀금박떡', '신선한구슬요리', '활발한불꽃스테이크',
  '흘러라물회', '날아라솜사탕', '정체모를수프',
  '비밀의스테이크', '환상의카레', '전설의라멘', '신비의푸딩',
  '마스터셰프스페셜', '골드실버디너', '요리왕볶음밥',
  '드래곤롤', '피닉스치킨', '유니콘케이크',
  '갤럭시마카롱', '오로라칵테일', '무한리필스시',
];

// ─── 재료-요리 매핑을 위한 헬퍼 ───

// 주재료별 매핑
final Map<String, List<String>> mainIngredientMap = {
  'beef': ['소고기', '비프', '불고기', '갈비', '스테이크', '육회', '와규', '규동'],
  'chicken': ['닭', '치킨', '계', '삼계', '닭갈비', '찜닭', '로스트치킨'],
  'pork': ['돼지', '삼겹', '보쌈', '족발', '제육', '돈카츠', '동파육', '탕수육'],
  'lamb': ['양', '램', '양갈비', '양꼬치'],
  'duck': ['오리', '덕', '베이징덕'],
  'salmon': ['연어', '사몬'],
  'tuna': ['참치', '토로'],
  'cod': ['대구'],
  'shrimp': ['새우', '에비'],
  'crab': ['게', '크랩'],
  'lobster': ['랍스터'],
  'squid': ['오징어'],
  'octopus': ['문어', '낙지'],
  'clam': ['조개', '클램'],
  'rice': ['밥', '라이스', '리조또', '죽'],
  'noodle': ['면', '국수', '소바', '우동', '파스타', '라멘'],
  'wheat_flour': ['빵', '케이크', '쿠키', '머핀', '타르트', '파이', '만두'],
  'tofu': ['두부', '순두부'],
  'kimchi': ['김치'],
  'cheese': ['치즈'],
  'chocolate': ['초콜릿', '브라우니', '가나슈'],
  'cream': ['크림'],
  'tomato': ['토마토'],
  'mushroom': ['버섯', '송이', '트러플'],
  'egg': ['계란', '달걀', '에그', '오믈렛'],
};

// 조리법에 따른 도구 범위
Map<String, Map<String, List<int>>> cookingMethodTools = {
  '구이': {'fire': [6, 12, 9]},
  '볶음': {'fire': [4, 9, 7], 'knife': [5, 15, 10]},
  '찜': {'fire': [3, 8, 5], 'water': [50, 70, 60]},
  '탕': {'fire': [4, 9, 7], 'water': [70, 90, 80]},
  '조림': {'fire': [3, 7, 5], 'water': [30, 50, 40]},
  '튀김': {'fire': [6, 12, 9]},
  '회/생': {},
  '무침': {'knife': [5, 15, 10]},
  '전': {'fire': [4, 8, 6], 'knife': [3, 10, 7]},
  '국': {'fire': [3, 7, 5], 'water': [60, 80, 70]},
  '샐러드': {'knife': [8, 20, 14]},
  '수프': {'fire': [3, 7, 5], 'water': [50, 70, 60]},
  '파스타': {'fire': [4, 8, 6], 'water': [40, 60, 50]},
  '베이킹': {'fire': [5, 10, 8]},
  '디저트': {'fire': [2, 6, 4]},
  '음료': {'water': [40, 70, 55]},
};

// ─── 메인 생성 로직 ───

void main() {
  final allIngredients = <Map<String, dynamic>>[];
  final allRecipes = <Map<String, dynamic>>[];
  final ingredientIds = <String>{};

  // 1. 기본 재료 등록
  for (final ing in baseIngredients) {
    allIngredients.add(ing);
    ingredientIds.add(ing['id']);
  }

  // 2. tier 1 파생 재료 + 레시피
  int recipeCounter = 0;
  for (final d in tier1Derivations) {
    allIngredients.add({
      'id': d.id, 'name': d.name, 'type': 'derived',
      'icon': d.icon, 'isBase': false, 'tier': d.tier,
    });
    ingredientIds.add(d.id);

    allRecipes.add({
      'id': 'R${(recipeCounter++).toString().padLeft(5, '0')}',
      'name': d.name,
      'inputs': d.inputIds.map((id) => {'ingredientId': id}).toList(),
      'outputIngredientId': d.id,
      'difficulty': 1,
      'tier': 0,
      'category': '기본 조합',
    });
  }

  // 3. tier 2 파생 재료 + 레시피
  for (final d in tier2Derivations) {
    allIngredients.add({
      'id': d.id, 'name': d.name, 'type': 'derived',
      'icon': d.icon, 'isBase': false, 'tier': d.tier,
    });
    ingredientIds.add(d.id);

    final recipe = <String, dynamic>{
      'id': 'R${(recipeCounter++).toString().padLeft(5, '0')}',
      'name': d.name,
      'inputs': d.inputIds.map((id) => {'ingredientId': id}).toList(),
      'outputIngredientId': d.id,
      'difficulty': 2,
      'tier': 1,
      'category': '가공 재료',
    };
    if (d.knife != null) recipe['knife'] = {'min': d.knife![0], 'max': d.knife![1], 'optimal': d.knife![2]};
    if (d.water != null) recipe['water'] = {'min': d.water![0], 'max': d.water![1], 'optimal': d.water![2]};
    if (d.fire != null) recipe['fire'] = {'min': d.fire![0], 'max': d.fire![1], 'optimal': d.fire![2]};
    allRecipes.add(recipe);
  }

  // 4. 완성 요리 레시피 대량 생성
  final allDishLists = <String, List<String>>{
    '한식': koreanDishes,
    '일식': japaneseDishes,
    '양식': westernDishes,
    '중식': chineseDishes,
    '디저트': dessertDishes,
    '퓨전': fusionDishes,
    '스페셜': specialDishes,
  };

  // 사용 가능한 재료 ID 리스트
  final availableIngredients = ingredientIds.toList();

  // 기본 요리 (tier 2~3) 생성
  for (final entry in allDishLists.entries) {
    final category = entry.key;
    final dishes = entry.value;
    for (final dishName in dishes) {
      final recipe = _generateDishRecipe(
        id: 'R${(recipeCounter++).toString().padLeft(5, '0')}',
        name: dishName,
        category: category,
        availableIngredients: availableIngredients,
        tier: 2,
      );
      allRecipes.add(recipe);
      // 결과물을 재료로 등록
      final outputId = recipe['outputIngredientId'];
      if (!ingredientIds.contains(outputId)) {
        allIngredients.add({
          'id': outputId, 'name': dishName, 'type': 'derived',
          'icon': _getDishIcon(category), 'isBase': false, 'tier': 2,
        });
        ingredientIds.add(outputId);
        availableIngredients.add(outputId);
      }
    }
  }

  // 5. 변형 요리 대량 생성 (조리법 x 재료 조합)
  final variations = [
    '매콤한', '달콤한', '부드러운', '바삭한', '특제', '프리미엄',
    '고급', '수제', '전통', '퓨전', '모던', '클래식',
    '불맛', '숯불', '화덕', '저온', '고온', '훈제',
    '크리미', '스파이시', '허니', '갈릭', '트러플',
    '발사믹', '레몬', '유자', '매실', '참깨',
    '치즈', '버터', '크림치즈', '모짜렐라', '파르메산',
    '황금', '은빛', '무지개', '봄', '여름', '가을', '겨울',
    '시골', '도시', '바다', '산', '하늘',
  ];

  final baseDishNames = allDishLists.values.expand((x) => x).toList();
  for (final variation in variations) {
    for (int i = 0; i < baseDishNames.length && recipeCounter < 8500; i++) {
      final baseDish = baseDishNames[_rand.nextInt(baseDishNames.length)];
      final variantName = '$variation $baseDish';

      // 중복 방지
      if (allRecipes.any((r) => r['name'] == variantName)) continue;

      final baseCat = allDishLists.entries
          .firstWhere((e) => e.value.contains(baseDish), orElse: () => MapEntry('퓨전', []))
          .key;

      final recipe = _generateDishRecipe(
        id: 'R${(recipeCounter++).toString().padLeft(5, '0')}',
        name: variantName,
        category: baseCat,
        availableIngredients: availableIngredients,
        tier: 3,
        difficultyBoost: 1,
      );
      allRecipes.add(recipe);
      final outputId = recipe['outputIngredientId'];
      if (!ingredientIds.contains(outputId)) {
        allIngredients.add({
          'id': outputId, 'name': variantName, 'type': 'derived',
          'icon': _getDishIcon(baseCat), 'isBase': false, 'tier': 3,
        });
        ingredientIds.add(outputId);
        availableIngredients.add(outputId);
      }
    }
  }

  // 6. 연쇄 조합 고급 요리 생성 (tier 4~5)
  final upgradePrefix = [
    '완벽한', '극상의', '전설의', '신비의', '환상의',
    '마스터', '셰프스페셜', '시그니처', '그랑프리', '미슐랭',
  ];
  final existingDishIds = allRecipes.where((r) => (r['tier'] as int) >= 2)
      .map((r) => r['outputIngredientId'] as String).toList();

  for (final prefix in upgradePrefix) {
    for (int i = 0; i < existingDishIds.length && recipeCounter < 9800; i++) {
      final baseId = existingDishIds[_rand.nextInt(existingDishIds.length)];
      final baseIng = allIngredients.firstWhere((ig) => ig['id'] == baseId, orElse: () => <String, dynamic>{});
      if (baseIng.isEmpty) continue;

      final upgradeName = '$prefix ${baseIng['name']}';
      if (allRecipes.any((r) => r['name'] == upgradeName)) continue;

      final upgradeId = '${baseId}_${prefix.hashCode.abs() % 10000}';
      if (ingredientIds.contains(upgradeId)) continue;

      // 추가 재료 1~2개
      final extraInputs = <Map<String, dynamic>>[
        {'ingredientId': baseId},
      ];
      final extraCount = 1 + _rand.nextInt(2);
      for (int j = 0; j < extraCount; j++) {
        extraInputs.add({'ingredientId': availableIngredients[_rand.nextInt(availableIngredients.length)]});
      }

      final difficulty = 5 + _rand.nextInt(6);
      final recipe = <String, dynamic>{
        'id': 'R${(recipeCounter++).toString().padLeft(5, '0')}',
        'name': upgradeName,
        'inputs': extraInputs,
        'outputIngredientId': upgradeId,
        'difficulty': difficulty,
        'tier': 4,
        'category': '스페셜',
        'knife': {'min': 5 + _rand.nextInt(10), 'max': 20 + _rand.nextInt(30), 'optimal': 15 + _rand.nextInt(15)},
        'fire': {'min': 3 + _rand.nextInt(5), 'max': 8 + _rand.nextInt(8), 'optimal': 5 + _rand.nextInt(6)},
      };
      if (_rand.nextBool()) {
        recipe['water'] = {'min': 20 + _rand.nextInt(30), 'max': 50 + _rand.nextInt(40), 'optimal': 35 + _rand.nextInt(25)};
      }
      allRecipes.add(recipe);
      allIngredients.add({
        'id': upgradeId, 'name': upgradeName, 'type': 'derived',
        'icon': '⭐', 'isBase': false, 'tier': 4,
      });
      ingredientIds.add(upgradeId);
      availableIngredients.add(upgradeId);
    }
  }

  // 7. 나머지를 채워서 10,000개 맞추기
  int fillIndex = 0;
  while (recipeCounter < 10000) {
    final cat = ['한식', '일식', '양식', '중식', '디저트', '퓨전'][_rand.nextInt(6)];
    final fillName = '비밀레시피 #${++fillIndex}';
    final recipe = _generateDishRecipe(
      id: 'R${(recipeCounter++).toString().padLeft(5, '0')}',
      name: fillName,
      category: cat,
      availableIngredients: availableIngredients,
      tier: 3 + _rand.nextInt(2),
      difficultyBoost: _rand.nextInt(3),
    );
    allRecipes.add(recipe);
    final outputId = recipe['outputIngredientId'];
    if (!ingredientIds.contains(outputId)) {
      allIngredients.add({
        'id': outputId, 'name': fillName, 'type': 'derived',
        'icon': '🔮', 'isBase': false, 'tier': recipe['tier'],
      });
      ingredientIds.add(outputId);
      availableIngredients.add(outputId);
    }
  }

  // 출력
  final output = {
    'ingredients': allIngredients,
    'recipes': allRecipes,
    'stats': {
      'totalIngredients': allIngredients.length,
      'totalRecipes': allRecipes.length,
      'baseIngredients': baseIngredients.length,
      'tier1Derivations': tier1Derivations.length,
      'tier2Derivations': tier2Derivations.length,
    },
  };

  final file = File('assets/data/recipes.json');
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(output));
  print('Generated ${allRecipes.length} recipes, ${allIngredients.length} ingredients');
  print('Saved to assets/data/recipes.json');
}

Map<String, dynamic> _generateDishRecipe({
  required String id,
  required String name,
  required String category,
  required List<String> availableIngredients,
  required int tier,
  int difficultyBoost = 0,
}) {
  // 재료 2~4개 선택 (이름에서 주재료 추론)
  final inputs = <Map<String, dynamic>>[];
  final usedIds = <String>{};

  // 이름 기반 주재료 매칭
  for (final entry in mainIngredientMap.entries) {
    if (entry.value.any((keyword) => name.contains(keyword))) {
      if (!usedIds.contains(entry.key)) {
        inputs.add({'ingredientId': entry.key});
        usedIds.add(entry.key);
      }
      break;
    }
  }

  // 카테고리별 기본 재료 추가
  final catDefaults = <String, List<String>>{
    '한식': ['cooked_rice', 'sesame_oil', 'soy_sauce', 'garlic', 'green_onion', 'hot_paste', 'kimchi'],
    '일식': ['cooked_rice', 'soy_sauce', 'dashi', 'wasabi', 'ginger'],
    '양식': ['olive_oil', 'butter', 'garlic', 'onion', 'cream', 'cheese'],
    '중식': ['oil', 'garlic', 'ginger', 'soy_sauce', 'onion'],
    '디저트': ['sugar', 'butter', 'wheat_flour', 'cream', 'chocolate', 'vanilla', 'chicken_egg'],
    '퓨전': ['olive_oil', 'garlic', 'sesame_oil', 'soy_sauce'],
    '스페셜': ['truffle', 'saffron', 'gold_leaf', 'cream'],
  };

  final defaults = catDefaults[category] ?? catDefaults['퓨전']!;
  final shuffledDefaults = List<String>.from(defaults)..shuffle(_rand);

  final targetInputCount = 2 + _rand.nextInt(3); // 2~4
  for (final defId in shuffledDefaults) {
    if (inputs.length >= targetInputCount) break;
    if (!usedIds.contains(defId) && availableIngredients.contains(defId)) {
      inputs.add({'ingredientId': defId});
      usedIds.add(defId);
    }
  }

  // 아직 부족하면 랜덤 추가
  while (inputs.length < 2) {
    final randomId = availableIngredients[_rand.nextInt(availableIngredients.length)];
    if (!usedIds.contains(randomId)) {
      inputs.add({'ingredientId': randomId});
      usedIds.add(randomId);
    }
  }

  // 도구 범위 결정
  final methods = cookingMethodTools.keys.toList();
  String method;
  if (name.contains('구이') || name.contains('스테이크') || name.contains('그릴')) {
    method = '구이';
  } else if (name.contains('볶음') || name.contains('볶은')) {
    method = '볶음';
  } else if (name.contains('찜') || name.contains('찐')) {
    method = '찜';
  } else if (name.contains('탕') || name.contains('찌개') || name.contains('스튜')) {
    method = '탕';
  } else if (name.contains('조림')) {
    method = '조림';
  } else if (name.contains('튀김') || name.contains('카츠') || name.contains('프라이')) {
    method = '튀김';
  } else if (name.contains('회') || name.contains('사시미') || name.contains('타르타르')) {
    method = '회/생';
  } else if (name.contains('무침') || name.contains('나물')) {
    method = '무침';
  } else if (name.contains('전') || name.contains('파전') || name.contains('빈대떡')) {
    method = '전';
  } else if (name.contains('국') || name.contains('시루')) {
    method = '국';
  } else if (name.contains('샐러드')) {
    method = '샐러드';
  } else if (name.contains('수프') || name.contains('스프')) {
    method = '수프';
  } else if (name.contains('파스타') || name.contains('면') || name.contains('국수')) {
    method = '파스타';
  } else if (name.contains('케이크') || name.contains('빵') || name.contains('쿠키') || name.contains('타르트')) {
    method = '베이킹';
  } else if (name.contains('아이스') || name.contains('푸딩') || name.contains('젤리') || name.contains('무스')) {
    method = '디저트';
  } else if (name.contains('차') || name.contains('라떼') || name.contains('스무디') || name.contains('주스')) {
    method = '음료';
  } else {
    method = methods[_rand.nextInt(methods.length)];
  }

  final tools = cookingMethodTools[method]!;
  final recipe = <String, dynamic>{
    'id': id,
    'name': name,
    'inputs': inputs,
    'outputIngredientId': _nameToId(name),
    'difficulty': (2 + tier + difficultyBoost + _rand.nextInt(2)).clamp(1, 10),
    'tier': tier,
    'category': category,
  };

  if (tools.containsKey('knife')) {
    final k = tools['knife']!;
    recipe['knife'] = {'min': k[0], 'max': k[1], 'optimal': k[2]};
  }
  if (tools.containsKey('water')) {
    final w = tools['water']!;
    recipe['water'] = {'min': w[0], 'max': w[1], 'optimal': w[2]};
  }
  if (tools.containsKey('fire')) {
    final f = tools['fire']!;
    recipe['fire'] = {'min': f[0], 'max': f[1], 'optimal': f[2]};
  }

  return recipe;
}

String _nameToId(String name) {
  return name
      .replaceAll(' ', '_')
      .replaceAll(RegExp(r'[^a-zA-Z0-9가-힣_]'), '')
      .toLowerCase();
}

String _getDishIcon(String category) {
  switch (category) {
    case '한식': return '🍚';
    case '일식': return '🍣';
    case '양식': return '🍝';
    case '중식': return '🥡';
    case '디저트': return '🍰';
    case '퓨전': return '🍽️';
    case '스페셜': return '⭐';
    default: return '🍳';
  }
}
