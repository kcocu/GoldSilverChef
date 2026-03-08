import 'package:flutter/material.dart';
import '../models/models.dart';

class JudgingScreen extends StatefulWidget {
  final JudgingResult result;

  const JudgingScreen({super.key, required this.result});

  @override
  State<JudgingScreen> createState() => _JudgingScreenState();
}

class _JudgingScreenState extends State<JudgingScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  int _revealedJudge = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _revealScores();
  }

  Future<void> _revealScores() async {
    await Future.delayed(const Duration(milliseconds: 500));
    for (int i = 0; i < widget.result.scores.length; i++) {
      if (!mounted) return;
      setState(() => _revealedJudge = i);
      _controller.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 1200));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;

    return Scaffold(
      appBar: AppBar(
        title: const Text('심사 결과'),
        backgroundColor: const Color(0xFF5D4037),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFFFFF8E1),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 요리 정보
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        r.cookingResult.recipeName,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _gradeColor(r.cookingResult.grade),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '품질 ${r.cookingResult.grade.label}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 심사위원별 점수
              ...List.generate(r.scores.length, (i) {
                if (i > _revealedJudge) {
                  return Card(
                    child: ListTile(
                      leading: const Text('❓', style: TextStyle(fontSize: 30)),
                      title: const Text('심사 중...'),
                    ),
                  );
                }

                final score = r.scores[i];
                final isBlackSugar = score.judgeName == '흑설탕';

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isBlackSugar ? '🍬' : '🐬',
                              style: const TextStyle(fontSize: 30),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              score.judgeName,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _scoreColor(score.totalScore),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${score.totalScore.toStringAsFixed(1)}점',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildScoreBar('맛', score.taste, 100),
                        if (!isBlackSugar)
                          _buildScoreBar('완성도', score.completion, 100),
                        if (isBlackSugar) ...[
                          _buildScoreBar('창의성', score.creativity, 100),
                          _buildScoreBar('비주얼', score.visual, 100),
                        ],
                        _buildScoreBar('등급', score.gradeScore, 100),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '"${score.comment}"',
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),

              // 최종 점수
              if (_revealedJudge >= r.scores.length - 1)
                Card(
                  color: const Color(0xFF5D4037),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          '최종 점수',
                          style: TextStyle(fontSize: 18, color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          r.finalScore.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D4037),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('돌아가기', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBar(String label, double value, double max) {
    final ratio = (value / max).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: const TextStyle(fontSize: 13))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 12,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(_barColor(ratio)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(value.toStringAsFixed(0), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Color _gradeColor(QualityGrade grade) {
    switch (grade) {
      case QualityGrade.F: return Colors.grey;
      case QualityGrade.D: return Colors.brown;
      case QualityGrade.C: return Colors.green;
      case QualityGrade.B: return Colors.blue;
      case QualityGrade.A: return Colors.purple;
      case QualityGrade.S: return Colors.orange;
      case QualityGrade.SS: return Colors.red;
      case QualityGrade.SSPlus: return const Color(0xFFFFD700);
    }
  }

  Color _scoreColor(double score) {
    if (score >= 80) return Colors.red;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.blue;
    return Colors.grey;
  }

  Color _barColor(double ratio) {
    if (ratio >= 0.8) return Colors.red;
    if (ratio >= 0.6) return Colors.orange;
    if (ratio >= 0.4) return Colors.blue;
    return Colors.grey;
  }
}
