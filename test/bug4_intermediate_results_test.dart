import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldsilver_chef/models/models.dart';
import 'package:goldsilver_chef/services/game_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// BUG-4: 연쇄 조합 없이 2번 연속 cook() 시 intermediateResults 영향 없음
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  group('intermediateResults 오염 방지', () {
    late GameState state;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      state = GameState();
      state.engine.loadIngredients([
        const Ingredient(id: 'meat', name: '고기', type: IngredientType.meat, isBase: true),
        const Ingredient(id: 'salt', name: '소금', type: IngredientType.salt, isBase: true),
        const Ingredient(id: 'grain', name: '곡물', type: IngredientType.grain, isBase: true),
      ]);
      state.engine.loadRecipes([]);
    });

    test('첫 cook 후 intermediateResults는 비어있음', () {
      state.addIngredient('meat');
      state.cook();
      expect(state.lastResult, isNotNull);
      expect(state.lastResult!.intermediateResults, isEmpty);
    });

    test('useResultAsIngredient 없이 두 번째 cook 시 intermediateResults 비어있음', () {
      // 첫 번째 조리
      state.addIngredient('meat');
      state.cook();
      final firstResult = state.lastResult!;
      expect(firstResult.intermediateResults, isEmpty);

      // 재료 추가하고 바로 두 번째 조리 (useResultAsIngredient 미사용)
      state.addIngredient('salt');
      final secondResult = state.cook();
      // intermediateResults가 오염되지 않아야 함
      expect(secondResult.intermediateResults, isEmpty);
    });

    test('useResultAsIngredient 후 cook 시 intermediateResults에 이전 결과 포함', () {
      // 첫 번째 조리
      state.addIngredient('meat');
      state.cook();

      // 결과를 재료로 사용
      state.useResultAsIngredient();
      expect(state.intermediateResults.length, equals(1));

      // 재료 추가 후 두 번째 조리
      state.addIngredient('salt');
      final secondResult = state.cook();
      // useResultAsIngredient를 거쳤으므로 중간 결과 반영됨
      // (cook()에서 _lastResult가 null이므로 clear 안 됨)
      expect(state.intermediateResults.length, equals(1));
    });

    test('resetCooking 후 intermediateResults 비어있음', () {
      state.addIngredient('meat');
      state.cook();
      state.useResultAsIngredient();
      expect(state.intermediateResults.length, equals(1));

      state.resetCooking();
      expect(state.intermediateResults, isEmpty);
    });

    test('resetAfterJudging 후 intermediateResults 비어있음', () {
      state.addIngredient('meat');
      state.cook();
      state.useResultAsIngredient();
      state.addIngredient('salt');
      state.cook();
      state.requestJudging();

      state.resetAfterJudging();
      expect(state.intermediateResults, isEmpty);
      expect(state.lastResult, isNull);
    });
  });
}
