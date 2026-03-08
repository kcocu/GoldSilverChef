import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_state.dart';

/// 조리 도구 패널 — 칼, 물, 불 조작
class CookingTools extends StatefulWidget {
  final int knifeCount;
  final double waterAmount;
  final int fireLevel;
  final bool isCooking;
  final double cookingTime;
  final VoidCallback onChop;
  final Function(double) onWaterChange;
  final Function(int) onFireChange;
  final Function(GameState) onStartCooking;
  final VoidCallback onStopCooking;

  const CookingTools({
    super.key,
    required this.knifeCount,
    required this.waterAmount,
    required this.fireLevel,
    required this.isCooking,
    required this.cookingTime,
    required this.onChop,
    required this.onWaterChange,
    required this.onFireChange,
    required this.onStartCooking,
    required this.onStopCooking,
  });

  @override
  State<CookingTools> createState() => _CookingToolsState();
}

class _CookingToolsState extends State<CookingTools> {
  // 물 드래그 상태
  double _waterDragAngle = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFFEFEBE9),
      child: Column(
        children: [
          Row(
            children: [
              // 칼
              Expanded(child: _buildKnifeTool()),
              const SizedBox(width: 8),
              // 물
              Expanded(child: _buildWaterTool()),
              const SizedBox(width: 8),
              // 불
              Expanded(child: _buildFireTool()),
            ],
          ),
          if (widget.fireLevel > 0) ...[
            const SizedBox(height: 8),
            _buildCookingControl(),
          ],
        ],
      ),
    );
  }

  Widget _buildKnifeTool() {
    return Column(
      children: [
        const Text('🔪 칼', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        // 터치/클릭으로 칼질
        GestureDetector(
          onTap: widget.onChop,
          child: Container(
            width: 70,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFBDBDBD),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(blurRadius: 2, color: Colors.black26)],
            ),
            child: Center(
              child: Text(
                '${widget.knifeCount}회',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        const Text('터치해서 칼질', style: TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildWaterTool() {
    return Column(
      children: [
        const Text('💧 물', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        // 드래그해서 기울이기
        GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _waterDragAngle += details.delta.dy * -0.5;
              _waterDragAngle = _waterDragAngle.clamp(-50, 0);
              // 기울기에 따라 물 양 증가
              final pourRate = (_waterDragAngle.abs() / 50) * 2;
              widget.onWaterChange(widget.waterAmount + pourRate);
            });
          },
          onPanEnd: (_) => setState(() => _waterDragAngle = 0),
          child: Transform.rotate(
            angle: _waterDragAngle * 0.01,
            child: Container(
              width: 70,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blue.shade200,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(blurRadius: 2, color: Colors.black26)],
              ),
              child: Center(
                child: Text(
                  '${widget.waterAmount.round()}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        const Text('드래그해서 붓기', style: TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildFireTool() {
    return Column(
      children: [
        const Text('🔥 불', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final level = i + 1;
            final isActive = widget.fireLevel >= level;
            return GestureDetector(
              onTap: () => widget.onFireChange(
                widget.fireLevel == level ? level - 1 : level,
              ),
              child: Container(
                width: 22,
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? [Colors.orange, Colors.deepOrange, Colors.red][i]
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '$level',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : Colors.grey,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 2),
        Text(
          '단계 ${widget.fireLevel}',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCookingControl() {
    final state = context.read<GameState>();
    return Row(
      children: [
        Text(
          '🍳 조리 시간: ${widget.cookingTime.toStringAsFixed(1)}초',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (!widget.isCooking)
          ElevatedButton.icon(
            onPressed: () => widget.onStartCooking(state),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('가열 시작'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: widget.onStopCooking,
            icon: const Icon(Icons.stop, size: 18),
            label: const Text('가열 중지'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
      ],
    );
  }
}
