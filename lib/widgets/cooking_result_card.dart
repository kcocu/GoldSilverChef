import 'package:flutter/material.dart';
import '../models/models.dart';

class CookingResultCard extends StatelessWidget {
  final CookingResult result;

  const CookingResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('🍽️', style: TextStyle(fontSize: 50)),
            const SizedBox(height: 8),
            Text(
              result.recipeName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // 품질 등급
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _gradeColor(result.grade),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _gradeColor(result.grade).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '품질 ${result.grade.label}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 정확도 바
            _buildAccuracyRow('🔪 칼질', result.knifeValue, result.knifeAccuracy),
            _buildAccuracyRow('💧 물', result.waterValue, result.waterAccuracy),
            _buildAccuracyRow('🔥 불', result.fireValue, result.fireAccuracy),
            const Divider(),
            _buildAccuracyRow('📊 종합', null, result.overallAccuracy),

            if (result.intermediateResults.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '중간 재료 ${result.intermediateResults.length}개 사용',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyRow(String label, int? value, double accuracy) {
    final color = accuracy >= 0.8
        ? Colors.green
        : accuracy >= 0.5
            ? Colors.orange
            : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(label, style: const TextStyle(fontSize: 13))),
          if (value != null)
            SizedBox(width: 40, child: Text('$value', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13))),
          if (value == null) const SizedBox(width: 40),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: accuracy,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 45,
            child: Text(
              '${(accuracy * 100).round()}%',
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
            ),
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
}
