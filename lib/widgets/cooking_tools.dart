import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_state.dart';

/// 조리 도구 패널 — 칼, 물, 불 조작 + 조리하기 버튼
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
  final VoidCallback? onCook; // 조리하기 버튼

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
    this.onCook,
  });

  @override
  State<CookingTools> createState() => _CookingToolsState();
}

class _CookingToolsState extends State<CookingTools> {
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
          // 조리하기 버튼
          if (widget.onCook != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onCook,
                icon: const Icon(Icons.local_fire_department),
                label: const Text('조리하기', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
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
        // 슬라이더 + 버튼으로 물 조절
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => widget.onWaterChange((widget.waterAmount - 5).clamp(0, 100)),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(child: Text('-', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 36,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${widget.waterAmount.round()}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => widget.onWaterChange((widget.waterAmount + 5).clamp(0, 100)),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(child: Text('+', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              ),
            ),
          ],
        ),
        SizedBox(
          width: 90,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: Colors.blue.shade400,
              inactiveTrackColor: Colors.blue.shade100,
              thumbColor: Colors.blue.shade600,
            ),
            child: Slider(
              value: widget.waterAmount,
              min: 0,
              max: 100,
              onChanged: (v) => widget.onWaterChange(v),
            ),
          ),
        ),
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
