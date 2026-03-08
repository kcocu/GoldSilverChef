/// 재료 타입
enum IngredientType {
  // 현실 계열
  grain,      // 곡물
  meat,       // 육류
  seafood,    // 수산물
  egg,        // 알
  dairy,      // 유제품
  vegetable,  // 채소
  fruit,      // 과일
  mushroom,   // 버섯
  oil,        // 기름
  liquid,     // 액체
  sugar,      // 설탕
  salt,       // 소금
  seasoning,  // 양념

  // 추상 계열
  redPowder,      // 빨간가루
  bluePowder,     // 파란가루
  greenPowder,    // 초록가루
  purplePowder,   // 보라가루
  yellowPowder,   // 노란가루
  hourglass,      // 모래시계
  freshOrb,       // 신선한 구슬
  livelyOrb,      // 활발한 구슬
  flyOrb,         // 날아라 구슬
  flowOrb,        // 흘러라 구슬
  mysteryPowder,  // 정체모를 가루

  // 파생 재료
  derived,
}

class Ingredient {
  final String id;
  final String name;
  final IngredientType type;
  final String icon;
  final bool isBase; // 기본 24종 여부
  final String? description;
  final int tier; // 0=기본, 1=1차 파생, 2=2차 파생...

  const Ingredient({
    required this.id,
    required this.name,
    required this.type,
    this.icon = '🧂',
    this.isBase = false,
    this.description,
    this.tier = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'icon': icon,
    'isBase': isBase,
    'description': description,
    'tier': tier,
  };

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    IngredientType type;
    try {
      type = IngredientType.values.byName(json['type']);
    } catch (_) {
      type = IngredientType.derived;
    }
    return Ingredient(
      id: json['id'],
      name: json['name'],
      type: type,
      icon: json['icon'] ?? '🧂',
      isBase: json['isBase'] ?? false,
      description: json['description'],
      tier: json['tier'] ?? 0,
    );
  }

  @override
  bool operator ==(Object other) => other is Ingredient && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}
