# GoldSilverChef 코드 리뷰 및 수정 기록

**일시:** 2026-03-08
**범위:** 전체 코드베이스 (29 Dart 파일, ~5,900줄)
**리뷰어:** 시니어 엔지니어 인수인계 관점

---

## 프로젝트 현황

| 항목 | 내용 |
|------|------|
| 프레임워크 | Flutter (Dart), 웹+모바일 |
| 상태 관리 | Provider (ChangeNotifier) |
| 로컬 저장 | SharedPreferences |
| 데이터 | recipes.json (6.7MB, 10,000+ 레시피) |
| 배포 | GitHub Pages (GitHub Actions CI/CD) |
| 테스트 | 없음 (빈 widget_test.dart 1개) |

---

## 수정 완료 항목

### 버그 수정 (BUG)

#### BUG-1. 새 요리 발견 알림 항상 표시 (로직 반전)
- **파일:** `cooking_screen.dart:283-299`
- **원인:** `cook()` 내부에서 `recipeBook.discover()`를 호출한 뒤 결과 반환. 이후 `isDiscovered()` 체크 시 항상 true.
- **수정:** cook() 호출 전에 `discovered` 스냅샷을 캡처하여 비교.

#### BUG-2. 빈 allRecipes에서 firstWhere 크래시
- **파일:** `game_state.dart:229-231, 259-262`
- **원인:** `orElse: () => engine.allRecipes.first` — allRecipes 비어있으면 NoSuchElementException
- **수정:** `cast<Recipe?>().firstWhere(..., orElse: () => null)` + null 체크

#### BUG-3. DataLoader 예외 처리 전무
- **파일:** `data_loader.dart:9-14`
- **원인:** rootBundle.loadString, json.decode, 키 캐스팅 모두 무방비
- **수정:** 단계별 try-catch + 구체적 한글 에러 메시지 + 필수 키 검증

#### BUG-4. 중간 결과(intermediateResults) 다음 조리에 오염
- **파일:** `game_state.dart:98`
- **원인:** cook() 시작 시 이전 결과가 있는데 useResultAsIngredient()를 거치지 않으면 _intermediateResults가 잔류
- **수정:** cook() 진입 시 `_lastResult != null`이면 `_intermediateResults.clear()`

---

### 중요 개선 (IMP)

#### IMP-1. 비동기 저장 fire-and-forget 에러 로깅
- **파일:** `recipe_book.dart:87-92`
- **수정:** `_save()`에 try-catch + `debugPrint` 에러 로깅

#### IMP-2. BuildContext async gap 안전 처리
- **파일:** `cooking_screen.dart:302-318`
- **수정:** `await Navigator.push()` 전 `mounted` 체크, `widget.requiredTheme` 접근을 로컬 변수로 캡처

#### IMP-3. CookingResult.toJson() 누락 필드
- **파일:** `cooking_result.dart:35-47`
- **수정:** `comment`, `intermediateResults` 직렬화 추가

#### IMP-4. Ingredient enum 파싱 에러 핸들링
- **파일:** `ingredient.dart:67`
- **수정:** `IngredientType.values.byName()` try-catch + `IngredientType.derived` 폴백

---

### 리팩토링 (REF)

#### REF-3. 등급 색상 매핑 중복 통합
- **파일:** `recipe.dart`, `cooking_result_card.dart`, `ingredient_picker.dart`, `recipe_book_screen.dart`
- **원인:** 동일한 등급→색상 switch 문이 3곳에 중복
- **수정:** `QualityGrade.color` getter + `QualityGrade.colorFromLabel()` 정적 메서드로 중앙 집중화. 3곳의 중복 메서드 제거.

#### REF-4. 재료 검색 디바운스
- **파일:** `ingredient_picker.dart:227-230`
- **원인:** 매 키 입력마다 setState + 캐시 무효화 → 1000+ 재료 GridView 리빌드
- **수정:** 300ms Timer 디바운스 + dispose에서 cancel

---

### 사소한 정리 (MINOR)

| # | 파일 | 내용 |
|---|------|------|
| 1 | `story_mode_screen.dart` | `dispose()` 메서드 추가 |
| 3 | `story_mode_screen.dart` | 미사용 `import 'judging_screen.dart'` 제거 |
| 4 | `judging_engine.dart` | 미사용 `_random` 필드 + `import 'dart:math'` 제거 |
| 5 | `procedural_recipe.dart` | 랜덤 시드 10초→1초 단위 세분화 |

---

## 미수정 사항 (현재 불필요)

| 항목 | 내용 | 판단 근거 |
|------|------|----------|
| REF-1 | GameState 책임 분리 (305줄) | 현재 규모에서 복잡도 적정 |
| REF-2 | IngredientPicker 파일 분리 (767줄) | 내부 위젯이 외부에서 사용되지 않음 |
| 테스트 | 유닛/위젯 테스트 전무 | 기능 안정화 후 추가 권장 |
| AudioService | 싱글톤 dispose 미호출 | Flutter 앱 생명주기상 실질적 문제 없음 |

---

## 수정 파일 목록 (13개)

```
lib/models/cooking_result.dart       - IMP-3: toJson 필드 추가
lib/models/ingredient.dart           - IMP-4: enum 파싱 안전 처리
lib/models/recipe.dart               - REF-3: QualityGrade.color 추가
lib/screens/cooking_screen.dart      - BUG-1, IMP-2
lib/screens/recipe_book_screen.dart  - REF-3: 중복 색상 제거
lib/screens/story_mode_screen.dart   - MINOR-1,3: dispose, import 정리
lib/services/data_loader.dart        - BUG-3: 예외 처리
lib/services/game_state.dart         - BUG-2,4: 크래시 방지, 오염 방지
lib/services/judging_engine.dart     - MINOR-4: 미사용 필드 제거
lib/services/procedural_recipe.dart  - MINOR-5: 랜덤 시드 개선
lib/services/recipe_book.dart        - IMP-1: 저장 에러 로깅
lib/widgets/cooking_result_card.dart - REF-3: 중복 색상 제거
lib/widgets/ingredient_picker.dart   - REF-3,4: 색상 통합, 디바운스
```

---

## 권장 테스트 (향후)

| 테스트 | 대상 | 유형 |
|--------|------|------|
| cook() 후 새 레시피 발견 여부 판별 | BUG-1 | Unit |
| 빈 allRecipes에서 requestJudging() | BUG-2 | Unit |
| 잘못된 JSON으로 DataLoader.loadAll() | BUG-3 | Unit |
| 연쇄 조합 없이 2번 cook() 시 intermediateResults | BUG-4 | Unit |
| ProceduralRecipeEngine 비밀 레시피 트리거 | 절차적 엔진 | Unit |
| QualityCalculator 경계값 (accuracy 0, 1) | 품질 계산 | Unit |
| 레시피북 저장/로드 사이클 | IMP-1 | Integration |
