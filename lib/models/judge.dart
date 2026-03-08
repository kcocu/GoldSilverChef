/// 심사위원
class Judge {
  final String id;
  final String name;
  final String icon;
  final double tasteWeight;
  final double completionWeight;
  final double creativityWeight;
  final double visualWeight;
  final double gradeWeight;

  const Judge({
    required this.id,
    required this.name,
    required this.icon,
    required this.tasteWeight,
    required this.completionWeight,
    required this.creativityWeight,
    required this.visualWeight,
    required this.gradeWeight,
  });

  /// 돌고래: 맛(30%) + 완성도(40%) + 등급(30%)
  static const dolphin = Judge(
    id: 'dolphin',
    name: '돌고래',
    icon: '🐬',
    tasteWeight: 0.30,
    completionWeight: 0.40,
    creativityWeight: 0.0,
    visualWeight: 0.0,
    gradeWeight: 0.30,
  );

  /// 흑설탕: 맛(20%) + 창의성(30%) + 비주얼(20%) + 등급(30%)
  static const blackSugar = Judge(
    id: 'black_sugar',
    name: '흑설탕',
    icon: '🍬',
    tasteWeight: 0.20,
    completionWeight: 0.0,
    creativityWeight: 0.30,
    visualWeight: 0.20,
    gradeWeight: 0.30,
  );

  static const List<Judge> all = [dolphin, blackSugar];
}
