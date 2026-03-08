import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/game_state.dart';
import 'cooking_screen.dart';
import 'judging_screen.dart';

class StoryModeScreen extends StatefulWidget {
  const StoryModeScreen({super.key});

  @override
  State<StoryModeScreen> createState() => _StoryModeScreenState();
}

class _StoryModeScreenState extends State<StoryModeScreen> {
  final StoryProgress _progress = StoryProgress();
  final _random = Random();
  List<NpcChef> _npcs = [];
  String? _currentTheme;
  bool _stageComplete = false;
  String _stageResultMessage = '';
  int _playerRank = 0;

  @override
  void initState() {
    super.initState();
    _generateNpcs();
    _generateTheme();
  }

  void _generateNpcs() {
    final stage = _progress.currentStage;
    final count = stage.totalParticipants - 1;
    final baseSkill = stage.index * 0.08; // 단계 높아질수록 스킬 상승

    _npcs = List.generate(count, (i) {
      final skill = (baseSkill + _random.nextDouble() * 0.5).clamp(0.0, 0.95);
      return NpcChef(
        id: 'npc_$i',
        name: _npcNames[i % _npcNames.length],
        skillLevel: skill,
      );
    });
  }

  void _generateTheme() {
    final state = context.read<GameState>();
    // 주제 재료 중 tier 1짜리 랜덤 선택
    final tier1 = state.engine.allIngredients.where((i) => i.tier == 1).toList();
    if (tier1.isNotEmpty) {
      _currentTheme = tier1[_random.nextInt(tier1.length)].id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stage = _progress.currentStage;

    return Scaffold(
      appBar: AppBar(
        title: Text(stage.title),
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFFFFF8E1),
        child: _stageComplete ? _buildStageResult() : _buildStageInfo(),
      ),
    );
  }

  Widget _buildStageInfo() {
    final stage = _progress.currentStage;
    final themeName = _currentTheme != null
        ? context.read<GameState>().engine.getIngredient(_currentTheme!)?.name ?? '?'
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 단계 정보 카드
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    stage.title,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stage.description,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _infoChip('참가자', '${stage.totalParticipants}명'),
                      _infoChip('생존', '${stage.survivors}명'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 주제 표시
          if (stage != StoryStage.stage6 &&
              stage != StoryStage.stage8 &&
              themeName != null)
            Card(
              color: const Color(0xFFE3F2FD),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('오늘의 주제', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      themeName,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

          if (stage == StoryStage.stage6 || stage == StoryStage.stage8)
            const Card(
              color: Color(0xFFFCE4EC),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '자유 주제! 최고의 요리를 보여주세요!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          const SizedBox(height: 24),

          // 요리 시작 버튼
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push<JudgingResult>(
                context,
                MaterialPageRoute(
                  builder: (_) => CookingScreen(
                    requiredTheme: _currentTheme,
                  ),
                ),
              );
              if (result != null && mounted) {
                _evaluateStage(result);
              }
            },
            icon: const Icon(Icons.restaurant, size: 28),
            label: const Text('요리 시작!', style: TextStyle(fontSize: 20)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageResult() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            _playerRank <= (_progress.currentStage.survivors)
                ? '🎉' : '😢',
            style: const TextStyle(fontSize: 80),
          ),
          const SizedBox(height: 16),
          Text(
            _stageResultMessage,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '당신의 순위: $_playerRank/${_progress.currentStage.totalParticipants}',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 40),

          if (_playerRank <= _progress.currentStage.survivors)
            ElevatedButton.icon(
              onPressed: _advanceStage,
              icon: const Icon(Icons.arrow_forward),
              label: Text(
                _progress.nextStage != null ? '다음 단계로' : '축하합니다!',
                style: const TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.home),
              label: const Text('메인으로', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
        ],
      ),
    );
  }

  void _evaluateStage(JudgingResult result) {
    // NPC들의 점수 생성
    final npcScores = _npcs.map((npc) {
      final accuracy = npc.getAccuracy(_random.nextDouble());
      return accuracy * 100;
    }).toList()..sort((a, b) => b.compareTo(a));

    final playerScore = result.finalScore;

    // 순위 계산
    int rank = 1;
    for (final npcScore in npcScores) {
      if (npcScore > playerScore) rank++;
    }
    _playerRank = rank;

    final stage = _progress.currentStage;
    final passed = rank <= stage.survivors;

    // 4단계 특수 처리
    if (stage == StoryStage.stage4) {
      if (rank == 1) {
        _progress.skipToStage6 = true;
        _stageResultMessage = '🌟 1등! 6단계로 직행합니다!';
      } else if (rank >= stage.totalParticipants) {
        _stageResultMessage = '탈락했습니다...';
      } else {
        _stageResultMessage = '5단계로 진출합니다!';
      }
    }
    // 6단계 특수 처리
    else if (stage == StoryStage.stage6) {
      if (rank == 1) {
        _progress.skipToStage8 = true;
        _stageResultMessage = '🌟 1등! 결승으로 직행합니다!';
      } else {
        _stageResultMessage = '7단계 요리 지옥으로...';
      }
    }
    // 8단계 만장일치
    else if (stage == StoryStage.stage8) {
      final unanimous = result.scores.every((s) => s.totalScore >= 70);
      if (unanimous && rank == 1) {
        _stageResultMessage = '🏆 만장일치 우승! GoldSilver 마스터 셰프!';
      } else {
        _stageResultMessage = '만장일치를 받지 못했습니다. 재도전!';
        // 사용한 주재료 기록
        setState(() => _stageComplete = false);
        return;
      }
    } else {
      _stageResultMessage = passed ? '통과!' : '탈락했습니다...';
    }

    setState(() => _stageComplete = true);
  }

  void _advanceStage() {
    final next = _progress.nextStage;
    if (next == null) {
      // 게임 클리어
      Navigator.pop(context);
      return;
    }
    setState(() {
      _progress.currentStage = next;
      _stageComplete = false;
      _generateNpcs();
    });
    _generateTheme();
  }

  Widget _infoChip(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  static const _npcNames = [
    '김요리', '박셰프', '이맛있', '최불꽃', '정칼날',
    '한물결', '오향기', '신신선', '유달인', '장고수',
    '문맛집', '서바삭', '조뜨끈', '임촉촉', '배달콤',
    '안매콤', '홍짭짤', '송쫄깃', '권고소', '민향긋',
    '윤부드', '허크런', '마스터', '천재쉐', '골드팬',
    '실버나', '다이아', '루비셰', '사파이', '에메랄',
    '스파이', '허브왕', '불의달', '물의선', '칼의성',
    '프라임', '울트라', '하이퍼', '메가셰', '기가쿡',
    '테라요', '페타셰', '엑사쿡', '제타요', '요타셰',
    '누들킹', '빵의신', '디저트', '그릴러', '스모커',
    '피클러', '소스왕', '양념달', '뚝배기', '솥밥왕',
    '회의달', '초밥왕', '라멘신', '커리킹', '파스타',
    '피자신', '타코왕', '스시맨', '덮밥킹', '볶음신',
    '찜의달', '구이왕', '튀김신', '조림달', '전의신',
    '국물왕', '탕의달', '죽마스', '면의신', '밥의달',
    '떡의왕', '과자신', '빵의달', '케이크', '아이스',
    '초코신', '캔디왕', '젤리달', '푸딩신', '무스왕',
    '타르트', '파이달', '쿠키신', '머핀왕', '도넛달',
    '크레페', '와플신', '팬케이', '베이글', '시나몬',
    '바닐라', '카라멜', '메이플', '허니왕', '민트달',
  ];
}
