import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 리더보드 항목
class LeaderboardEntry {
  final String playerName;
  final String dishName;
  final String grade;
  final double score;
  final DateTime date;

  const LeaderboardEntry({
    required this.playerName,
    required this.dishName,
    required this.grade,
    required this.score,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'playerName': playerName,
    'dishName': dishName,
    'grade': grade,
    'score': score,
    'date': date.toIso8601String(),
  };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
    playerName: json['playerName'] ?? '???',
    dishName: json['dishName'] ?? '???',
    grade: json['grade'] ?? 'F',
    score: (json['score'] as num).toDouble(),
    date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
  );
}

/// 로컬 리더보드 서비스
class Leaderboard {
  static const _key = 'leaderboard';
  static const _nameKey = 'player_name';
  static const maxEntries = 100;

  final List<LeaderboardEntry> _entries = [];
  String _playerName = '요리사';

  List<LeaderboardEntry> get entries => List.unmodifiable(_entries);
  String get playerName => _playerName;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _playerName = prefs.getString(_nameKey) ?? '요리사';

    final jsonStr = prefs.getString(_key);
    if (jsonStr != null) {
      final list = json.decode(jsonStr) as List;
      _entries.clear();
      _entries.addAll(list.map((e) => LeaderboardEntry.fromJson(e)));
      _entries.sort((a, b) => b.score.compareTo(a.score));
    }
  }

  Future<void> setPlayerName(String name) async {
    _playerName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
  }

  Future<int> addEntry({
    required String dishName,
    required String grade,
    required double score,
  }) async {
    final entry = LeaderboardEntry(
      playerName: _playerName,
      dishName: dishName,
      grade: grade,
      score: score,
      date: DateTime.now(),
    );

    _entries.add(entry);
    _entries.sort((a, b) => b.score.compareTo(a.score));

    // 최대 항목 수 제한
    if (_entries.length > maxEntries) {
      _entries.removeRange(maxEntries, _entries.length);
    }

    await _save();

    // 순위 반환
    return _entries.indexOf(entry) + 1;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(_entries.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonStr);
  }

  /// 상위 N개
  List<LeaderboardEntry> topN(int n) => _entries.take(n).toList();

  /// 현재 플레이어의 최고 기록
  LeaderboardEntry? get personalBest {
    try {
      return _entries.firstWhere((e) => e.playerName == _playerName);
    } catch (_) {
      return null;
    }
  }
}
