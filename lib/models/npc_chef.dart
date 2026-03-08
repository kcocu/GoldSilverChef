/// NPC 요리사
class NpcChef {
  final String id;
  final String name;
  final double skillLevel; // 0.0 ~ 1.0
  final String icon;

  const NpcChef({
    required this.id,
    required this.name,
    required this.skillLevel,
    this.icon = '👨‍🍳',
  });

  /// NPC 도구 정확도 (실력 기반 + 랜덤 변동)
  double getAccuracy(double randomFactor) {
    // 기본 정확도 = 실력 * 0.7 + 랜덤 * 0.3
    return (skillLevel * 0.7 + randomFactor * 0.3).clamp(0.0, 1.0);
  }
}
