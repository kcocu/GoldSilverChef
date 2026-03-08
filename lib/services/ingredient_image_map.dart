/// 재료 ID → 이미지 경로 매핑
/// CC0 아이콘: OpenGameArt "Glitch food" set
class IngredientImageMap {
  static const _basePath = 'assets/images/ingredients';

  static const Map<String, String> _map = {
    // 기본 재료
    'grain': 'grain/wheat.png',
    'meat': 'meat/steak_raw.png',
    'seafood': 'meat/salmon_01.png',
    'egg': 'meat/egg.png',
    'dairy': 'dairy/cheese_01.png',
    'vegetable': 'vegetable/cabbage.png',
    'fruit': 'fruit/apple.png',
    'mushroom': 'misc/mushroom.png',
    'oil': 'condiment/oil_olive.png',
    'liquid': 'drink/milk_01.png',
    'sugar': 'spice/all_spice.png',
    'salt': 'spice/salt.png',
    'seasoning': 'spice/hot_pepper.png',

    // 육류 파생
    'beef': 'meat/steak_raw.png',
    'chicken': 'meat/fried_egg.png',
    'pork': 'meat/bacon_01.png',
    'lamb': 'meat/ribs_01.png',
    'duck': 'meat/braised_meat.png',
    'bone': 'meat/ribs_02.png',

    // 수산물 파생
    'salmon': 'meat/salmon_01.png',
    'tuna': 'meat/salmon_02.png',
    'shrimp': 'meat/oyster.png',
    'lobster': 'meat/oyster.png',
    'squid': 'meat/oyster.png',

    // 곡물 파생
    'rice': 'grain/rice_bowl.png',
    'wheat_flour': 'misc/flour.png',
    'corn': 'grain/corn.png',
    'potato': 'vegetable/potato.png',
    'bean': 'vegetable/bean.png',
    'oat': 'grain/oats.png',

    // 채소 파생
    'cabbage': 'vegetable/cabbage.png',
    'lettuce': 'vegetable/lettuce.png',
    'spinach': 'vegetable/spinach.png',
    'carrot': 'vegetable/carrot.png',
    'radish': 'vegetable/radish.png',
    'onion': 'vegetable/onion.png',
    'garlic': 'vegetable/garlic.png',
    'tomato': 'fruit/tomato.png',
    'pumpkin': 'vegetable/pumpkin.png',
    'cucumber': 'vegetable/cucumber.png',
    'pepper': 'spice/hot_pepper.png',
    'ginger': 'vegetable/ginger.png',

    // 과일 파생
    'apple': 'fruit/apple.png',
    'lemon': 'fruit/lemon.png',
    'orange': 'fruit/orange.png',
    'grape': 'fruit/grapes_01.png',
    'banana': 'fruit/banana.png',
    'strawberry': 'fruit/strawberry.png',
    'pineapple': 'fruit/pineapple.png',
    'coconut': 'fruit/guava_01.png',

    // 유제품 파생
    'butter': 'dairy/butter.png',
    'cheese': 'dairy/cheese_01.png',
    'cream': 'dairy/butter.png',

    // 가공
    'cooked_rice': 'grain/rice_steamed.png',
    'bread': 'misc/fried_bread.png',
    'fried_rice': 'grain/rice_fried.png',
    'steak_sauce': 'condiment/sauce_stock.png',
    'tomato_sauce': 'condiment/sauce_red.png',
    'cream_sauce': 'condiment/sauce_cheesy.png',
    'ketchup': 'condiment/sauce_ketchup.png',
    'mayo': 'condiment/sauce_mild.png',
    'pesto': 'condiment/sauce_secret.png',
    'tofu': 'misc/tofu_01.png',
    'noodle': 'pasta/fried_noodles.png',

    // 기타
    'honey': 'misc/honey.png',
    'chocolate': 'treat/carob-ish_treat.png',
    'nut': 'seed/seeds_pumpkin.png',
    'tea_leaf': 'herb/gandlevery.png',
    'herb': 'herb/rookswort.png',
    'vanilla': 'herb/silvertongue.png',
    'wine': 'drink/vodka.png',
    'beer': 'drink/beer.png',
    'coffee': 'drink/coffee.png',

    // 완성 요리
    'kimchi': 'vegetable/pickle.png',
    'broth': 'misc/stew.png',

    // 디저트
    'jam': 'misc/spread_cloudberry_jam.png',
    'candy': 'treat/birch_candy.png',
    'caramel': 'treat/carob-ish_treat.png',

    // 추가 완성 요리
    'pizza': 'misc/pizza_01.png',
    'burger': 'misc/sandwich_burger_01.png',
    'salad': 'misc/salad.png',
    'pancake': 'misc/pancakes.png',
    'waffle': 'misc/waffle.png',
    'taco': 'misc/taco.png',
    'burrito': 'misc/burrito.png',
    'omelet': 'misc/omelet_01.png',
    'pasta': 'pasta/spaghetti_01.png',
    'nachos': 'misc/nachos.png',
    'stew': 'misc/stew.png',
    'pie': 'dessert/pie.png',
  };

  /// 재료 ID로 이미지 경로 가져오기 (없으면 null)
  static String? getImagePath(String ingredientId) {
    final relativePath = _map[ingredientId];
    if (relativePath == null) return null;
    return '$_basePath/$relativePath';
  }

  /// 이미지가 있는지 확인
  static bool hasImage(String ingredientId) => _map.containsKey(ingredientId);
}
