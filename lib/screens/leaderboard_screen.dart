import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_state.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = context.read<GameState>();
    _nameController.text = state.leaderboard.playerName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final entries = state.leaderboard.topN(50);

    return Scaffold(
      appBar: AppBar(
        title: const Text('리더보드'),
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _showNameDialog,
            tooltip: '이름 변경',
          ),
        ],
      ),
      body: entries.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🏆', style: TextStyle(fontSize: 60)),
                  SizedBox(height: 16),
                  Text('아직 기록이 없습니다', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  Text('자유 경연에서 요리를 만들어보세요!', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final rank = index + 1;
                final isMe = entry.playerName == state.leaderboard.playerName;

                return Card(
                  color: isMe ? const Color(0xFFFFF3E0) : null,
                  child: ListTile(
                    leading: SizedBox(
                      width: 40,
                      child: Center(
                        child: rank <= 3
                            ? Text(
                                ['🥇', '🥈', '🥉'][rank - 1],
                                style: const TextStyle(fontSize: 24),
                              )
                            : Text(
                                '#$rank',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                    title: Text(
                      entry.dishName,
                      style: TextStyle(
                        fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      '${entry.playerName} | ${entry.grade} | ${_formatDate(entry.date)}',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _scoreColor(entry.score),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        entry.score.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showNameDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이름 변경'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: '닉네임을 입력하세요',
            border: OutlineInputBorder(),
          ),
          maxLength: 10,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _nameController.text.trim();
              if (name.isNotEmpty) {
                context.read<GameState>().leaderboard.setPlayerName(name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  Color _scoreColor(double score) {
    if (score >= 80) return Colors.red;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.blue;
    return Colors.grey;
  }
}
