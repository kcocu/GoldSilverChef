import 'package:flutter/material.dart';

class TutorialScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const TutorialScreen({super.key, this.onComplete});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = <_TutorialPage>[
    _TutorialPage(
      icon: '🍳',
      title: 'GoldSilver 요리사에 오신 걸 환영합니다!',
      description: '10,000가지 요리를 조합하고 심사위원에게 평가받는 요리 경연 게임입니다.',
    ),
    _TutorialPage(
      icon: '🧪',
      title: '재료 조합',
      description: '기본 24종의 재료를 조합하여 새로운 재료를 만들 수 있습니다.\n\n'
          '예: 육류 + 빨간가루 → 소고기\n'
          '     곡물 + 초록가루 + 신선한 구슬 → 콩\n\n'
          '중간 결과물은 다시 재료로 사용할 수 있습니다!',
    ),
    _TutorialPage(
      icon: '🔪',
      title: '칼질',
      description: '화면의 칼 버튼을 터치/클릭하면 칼질 횟수가 올라갑니다.\n\n'
          '레시피마다 최적의 칼질 횟수가 있으니 잘 조절하세요!',
    ),
    _TutorialPage(
      icon: '💧',
      title: '물 붓기',
      description: '물 영역을 드래그하면 물을 부을 수 있습니다.\n\n'
          '게이지는 표시되지 않으니 감으로 조절하세요!\n'
          '숙련도가 곧 실력입니다.',
    ),
    _TutorialPage(
      icon: '🔥',
      title: '불 조절',
      description: '불은 1단계(약불), 2단계(중불), 3단계(강불)로 나뉩니다.\n\n'
          '불을 켠 후 "가열 시작"을 누르면 시간이 흘러갑니다.\n'
          '불 단계 × 시간 = 최종 불 수치!',
    ),
    _TutorialPage(
      icon: '⭐',
      title: '품질 등급',
      description: '도구 수치의 정확도에 따라 품질이 결정됩니다.\n\n'
          'F → D → C → B → A → S → SS → SS+\n\n'
          '중간 재료의 품질도 최종 결과에 영향을 줍니다!',
    ),
    _TutorialPage(
      icon: '🐬',
      title: '심사위원',
      description: '돌고래 🐬: 맛 + 완성도 + 등급을 중시\n'
          '흑설탕 🍬: 맛 + 창의성 + 비주얼 + 등급을 중시\n\n'
          '두 심사위원의 점수 평균이 최종 점수입니다.',
    ),
    _TutorialPage(
      icon: '🏆',
      title: '스토리 모드',
      description: '100명의 요리사 중 최후의 1인이 되세요!\n\n'
          '8단계를 거치며 탈락자가 생깁니다.\n'
          '마지막 결승에서는 심사위원 만장일치가 필요합니다!',
    ),
    _TutorialPage(
      icon: '📖',
      title: '레시피북',
      description: '한 번 만든 요리는 레시피북에 자동 기록됩니다.\n'
          '즐겨찾기로 자주 쓰는 레시피를 빠르게 찾을 수 있어요.\n\n'
          '10,000개 레시피를 모두 발견해보세요!',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8E1), Color(0xFFFFE0B2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 건너뛰기 버튼
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('건너뛰기', style: TextStyle(color: Color(0xFF8D6E63))),
                ),
              ),

              // 페이지 내용
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(page.icon, style: const TextStyle(fontSize: 80)),
                          const SizedBox(height: 24),
                          Text(
                            page.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5D4037),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            page.description,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Color(0xFF6D4C41),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // 인디케이터
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  return Container(
                    width: i == _currentPage ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? const Color(0xFFE65100)
                          : const Color(0xFFBCAAA4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              // 다음/시작 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLast ? _finish : _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      isLast ? '요리 시작!' : '다음',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _finish() {
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.pop(context);
    }
  }
}

class _TutorialPage {
  final String icon;
  final String title;
  final String description;

  const _TutorialPage({
    required this.icon,
    required this.title,
    required this.description,
  });
}
