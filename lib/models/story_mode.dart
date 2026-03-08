/// 스토리 모드 단계
enum StoryStage {
  stage1, // 100→40, 개인전 점수 컷
  stage2, // 40→20, 1:1
  stage3, // 20→14, 팀전
  stage4, // 14→10, 개인 분기
  stage5, // 10→5, 1:1
  stage6, // 7명, 자유 분기
  stage7, // 6→1, 요리 지옥
  stage8, // 2명, 결승
}

extension StoryStageExt on StoryStage {
  String get title {
    switch (this) {
      case StoryStage.stage1: return '1단계: 예선';
      case StoryStage.stage2: return '2단계: 1:1 대결';
      case StoryStage.stage3: return '3단계: 팀 대결';
      case StoryStage.stage4: return '4단계: 서바이벌';
      case StoryStage.stage5: return '5단계: 재대결';
      case StoryStage.stage6: return '6단계: 자유 요리';
      case StoryStage.stage7: return '7단계: 요리 지옥';
      case StoryStage.stage8: return '8단계: 결승전';
    }
  }

  String get description {
    switch (this) {
      case StoryStage.stage1: return '일정 점수 이상을 받아 예선을 통과하세요!';
      case StoryStage.stage2: return '상대 요리사와 1:1로 겨루세요!';
      case StoryStage.stage3: return '팀 대결! 상위 4명 안에 들면 통과!';
      case StoryStage.stage4: return '1등은 6단계 직행, 꼴지는 탈락!';
      case StoryStage.stage5: return '다시 한번 1:1 대결!';
      case StoryStage.stage6: return '자유 주제! 최고의 요리를 보여주세요!';
      case StoryStage.stage7: return '요리 지옥! 꼴지만 탈락, 5판 생존!';
      case StoryStage.stage8: return '결승! 심사위원 만장일치를 받아야 합니다!';
    }
  }

  int get totalParticipants {
    switch (this) {
      case StoryStage.stage1: return 100;
      case StoryStage.stage2: return 40;
      case StoryStage.stage3: return 20;
      case StoryStage.stage4: return 14;
      case StoryStage.stage5: return 10;
      case StoryStage.stage6: return 7;
      case StoryStage.stage7: return 6;
      case StoryStage.stage8: return 2;
    }
  }

  int get survivors {
    switch (this) {
      case StoryStage.stage1: return 40;
      case StoryStage.stage2: return 20;
      case StoryStage.stage3: return 14;
      case StoryStage.stage4: return 10;
      case StoryStage.stage5: return 5;
      case StoryStage.stage6: return 7; // 분기
      case StoryStage.stage7: return 1;
      case StoryStage.stage8: return 1;
    }
  }
}

/// 스토리 진행 상태
class StoryProgress {
  StoryStage currentStage;
  int currentRound; // 7단계 요리 지옥 라운드용
  bool skipToStage6; // 4단계 1등 → 6단계 직행
  bool skipToStage8; // 6단계 1등 → 8단계 직행
  Set<String> usedMainIngredients; // 8단계 사용한 주재료

  StoryProgress({
    this.currentStage = StoryStage.stage1,
    this.currentRound = 0,
    this.skipToStage6 = false,
    this.skipToStage8 = false,
    Set<String>? usedMainIngredients,
  }) : usedMainIngredients = usedMainIngredients ?? {};

  StoryStage? get nextStage {
    switch (currentStage) {
      case StoryStage.stage1: return StoryStage.stage2;
      case StoryStage.stage2: return StoryStage.stage3;
      case StoryStage.stage3: return StoryStage.stage4;
      case StoryStage.stage4:
        return skipToStage6 ? StoryStage.stage6 : StoryStage.stage5;
      case StoryStage.stage5: return StoryStage.stage6;
      case StoryStage.stage6:
        return skipToStage8 ? StoryStage.stage8 : StoryStage.stage7;
      case StoryStage.stage7: return StoryStage.stage8;
      case StoryStage.stage8: return null; // 게임 끝
    }
  }
}
